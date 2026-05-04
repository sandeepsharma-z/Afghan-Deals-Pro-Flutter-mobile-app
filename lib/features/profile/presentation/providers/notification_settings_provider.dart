import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/notification_settings_model.dart';

final notificationSettingsProvider =
    FutureProvider<NotificationSettingsModel>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) throw Exception('User not authenticated');

  try {
    final response = await Supabase.instance.client
        .from('notification_settings')
        .select()
        .eq('user_id', userId)
        .single();

    return NotificationSettingsModel.fromMap(response);
  } catch (e) {
    debugPrint('Error fetching notification settings: $e');
    return NotificationSettingsModel.defaults(userId);
  }
});

class NotificationSettingsActions {
  Future<void> updateSetting(String userId, String field, bool value) async {
    await Supabase.instance.client
        .from('notification_settings')
        .upsert({
          'user_id': userId,
          field: value,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('user_id', userId);
  }

  Future<void> updateAllSettings(
      String userId, NotificationSettingsModel settings) async {
    await Supabase.instance.client
        .from('notification_settings')
        .upsert(settings.toMap()).eq('user_id', userId);
  }
}

final notificationSettingsActionsProvider =
    Provider<NotificationSettingsActions>(
        (ref) => NotificationSettingsActions());
