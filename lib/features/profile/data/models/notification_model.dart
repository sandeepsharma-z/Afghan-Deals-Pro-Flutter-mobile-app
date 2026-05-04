class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String subtitle;
  final String iconType;
  final bool isRead;
  final DateTime createdAt;
  final String? actionUrl;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.iconType,
    required this.isRead,
    required this.createdAt,
    this.actionUrl,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      type: map['type'] as String,
      title: map['title'] as String,
      subtitle: map['subtitle'] as String,
      iconType: map['icon_type'] as String,
      isRead: (map['is_read'] as bool?) ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      actionUrl: map['action_url'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'title': title,
      'subtitle': subtitle,
      'icon_type': iconType,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'action_url': actionUrl,
    };
  }
}
