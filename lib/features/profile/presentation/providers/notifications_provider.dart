import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/notification_model.dart';

final notificationsProvider =
    FutureProvider<List<NotificationModel>>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return const [];

  final response = await Supabase.instance.client
      .from('notifications')
      .select()
      .eq('user_id', userId)
      .order('created_at', ascending: false);

  if (response.isEmpty) return const [];

  final notifications = <NotificationModel>[];
  for (final row in response) {
    try {
      notifications.add(NotificationModel.fromMap(row));
    } catch (e) {
      debugPrint('Error mapping notification: $e');
    }
  }
  return notifications;
});

class NotificationsActions {
  Future<void> markAsRead(String notificationId) async {
    await Supabase.instance.client
        .from('notifications')
        .update({'is_read': true}).eq('id', notificationId);
  }

  Future<void> markAllAsRead(String userId) async {
    await Supabase.instance.client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId);
  }

  Future<void> deleteNotification(String notificationId) async {
    await Supabase.instance.client
        .from('notifications')
        .delete()
        .eq('id', notificationId);
  }
}

final notificationsActionsProvider =
    Provider<NotificationsActions>((ref) => NotificationsActions());
