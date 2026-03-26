import 'package:google_sign_in/google_sign_in.dart';
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
    return _client.auth.onAuthStateChange.map((event) {
      final user = event.session?.user;
      if (user == null) return null;
      return UserModel.fromSupabaseUser(user);
    });
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
      return UserModel.fromSupabaseUser(response.user!);
    } on AuthException catch (e) {
      throw AppAuthException(e.message, code: e.statusCode);
    } catch (e) {
      if (e is AppAuthException) rethrow;
      throw const AppAuthException('OTP verification failed. Please try again.');
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
      throw const AppAuthException('Failed to send email link. Please try again.');
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
      return UserModel.fromSupabaseUser(response.user!);
    } on AuthException catch (e) {
      throw AppAuthException(e.message, code: e.statusCode);
    } catch (e) {
      if (e is AppAuthException) rethrow;
      throw const AppAuthException('Email verification failed. Please try again.');
    }
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn(
        serverClientId: const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID'),
      ).signIn();
      if (googleUser == null) throw const AppAuthException('Google sign-in cancelled.');

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) throw const AppAuthException('Google sign-in failed: no token.');

      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      if (response.user == null) throw const AppAuthException('Google sign-in failed.');
      return UserModel.fromSupabaseUser(response.user!);
    } on AuthException catch (e) {
      throw AppAuthException(e.message, code: e.statusCode);
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
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw AppAuthException(e.message, code: e.statusCode);
    } catch (_) {
      throw const AppAuthException('Sign out failed. Please try again.');
    }
  }
}
