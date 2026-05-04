class NotificationSettingsModel {
  final String userId;
  final bool pushEnabled;
  final bool newMessages;
  final bool newOffers;
  final bool priceDrops;
  final bool savedAds;
  final bool accountAlerts;
  final bool promotions;
  final bool weeklyDigest;
  final DateTime updatedAt;

  NotificationSettingsModel({
    required this.userId,
    required this.pushEnabled,
    required this.newMessages,
    required this.newOffers,
    required this.priceDrops,
    required this.savedAds,
    required this.accountAlerts,
    required this.promotions,
    required this.weeklyDigest,
    required this.updatedAt,
  });

  factory NotificationSettingsModel.fromMap(Map<String, dynamic> map) {
    return NotificationSettingsModel(
      userId: map['user_id'] as String,
      pushEnabled: (map['push_enabled'] as bool?) ?? true,
      newMessages: (map['new_messages'] as bool?) ?? true,
      newOffers: (map['new_offers'] as bool?) ?? true,
      priceDrops: (map['price_drops'] as bool?) ?? true,
      savedAds: (map['saved_ads'] as bool?) ?? false,
      accountAlerts: (map['account_alerts'] as bool?) ?? true,
      promotions: (map['promotions'] as bool?) ?? false,
      weeklyDigest: (map['weekly_digest'] as bool?) ?? false,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }

  factory NotificationSettingsModel.defaults(String userId) {
    return NotificationSettingsModel(
      userId: userId,
      pushEnabled: true,
      newMessages: true,
      newOffers: true,
      priceDrops: true,
      savedAds: false,
      accountAlerts: true,
      promotions: false,
      weeklyDigest: false,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'push_enabled': pushEnabled,
      'new_messages': newMessages,
      'new_offers': newOffers,
      'price_drops': priceDrops,
      'saved_ads': savedAds,
      'account_alerts': accountAlerts,
      'promotions': promotions,
      'weekly_digest': weeklyDigest,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
