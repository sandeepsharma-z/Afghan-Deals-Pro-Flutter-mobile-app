import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/auth/app_auth.dart';

/// Thrown when Firebase wants a fresh sign-in before it will delete the user.
/// The caller has already been signed out, so logging back in and retrying is
/// all that is left to do.
class ReauthRequiredException implements Exception {
  final String message;
  const ReauthRequiredException(this.message);

  @override
  String toString() => message;
}

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
      final uid = firebaseUser?.uid;

      // Delete the Firebase user first. It is the only step that can be
      // refused, and doing it last would wipe the user's listings and profile
      // while leaving them with an account and an error message.
      try {
        await firebaseUser?.delete();
      } on fb.FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          // Sign out so "log in again" is actually possible - nothing has been
          // deleted at this point.
          await AppAuth.signOutAll();
          throw const ReauthRequiredException(
              'For security, Apple requires a fresh sign-in before deleting an '
              'account. You have been signed out - please log in again and tap '
              'Delete Account.');
        }
        rethrow;
      }

      // Firebase user is gone; now drop the Supabase profile linked to it.
      await _client.rpc('delete_my_account_firebase',
          params: {'p_firebase_uid': uid});
    } else {
      await _client.rpc('delete_my_account');
    }
    await AppAuth.signOutAll();
  }
}
