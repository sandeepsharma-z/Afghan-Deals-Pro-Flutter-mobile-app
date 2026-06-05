import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/auth/app_auth.dart';
import '../../data/models/profile_model.dart';

final profileProvider = FutureProvider<ProfileModel?>((ref) async {
  final userId = AppAuth.currentProfileLookupValue;
  if (userId == null) return null;
  final idColumn = AppAuth.profileLookupColumn;

  final response = await Supabase.instance.client
      .from('profiles')
      .select()
      .eq(idColumn, userId)
      .maybeSingle();

  if (response == null) return null;
  return ProfileModel.fromMap(response);
});

class ProfileNotifier extends StateNotifier<AsyncValue<void>> {
  ProfileNotifier() : super(const AsyncValue.data(null));

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final userId = AppAuth.currentProfileLookupValue;
    if (userId == null) return;
    final idColumn = AppAuth.profileLookupColumn;

    state = const AsyncValue.loading();
    try {
      await Supabase.instance.client
          .from('profiles')
          .update(data)
          .eq(idColumn, userId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateAvatar(String avatarUrl) async {
    await updateProfile({'avatar_url': avatarUrl});
  }
}

final profileNotifierProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<void>>(
  (_) => ProfileNotifier(),
);
