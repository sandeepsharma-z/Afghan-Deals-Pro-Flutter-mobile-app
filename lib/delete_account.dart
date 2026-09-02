import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/auth/app_auth.dart';

/// Removes the signed-in user and everything belonging to them.
///
/// The app's data lives in Supabase, so deletion runs through the
/// `delete_my_account` RPCs. Phone users are authenticated by Firebase and
/// additionally need their Firebase user removed.
class DeleteAccountService {
  static SupabaseClient get _client => Supabase.instance.client;

  static Future<void> deleteUserAccount() async {
    if (AppAuth.isFirebaseAuthenticated) {
      final firebaseUser = fb.FirebaseAuth.instance.currentUser;
      // Best-effort: drop the Supabase profile linked to this phone user.
      try {
        await _client.rpc('delete_my_account_firebase',
            params: {'p_firebase_uid': firebaseUser?.uid});
      } catch (_) {}
      try {
        await firebaseUser?.delete();
      } on fb.FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          throw Exception(
              'For security, please log in again and then retry deleting your account.');
        }
        rethrow;
      }
    } else {
      await _client.rpc('delete_my_account');
    }
    await AppAuth.signOutAll();
  }
}
