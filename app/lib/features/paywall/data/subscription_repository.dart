import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/analytics.dart';

/// Repository for managing subscription entitlements and sync with Supabase
class SubscriptionRepository {
  static final SubscriptionRepository _instance = SubscriptionRepository._internal();
  static SubscriptionRepository get instance => _instance;
  SubscriptionRepository._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Stream controller for entitlement updates
  final StreamController<bool> _entitlementController = StreamController<bool>.broadcast();
  Stream<bool> get entitlementStream => _entitlementController.stream;
  
  bool _hasActiveSubscription = false;
  bool get hasActiveSubscription => _hasActiveSubscription;
  
  DateTime? _subscriptionExpiresAt;
  DateTime? get subscriptionExpiresAt => _subscriptionExpiresAt;
  
  String? _currentPlan;
  String? get currentPlan => _currentPlan;
  
  Timer? _refreshTimer;
  
  /// Initialize the repository and start background refresh
  Future<void> initialize() async {
    try {
      // Load initial entitlement state
      await refreshEntitlement();
      
      // Set up periodic refresh (every 5 minutes)
      _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
        refreshEntitlement();
      });
      
      debugPrint('Subscription repository initialized');
    } catch (e) {
      debugPrint('Failed to initialize subscription repository: $e');
      AnalyticsService.capture('subscription_init_failure', {
        'error': e.toString(),
      });
    }
  }
  
  /// Refresh entitlement status from Supabase
  Future<void> refreshEntitlement() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        _updateEntitlement(false, null, null);
        return;
      }
      
      // Query active subscription from Supabase
      final response = await _supabase
          .from('subscriptions')
          .select('*')
          .eq('user_id', user.id)
          .eq('status', 'active')
          .maybeSingle();
      
      if (response == null) {
        _updateEntitlement(false, null, null);
        AnalyticsService.capture('entitlement_sync', {
          'has_subscription': false,
        });
        return;
      }
      
      final subscription = response as Map<String, dynamic>;
      final expiresAt = DateTime.parse(subscription['expires_at']);
      final plan = subscription['plan_type'] as String?;
      
      // Check if subscription is still valid
      final isActive = expiresAt.isAfter(DateTime.now());
      
      _updateEntitlement(isActive, expiresAt, plan);
      
      AnalyticsService.capture('entitlement_sync', {
        'has_subscription': isActive,
        'plan_type': plan,
        'expires_at': expiresAt.toIso8601String(),
      });
      
    } catch (e) {
      debugPrint('Error refreshing entitlement: $e');
      AnalyticsService.capture('entitlement_sync_error', {
        'error': e.toString(),
      });
    }
  }
  
  /// Update entitlement state and notify listeners
  void _updateEntitlement(bool hasSubscription, DateTime? expiresAt, String? plan) {
    final bool changed = _hasActiveSubscription != hasSubscription;
    
    _hasActiveSubscription = hasSubscription;
    _subscriptionExpiresAt = expiresAt;
    _currentPlan = plan;
    
    if (changed) {
      _entitlementController.add(hasSubscription);
      debugPrint('Entitlement updated: hasSubscription=$hasSubscription, plan=$plan');
    }
  }
  
  /// Validate and sync purchase receipt/token with server
  Future<bool> syncPurchaseWithServer({
    required String productId,
    required String purchaseToken,
    String? transactionId,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('No authenticated user for purchase sync');
        return false;
      }
      
      // Call the entitlement-sync Edge Function
      final response = await _supabase.functions.invoke(
        'entitlement-sync',
        body: {
          'product_id': productId,
          'purchase_token': purchaseToken,
          'transaction_id': transactionId,
          'platform': defaultTargetPlatform.name,
        },
      );
      
      if (response.status == 200) {
        final data = response.data as Map<String, dynamic>;
        final success = data['success'] as bool? ?? false;
        
        if (success) {
          // Refresh entitlement after successful sync
          await refreshEntitlement();
          
          AnalyticsService.capture('purchase_sync_success', {
            'product_id': productId,
          });
          
          return true;
        } else {
          final error = data['error'] as String? ?? 'Unknown error';
          debugPrint('Purchase sync failed: $error');
          
          AnalyticsService.capture('purchase_sync_failure', {
            'product_id': productId,
            'error': error,
          });
          
          return false;
        }
      } else {
        debugPrint('Purchase sync HTTP error: ${response.status}');
        
        AnalyticsService.capture('purchase_sync_failure', {
          'product_id': productId,
          'error': 'http_${response.status}',
        });
        
        return false;
      }
    } catch (e) {
      debugPrint('Exception during purchase sync: $e');
      
      AnalyticsService.capture('purchase_sync_exception', {
        'product_id': productId,
        'error': e.toString(),
      });
      
      return false;
    }
  }
  
  /// Check if user has access to premium features
  bool hasPremiumAccess() {
    return _hasActiveSubscription;
  }
  
  /// Get subscription status for display
  String getSubscriptionStatus() {
    if (!_hasActiveSubscription) {
      return 'No active subscription';
    }
    
    if (_subscriptionExpiresAt == null) {
      return 'Active subscription';
    }
    
    final daysUntilExpiry = _subscriptionExpiresAt!.difference(DateTime.now()).inDays;
    
    if (daysUntilExpiry <= 0) {
      return 'Subscription expired';
    } else if (daysUntilExpiry <= 7) {
      return 'Expires in $daysUntilExpiry days';
    } else {
      return 'Active until ${_formatDate(_subscriptionExpiresAt!)}';
    }
  }
  
  /// Format date for display
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  /// Get current plan display name
  String getPlanDisplayName() {
    switch (_currentPlan) {
      case 'monthly':
        return 'Monthly Plan';
      case 'annual':
        return 'Annual Plan';
      default:
        return 'Unknown Plan';
    }
  }
  
  /// Dispose of resources
  void dispose() {
    _refreshTimer?.cancel();
    _entitlementController.close();
  }
}
