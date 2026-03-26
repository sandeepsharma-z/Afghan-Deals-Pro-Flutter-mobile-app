import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/profile_model.dart';

final profileProvider = FutureProvider<ProfileModel?>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;

  final response = await Supabase.instance.client
      .from('profiles')
      .select()
      .eq('id', user.id)
      .maybeSingle();

  if (response == null) return null;
  return ProfileModel.fromMap(response);
});

class ProfileNotifier extends StateNotifier<AsyncValue<void>> {
  ProfileNotifier() : super(const AsyncValue.data(null));

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    state = const AsyncValue.loading();
    try {
      await Supabase.instance.client
          .from('profiles')
          .update(data)
          .eq('id', user.id);
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
