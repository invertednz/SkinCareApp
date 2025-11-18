import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/analytics.dart';
import 'referral_model.dart';

class ReferralService extends ChangeNotifier {
  static final ReferralService instance = ReferralService._();
  ReferralService._();

  // Reward configuration
  static const double rewardPerReferral = 10.0; // $10 off next year per successful referral
  static const double maxRewardCap = 57.0; // Can earn up to full Pay It Forward price
  static const int maxReferrals = 5; // Max 5 referrals to prevent abuse

  Referral? _currentUserReferral;
  List<ReferralConversion> _conversions = [];
  bool _isLoading = false;

  Referral? get currentUserReferral => _currentUserReferral;
  List<ReferralConversion> get conversions => _conversions;
  bool get isLoading => _isLoading;

  double get earnedReward => _currentUserReferral?.earnedReward ?? 0.0;
  int get successfulReferrals => _currentUserReferral?.successfulReferrals ?? 0;
  String get referralCode => _currentUserReferral?.code ?? '';
  
  bool get hasReachedCap => earnedReward >= maxRewardCap;
  int get remainingReferrals => max(0, maxReferrals - successfulReferrals);
  double get potentialEarnings => min(remainingReferrals * rewardPerReferral, maxRewardCap - earnedReward);

  /// Generate unique 8-character alphanumeric code (avoiding confusing characters)
  String _generateReferralCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // No O/0, I/1
    final random = Random.secure();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// Initialize or fetch user's referral data
  Future<void> initializeReferral(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final supabase = Supabase.instance.client;

      // Try to fetch existing referral
      final response = await supabase
          .from('referrals')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        _currentUserReferral = Referral.fromJson({
          'id': response['id'],
          'userId': response['user_id'],
          'code': response['code'],
          'successfulReferrals': response['successful_referrals'] ?? 0,
          'earnedReward': (response['earned_reward'] ?? 0.0).toDouble(),
          'createdAt': DateTime.parse(response['created_at']),
          'updatedAt': response['updated_at'] != null 
              ? DateTime.parse(response['updated_at']) 
              : null,
        });
      } else {
        // Create new referral entry
        final code = _generateReferralCode();
        final newResponse = await supabase.from('referrals').insert({
          'user_id': userId,
          'code': code,
          'successful_referrals': 0,
          'earned_reward': 0.0,
        }).select().single();

        _currentUserReferral = Referral.fromJson({
          'id': newResponse['id'],
          'userId': newResponse['user_id'],
          'code': newResponse['code'],
          'successfulReferrals': 0,
          'earnedReward': 0.0,
          'createdAt': DateTime.parse(newResponse['created_at']),
        });

        AnalyticsService.capture('referral_code_generated', {
          'code': code,
        });
      }

      await _fetchConversions(userId);
    } catch (e) {
      debugPrint('Error initializing referral: $e');
      AnalyticsService.capture('referral_init_error', {'error': e.toString()});
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch all conversions for this user
  Future<void> _fetchConversions(String userId) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('referral_conversions')
          .select()
          .eq('referrer_id', userId)
          .order('created_at', ascending: false);

      _conversions = (response as List)
          .map((json) => ReferralConversion.fromJson({
                'id': json['id'],
                'referralCode': json['referral_code'],
                'referrerId': json['referrer_id'],
                'referredUserId': json['referred_user_id'],
                'rewardAmount': (json['reward_amount'] ?? 0.0).toDouble(),
                'createdAt': DateTime.parse(json['created_at']),
                'rewardRedeemed': json['reward_redeemed'] ?? false,
              }))
          .toList();
    } catch (e) {
      debugPrint('Error fetching conversions: $e');
    }
  }

  /// Apply referral code when new user signs up
  Future<bool> applyReferralCode(String code, String newUserId) async {
    try {
      final supabase = Supabase.instance.client;

      // Find referral by code
      final referralResponse = await supabase
          .from('referrals')
          .select()
          .eq('code', code.toUpperCase())
          .maybeSingle();

      if (referralResponse == null) {
        AnalyticsService.capture('referral_code_invalid', {'code': code});
        return false;
      }

      final referrerId = referralResponse['user_id'];
      final currentReferrals = referralResponse['successful_referrals'] ?? 0;
      final currentReward = (referralResponse['earned_reward'] ?? 0.0).toDouble();

      // Check if cap reached
      if (currentReferrals >= maxReferrals || currentReward >= maxRewardCap) {
        AnalyticsService.capture('referral_cap_reached', {
          'code': code,
          'referrer_id': referrerId,
        });
        return false;
      }

      // Calculate new reward
      final newReward = min<double>(currentReward + rewardPerReferral, maxRewardCap);

      // Create conversion record
      await supabase.from('referral_conversions').insert({
        'referral_code': code.toUpperCase(),
        'referrer_id': referrerId,
        'referred_user_id': newUserId,
        'reward_amount': rewardPerReferral,
        'reward_redeemed': false,
      });

      // Update referral stats
      await supabase.from('referrals').update({
        'successful_referrals': currentReferrals + 1,
        'earned_reward': newReward,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', referrerId);

      AnalyticsService.capture('referral_conversion_success', {
        'code': code,
        'referrer_id': referrerId,
        'referred_user_id': newUserId,
        'reward_earned': rewardPerReferral,
        'total_reward': newReward,
      });

      return true;
    } catch (e) {
      debugPrint('Error applying referral code: $e');
      AnalyticsService.capture('referral_apply_error', {
        'code': code,
        'error': e.toString(),
      });
      return false;
    }
  }

  /// Redeem earned rewards (apply discount to next payment)
  Future<bool> redeemRewards(String userId) async {
    if (earnedReward <= 0) return false;

    try {
      final supabase = Supabase.instance.client;

      // Mark conversions as redeemed
      await supabase
          .from('referral_conversions')
          .update({'reward_redeemed': true})
          .eq('referrer_id', userId)
          .eq('reward_redeemed', false);

      AnalyticsService.capture('referral_reward_redeemed', {
        'user_id': userId,
        'reward_amount': earnedReward,
      });

      return true;
    } catch (e) {
      debugPrint('Error redeeming rewards: $e');
      return false;
    }
  }

  /// Get shareable message with referral code
  String getShareMessage({String? userName}) {
    final name = userName ?? 'A community member';
    return '''
🎁 $name just helped me get premium skincare support for \$27/year!

Through the Pay It Forward program, they donated \$15, the app matched it, and now I'm saving \$30 on my membership. This app has transformed my skincare routine - personalized AI insights, photo tracking, and 24/7 support!

Your skin deserves this too. Use my code: $referralCode to join the movement and I'll earn \$${rewardPerReferral.toInt()} off my next year! 

#SkinCareJourney #PayItForward #HealthySkin
''';
  }
}
