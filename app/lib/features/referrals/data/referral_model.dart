class Referral {
  const Referral({
    required this.id,
    required this.userId,
    required this.code,
    required this.successfulReferrals,
    required this.earnedReward,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String code;
  final int successfulReferrals;
  final double earnedReward;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory Referral.fromJson(Map<String, dynamic> json) {
    return Referral(
      id: json['id'] as String,
      userId: json['userId'] as String,
      code: json['code'] as String,
      successfulReferrals: _toInt(json['successfulReferrals']),
      earnedReward: _toDouble(json['earnedReward']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'code': code,
        'successfulReferrals': successfulReferrals,
        'earnedReward': earnedReward,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  Referral copyWith({
    String? id,
    String? userId,
    String? code,
    int? successfulReferrals,
    double? earnedReward,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Referral(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      code: code ?? this.code,
      successfulReferrals: successfulReferrals ?? this.successfulReferrals,
      earnedReward: earnedReward ?? this.earnedReward,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ReferralConversion {
  const ReferralConversion({
    required this.id,
    required this.referralCode,
    required this.referrerId,
    required this.referredUserId,
    required this.rewardAmount,
    required this.createdAt,
    required this.rewardRedeemed,
  });

  final String id;
  final String referralCode;
  final String referrerId;
  final String referredUserId;
  final double rewardAmount;
  final DateTime createdAt;
  final bool rewardRedeemed;

  factory ReferralConversion.fromJson(Map<String, dynamic> json) {
    return ReferralConversion(
      id: json['id'] as String,
      referralCode: json['referralCode'] as String,
      referrerId: json['referrerId'] as String,
      referredUserId: json['referredUserId'] as String,
      rewardAmount: Referral._toDouble(json['rewardAmount']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      rewardRedeemed: json['rewardRedeemed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'referralCode': referralCode,
        'referrerId': referrerId,
        'referredUserId': referredUserId,
        'rewardAmount': rewardAmount,
        'createdAt': createdAt.toIso8601String(),
        'rewardRedeemed': rewardRedeemed,
      };

  ReferralConversion copyWith({
    String? id,
    String? referralCode,
    String? referrerId,
    String? referredUserId,
    double? rewardAmount,
    DateTime? createdAt,
    bool? rewardRedeemed,
  }) {
    return ReferralConversion(
      id: id ?? this.id,
      referralCode: referralCode ?? this.referralCode,
      referrerId: referrerId ?? this.referrerId,
      referredUserId: referredUserId ?? this.referredUserId,
      rewardAmount: rewardAmount ?? this.rewardAmount,
      createdAt: createdAt ?? this.createdAt,
      rewardRedeemed: rewardRedeemed ?? this.rewardRedeemed,
    );
  }
}
