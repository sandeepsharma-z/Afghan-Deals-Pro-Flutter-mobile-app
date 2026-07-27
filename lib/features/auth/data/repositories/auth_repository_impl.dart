import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/auth/app_auth.dart';

class AuthRepositoryImpl implements AuthRepository {
  static const _googleServerClientId =
      '856987295621-qe6pgebeugaerk2s4qdqckcr24qfjeel.apps.googleusercontent.com';
  final fb.FirebaseAuth _firebaseAuth = fb.FirebaseAuth.instance;
  String? _phoneVerificationId;

  AuthRepositoryImpl(SupabaseClient _);

  SupabaseClient get _client => Supabase.instance.client;

  String? _firstNonEmpty(Iterable<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }

  String? _metadataText(Map<String, dynamic> metadata, List<String> keys) {
    return _firstNonEmpty(
      keys.map((key) => metadata[key]?.toString()),
    );
  }

  String? _identityText(User user, List<String> keys) {
    for (final identity in user.identities ?? const <UserIdentity>[]) {
      final data = identity.identityData;
      if (data == null) continue;
      final value = _metadataText(data, keys);
      if (value != null) return value;
    }
    return null;
  }

  String? _resolvedAvatar(User user) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    return _firstNonEmpty([
      _metadataText(metadata, const ['avatar_url', 'picture', 'photo_url', 'image']),
      _identityText(user, const ['avatar_url', 'picture', 'photo_url', 'image']),
      _identityText(user, const ['avatar']),
    ]);
  }

  String _resolvedDisplayName(User user) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    return _firstNonEmpty([
          _metadataText(
            metadata,
            const ['name', 'full_name', 'display_name', 'preferred_username'],
          ),
          _identityText(
            user,
            const ['name', 'full_name', 'display_name', 'preferred_username'],
          ),
          user.email?.split('@').first,
          user.phone,
          'User',
        ]) ??
        'User';
  }

  @override
  UserEntity? get currentUser {
    return AppAuth.currentUserEntity;
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return AppAuth.authStateChanges();
  }

  Future<void> _ensureProfile(User user) async {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final displayName = _resolvedDisplayName(user);
    final oauthAvatarUrl = _resolvedAvatar(user);

    Map<String, dynamic>? existingProfile;
    try {
      existingProfile = await _client
          .from('profiles')
          .select('avatar_url')
          .eq('id', user.id)
          .maybeSingle();
    } catch (_) {
      existingProfile = null;
    }

    final existingAvatarUrl =
        existingProfile?['avatar_url']?.toString().trim();
    final avatarUrl = _firstNonEmpty([existingAvatarUrl, oauthAvatarUrl]);

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

  bool _isInvalidRefreshToken(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('invalid refresh token') ||
        message.contains('refresh token not found');
  }

  @override
  Future<void> sendPhoneOtp(String phone) async {
    try {
      final completer = Completer<void>();
      bool codeSent = false;

      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 120),
        verificationCompleted: (credential) async {
          // Auto-retrieve (Android only) - complete and sign in
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        verificationFailed: (error) {
          if (!completer.isCompleted) {
            completer.completeError(
              AppAuthException(
                error.message ?? 'Phone verification failed. Please try again.',
              ),
            );
          }
        },
        codeSent: (verificationId, resendToken) {
          _phoneVerificationId = verificationId;
          codeSent = true;
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _phoneVerificationId = verificationId;
          if (!codeSent && !completer.isCompleted) {
            completer.complete();
          }
        },
      );

      // Wait for OTP to be sent (max 120 seconds)
      await completer.future.timeout(const Duration(seconds: 120));

      if (_phoneVerificationId == null || _phoneVerificationId!.isEmpty) {
        throw const AppAuthException('Failed to send OTP. Please check the phone number and try again.');
      }
    } catch (e) {
      if (e is AppAuthException) rethrow;
      if (e is TimeoutException) {
        throw const AppAuthException('Request timed out. Please try again.');
      }
      throw AppAuthException('Failed to send OTP: ${e.toString()}');
    }
  }

  @override
  Future<UserEntity> verifyPhoneOtp({
    required String phone,
    required String otp,
  }) async {
    try {
      final verificationId = _phoneVerificationId;
      if (verificationId == null || verificationId.isEmpty) {
        throw const AppAuthException('Phone verification session expired. Please request a new OTP.');
      }

      if (otp.isEmpty || otp.length != 6) {
        throw const AppAuthException('Please enter a valid 6-digit code.');
      }

      final credential = fb.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp.trim(),
      );

      final result = await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = result.user;
      if (firebaseUser == null) {
        throw const AppAuthException('Verification failed. Please try again.');
      }

      // Switch to Firebase+Supabase mode
      await AppAuth.ensureFirebaseSupabaseMode();

      final displayName = firebaseUser.displayName?.trim().isNotEmpty == true
          ? firebaseUser.displayName!.trim()
          : (firebaseUser.phoneNumber ?? 'User');

      // Create/update profile in Supabase
      try {
        await AppAuth.ensureFirebaseProfileId(
          displayName: displayName,
          email: firebaseUser.email,
          phone: firebaseUser.phoneNumber ?? phone,
        );
      } catch (e) {
        // Profile update failed, but user is still authenticated in Firebase
        // Log but don't fail the auth
      }

      return UserEntity(
        id: firebaseUser.uid,
        email: firebaseUser.email,
        phone: firebaseUser.phoneNumber ?? phone,
        name: displayName,
        isVerified: true,
        createdAt: firebaseUser.metadata.creationTime,
      );
    } on fb.FirebaseAuthException catch (e) {
      final errorMsg = _parseFirebaseError(e);
      throw AppAuthException(errorMsg);
    } catch (e) {
      if (e is AppAuthException) rethrow;
      throw AppAuthException('Verification failed: ${e.toString()}');
    }
  }

  String _parseFirebaseError(fb.FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-verification-code':
        return 'Invalid code. Please try again.';
      case 'session-expired':
        return 'Verification session expired. Please request a new OTP.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return error.message ?? 'OTP verification failed. Please try again.';
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
    // iOS has no native Google OAuth client configured; use Supabase's
    // hosted OAuth flow (opens ASWebAuthenticationSession, returns via the
    // io.supabase.flutter:// deep link). Android keeps the native flow.
    if (Platform.isIOS) {
      return _signInWithGoogleWeb();
    }
    try {
      try {
        await _client.auth.signOut();
      } catch (e) {
        if (!_isInvalidRefreshToken(e)) rethrow;
      }

      final googleSignIn = GoogleSignIn(
        scopes: const ['email', 'profile'],
        serverClientId: _googleServerClientId,
      );

      await googleSignIn.signOut();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw const AppAuthException('Google sign-in was cancelled.');
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AppAuthException(
          'Google sign-in did not return an ID token. Please try again.',
        );
      }

      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );

      final user = response.user;
      if (user == null) {
        throw const AppAuthException(
            'Google sign-in did not complete. Please try again.');
      }
      await _ensureProfile(user);
      return UserModel.fromSupabaseUser(user);
    } on AuthException catch (e) {
      if (_isInvalidRefreshToken(e)) {
        final user = AppAuth.currentUserEntity;
        if (user != null) {
          return user;
        }
      }
      throw AppAuthException(e.message, code: e.statusCode);
    } on TimeoutException {
      throw const AppAuthException(
        'Google sign-in timed out. Please complete Google login and try again.',
      );
    } on PlatformException catch (e) {
      throw AppAuthException(
        'Google sign-in config error (${e.code}): ${e.message ?? e.details ?? 'Unknown platform error'}',
      );
    } catch (e) {
      if (e is AppAuthException) rethrow;
      throw AppAuthException('Google sign-in failed: $e');
    }
  }

  Future<UserEntity> _signInWithGoogleWeb() async {
    try {
      try {
        await _client.auth.signOut();
      } catch (e) {
        if (!_isInvalidRefreshToken(e)) rethrow;
      }

      final completer = Completer<User>();
      late final StreamSubscription<AuthState> sub;
      sub = _client.auth.onAuthStateChange.listen((data) {
        final user = data.session?.user;
        if (user != null && !completer.isCompleted) {
          completer.complete(user);
        }
      });

      try {
        await _client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'io.supabase.flutter://login-callback/',
          authScreenLaunchMode: LaunchMode.externalApplication,
        );
        final user = await completer.future.timeout(const Duration(minutes: 3));
        await _ensureProfile(user);
        return UserModel.fromSupabaseUser(user);
      } finally {
        await sub.cancel();
      }
    } on AuthException catch (e) {
      throw AppAuthException(e.message, code: e.statusCode);
    } on TimeoutException {
      throw const AppAuthException('Google sign-in timed out. Please try again.');
    } catch (e) {
      if (e is AppAuthException) rethrow;
      throw const AppAuthException('Google sign-in failed. Please try again.');
    }
  }

  @override
  Future<UserEntity> signInWithApple() async {
    try {
      final rawNonce = _client.auth.generateRawNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw const AppAuthException(
            'Apple sign-in did not return a token. Please try again.');
      }

      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      final user = response.user;
      if (user == null) throw const AppAuthException('Apple sign-in failed.');

      // Apple returns the name only on the very first sign-in — save it now.
      final fullName = _firstNonEmpty([
        [credential.givenName, credential.familyName]
            .whereType<String>()
            .join(' '),
      ]);
      final existingName =
          _metadataText(user.userMetadata ?? const {}, ['full_name', 'name']);
      if (fullName != null && (existingName == null || existingName.isEmpty)) {
        try {
          await _client.auth
              .updateUser(UserAttributes(data: {'full_name': fullName}));
        } catch (_) {}
      }

      return UserModel.fromSupabaseUser(_client.auth.currentUser ?? user);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const AppAuthException('Apple sign-in was cancelled.');
      }
      throw AppAuthException('Apple sign-in failed: ${e.message}');
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
      final userId = AppAuth.currentUserId;
      final lookupValue = AppAuth.currentProfileLookupValue;
      if (userId != null) {
        try {
          await _client
              .from('profiles')
              .update({'fcm_token': null})
              .eq(AppAuth.profileLookupColumn, lookupValue ?? userId);
        } catch (_) {}
      }
      await AppAuth.signOutAll();
    } on AuthException catch (e) {
      throw AppAuthException(e.message, code: e.statusCode);
    } catch (_) {
      throw const AppAuthException('Sign out failed. Please try again.');
    }
  }
}
