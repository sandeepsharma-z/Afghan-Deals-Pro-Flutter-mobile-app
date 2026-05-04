import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';
import '../../../../core/error/app_exception.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _client;

  AuthRepositoryImpl(this._client);

  @override
  UserEntity? get currentUser {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return UserModel.fromSupabaseUser(user);
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return _client.auth.onAuthStateChange.asyncMap((event) async {
      final user = event.session?.user;
      if (user == null) return null;
      if (event.event == AuthChangeEvent.signedIn ||
          event.event == AuthChangeEvent.userUpdated ||
          event.event == AuthChangeEvent.tokenRefreshed ||
          event.event == AuthChangeEvent.initialSession) {
        await _ensureProfile(user);
      }
      return UserModel.fromSupabaseUser(user);
    });
  }

  Future<void> _ensureProfile(User user) async {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    String? firstText(List<String> keys) {
      for (final key in keys) {
        final value = metadata[key]?.toString().trim();
        if (value != null && value.isNotEmpty) return value;
      }
      return null;
    }

    final displayName = firstText(
          const ['name', 'full_name', 'display_name', 'preferred_username'],
        ) ??
        user.email?.split('@').first ??
        user.phone ??
        'User';
    final avatarUrl =
        firstText(const ['avatar_url', 'picture', 'photo_url', 'image']);

    final payload = <String, dynamic>{
      'id': user.id,
      'name': displayName,
      'email': user.email,
      'phone': user.phone,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'country': metadata['country']?.toString().trim().isNotEmpty == true
          ? metadata['country'].toString().trim()
          : 'Afghanistan',
      if (metadata['nationality']?.toString().trim().isNotEmpty == true)
        'nationality': metadata['nationality'].toString().trim(),
      if (metadata['gender']?.toString().trim().isNotEmpty == true)
        'gender': metadata['gender'].toString().trim(),
      if (metadata['dob']?.toString().trim().isNotEmpty == true)
        'dob': metadata['dob'].toString().trim(),
      'is_verified':
          user.emailConfirmedAt != null || user.phoneConfirmedAt != null,
    };

    try {
      await _client.from('profiles').upsert(payload, onConflict: 'id');
    } catch (_) {
      // Auth should not fail only because the profile mirror could not update.
    }
  }

  @override
  Future<void> sendPhoneOtp(String phone) async {
    try {
      await _client.auth.signInWithOtp(phone: phone);
    } on AuthException catch (e) {
      throw AppAuthException(e.message, code: e.statusCode);
    } catch (_) {
      throw const AppAuthException('Failed to send OTP. Please try again.');
    }
  }

  @override
  Future<UserEntity> verifyPhoneOtp({
    required String phone,
    required String otp,
  }) async {
    try {
      final response = await _client.auth.verifyOTP(
        phone: phone,
        token: otp,
        type: OtpType.sms,
      );
      if (response.user == null) {
        throw const AppAuthException('Verification failed. Please try again.');
      }
      await _ensureProfile(response.user!);
      return UserModel.fromSupabaseUser(response.user!);
    } on AuthException catch (e) {
      throw AppAuthException(e.message, code: e.statusCode);
    } catch (e) {
      if (e is AppAuthException) rethrow;
      throw const AppAuthException(
          'OTP verification failed. Please try again.');
    }
  }

  @override
  Future<UserEntity> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? gender,
    String? nationality,
    String? dob,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'email': email,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          if (gender != null) 'gender': gender,
          if (nationality != null) 'nationality': nationality,
          if (dob != null) 'dob': dob,
        },
      );
      if (response.user == null) {
        throw const AppAuthException('Sign up failed. Please try again.');
      }
      await _ensureProfile(response.user!);
      return UserModel.fromSupabaseUser(response.user!);
    } on AuthException catch (e) {
      throw AppAuthException(e.message, code: e.statusCode);
    } catch (e) {
      if (e is AppAuthException) rethrow;
      throw const AppAuthException('Sign up failed. Please try again.');
    }
  }

  @override
  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) {
        throw const AppAuthException('Sign in failed. Please try again.');
      }
      await _ensureProfile(response.user!);
      return UserModel.fromSupabaseUser(response.user!);
    } on AuthException catch (e) {
      throw AppAuthException(e.message, code: e.statusCode);
    } catch (e) {
      if (e is AppAuthException) rethrow;
      throw const AppAuthException('Sign in failed. Please try again.');
    }
  }

  @override
  Future<void> sendEmailOtp(String email) async {
    try {
      await _client.auth.signInWithOtp(email: email);
    } on AuthException catch (e) {
      throw AppAuthException(e.message, code: e.statusCode);
    } catch (_) {
      throw const AppAuthException(
          'Failed to send email link. Please try again.');
    }
  }

  @override
  Future<UserEntity> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _client.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.email,
      );
      if (response.user == null) {
        throw const AppAuthException('Verification failed. Please try again.');
      }
      await _ensureProfile(response.user!);
      return UserModel.fromSupabaseUser(response.user!);
    } on AuthException catch (e) {
      throw AppAuthException(e.message, code: e.statusCode);
    } catch (e) {
      if (e is AppAuthException) rethrow;
      throw const AppAuthException(
          'Email verification failed. Please try again.');
    }
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    try {
      final launched = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutter://login-callback/',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw const AppAuthException('Google sign-in was cancelled.');
      }

      final immediateUser = _client.auth.currentUser;
      if (immediateUser != null) {
        await _ensureProfile(immediateUser);
        return UserModel.fromSupabaseUser(immediateUser);
      }

      final authEvent = await _client.auth.onAuthStateChange
          .where((event) =>
              event.session?.user != null &&
              event.event != AuthChangeEvent.signedOut)
          .first
          .timeout(const Duration(minutes: 2));

      final user = authEvent.session?.user;
      if (user == null) {
        throw const AppAuthException(
            'Google sign-in did not complete. Please try again.');
      }
      await _ensureProfile(user);
      return UserModel.fromSupabaseUser(user);
    } on AuthException catch (e) {
      throw AppAuthException(e.message, code: e.statusCode);
    } on TimeoutException {
      throw const AppAuthException(
        'Google sign-in timed out. Please complete Google login and try again.',
      );
    } catch (e) {
      if (e is AppAuthException) rethrow;
      throw const AppAuthException('Google sign-in failed. Please try again.');
    }
  }

  @override
  Future<UserEntity> signInWithApple() async {
    try {
      await _client.auth.signInWithOAuth(OAuthProvider.apple);
      final user = _client.auth.currentUser;
      if (user == null) throw const AppAuthException('Apple sign-in failed.');
      return UserModel.fromSupabaseUser(user);
    } on AuthException catch (e) {
      throw AppAuthException(e.message, code: e.statusCode);
    } catch (e) {
      if (e is AppAuthException) rethrow;
      throw const AppAuthException('Apple sign-in failed. Please try again.');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId != null) {
        try {
          await _client
              .from('profiles')
              .update({'fcm_token': null}).eq('id', userId);
        } catch (_) {}
      }
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw AppAuthException(e.message, code: e.statusCode);
    } catch (_) {
      throw const AppAuthException('Sign out failed. Please try again.');
    }
  }
}
