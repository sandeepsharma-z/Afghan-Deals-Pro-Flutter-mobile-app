import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/auth/app_auth.dart';
import '../../../../core/localization/app_language_provider.dart';

// ── Supabase client provider ──────────────────────────────────────────────────
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// ── Repository provider ───────────────────────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.read(supabaseClientProvider));
});

// ── Auth state stream (current user) ─────────────────────────────────────────
final authStateProvider = StreamProvider<UserEntity?>((ref) async* {
  yield AppAuth.currentUserEntity;
  yield* ref.read(authRepositoryProvider).authStateChanges;
});

// ── Auth actions notifier ─────────────────────────────────────────────────────

sealed class AuthActionState {
  const AuthActionState();
}

class AuthActionIdle extends AuthActionState {
  const AuthActionIdle();
}

class AuthActionLoading extends AuthActionState {
  const AuthActionLoading();
}

class AuthActionSuccess extends AuthActionState {
  final String? message;
  const AuthActionSuccess({this.message});
}

class AuthActionError extends AuthActionState {
  final String message;
  const AuthActionError(this.message);
}

class AuthNotifier extends StateNotifier<AuthActionState> {
  final AuthRepository _repository;
  final Ref _ref;

  AuthNotifier(this._repository, this._ref) : super(const AuthActionIdle());

  // ── Phone OTP ───────────────────────────────────────────────────────────────
  Future<bool> sendPhoneOtp(String phone) async {
    state = const AuthActionLoading();
    try {
      await _repository.sendPhoneOtp(phone);
      state = const AuthActionSuccess(message: 'OTP sent successfully');
      return true;
    } on AppAuthException catch (e) {
      state = AuthActionError(e.message);
      return false;
    } catch (_) {
      state = const AuthActionError('Something went wrong. Please try again.');
      return false;
    }
  }

  Future<bool> verifyPhoneOtp({
    required String phone,
    required String otp,
  }) async {
    state = const AuthActionLoading();
    try {
      await _repository.verifyPhoneOtp(phone: phone, otp: otp);
      _ref.invalidate(authStateProvider);
      state = const AuthActionSuccess();
      return true;
    } on AppAuthException catch (e) {
      state = AuthActionError(e.message);
      return false;
    } catch (_) {
      state = const AuthActionError('OTP verification failed. Please try again.');
      return false;
    }
  }

  // ── Email + Password ────────────────────────────────────────────────────────
  Future<bool> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? gender,
    String? nationality,
    String? dob,
  }) async {
    state = const AuthActionLoading();
    try {
      await _repository.signUpWithEmail(
        name: name, email: email, password: password,
        phone: phone, gender: gender, nationality: nationality, dob: dob,
      );
      _ref.invalidate(authStateProvider);
      state = const AuthActionSuccess();
      return true;
    } on AppAuthException catch (e) {
      state = AuthActionError(e.message);
      return false;
    } catch (_) {
      state = const AuthActionError('Sign up failed. Please try again.');
      return false;
    }
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AuthActionLoading();
    try {
      await _repository.signInWithEmail(email: email, password: password);
      _ref.invalidate(authStateProvider);
      state = const AuthActionSuccess();
      return true;
    } on AppAuthException catch (e) {
      state = AuthActionError(e.message);
      return false;
    } catch (_) {
      state = const AuthActionError('Sign in failed. Please try again.');
      return false;
    }
  }

  // ── Email OTP ───────────────────────────────────────────────────────────────
  Future<bool> sendEmailOtp(String email) async {
    state = const AuthActionLoading();
    try {
      await _repository.sendEmailOtp(email);
      state = const AuthActionSuccess(message: 'Check your email for the login link');
      return true;
    } on AppAuthException catch (e) {
      state = AuthActionError(e.message);
      return false;
    } catch (_) {
      state = const AuthActionError('Something went wrong. Please try again.');
      return false;
    }
  }

  Future<bool> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    state = const AuthActionLoading();
    try {
      await _repository.verifyEmailOtp(email: email, otp: otp);
      _ref.invalidate(authStateProvider);
      state = const AuthActionSuccess();
      return true;
    } on AppAuthException catch (e) {
      state = AuthActionError(e.message);
      return false;
    } catch (_) {
      state = const AuthActionError('OTP verification failed. Please try again.');
      return false;
    }
  }

  // ── Google ──────────────────────────────────────────────────────────────────
  Future<bool> signInWithGoogle() async {
    state = const AuthActionLoading();
    try {
      await _repository.signInWithGoogle();
      _ref.invalidate(authStateProvider);
      state = const AuthActionSuccess();
      return true;
    } on AppAuthException catch (e) {
      state = AuthActionError(e.message);
      return false;
    } catch (_) {
      state = const AuthActionError('Google sign-in failed. Please try again.');
      return false;
    }
  }

  // ── Apple ───────────────────────────────────────────────────────────────────
  Future<bool> signInWithApple() async {
    state = const AuthActionLoading();
    try {
      await _repository.signInWithApple();
      _ref.invalidate(authStateProvider);
      state = const AuthActionSuccess();
      return true;
    } on AppAuthException catch (e) {
      state = AuthActionError(e.message);
      return false;
    } catch (_) {
      state = const AuthActionError('Apple sign-in failed. Please try again.');
      return false;
    }
  }

  // ── Sign out ────────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    state = const AuthActionLoading();
    try {
      // Clear Supabase metadata language BEFORE logout (while still authenticated)
      try {
        await AppAuth.updateSupabaseUserMetadata({'language': null});
      } catch (_) {
        // Ignore if update fails
      }

      await _repository.signOut();

      // Reset language to English on logout
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language_code', 'en');

      // Reset language provider state to English
      await _ref.read(appLanguageProvider.notifier).setLocale(const Locale('en'));

      _ref.invalidate(authStateProvider);
      state = const AuthActionSuccess();
      // Clear auth state after successful signout
      // The authStateProvider will update via the stream automatically
    } on AppAuthException catch (e) {
      state = AuthActionError(e.message);
    } catch (_) {
      state = const AuthActionError('Sign out failed. Please try again.');
    }
  }

  void reset() => state = const AuthActionIdle();
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthActionState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider), ref);
});
