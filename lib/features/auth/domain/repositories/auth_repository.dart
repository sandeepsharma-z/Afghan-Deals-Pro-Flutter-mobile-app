import '../entities/user_entity.dart';

abstract interface class AuthRepository {
  /// Returns current logged-in user, or null
  UserEntity? get currentUser;

  /// Stream of auth state changes
  Stream<UserEntity?> get authStateChanges;

  /// Send OTP to phone number
  Future<void> sendPhoneOtp(String phone);

  /// Verify phone OTP — returns user on success
  Future<UserEntity> verifyPhoneOtp({
    required String phone,
    required String otp,
  });

  /// Sign up with email + password
  Future<UserEntity> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? gender,
    String? nationality,
    String? dob,
  });

  /// Sign in with email + password
  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  });

  /// Sign in / sign up with email (magic link / OTP)
  Future<void> sendEmailOtp(String email);

  /// Verify email OTP
  Future<UserEntity> verifyEmailOtp({
    required String email,
    required String otp,
  });

  /// Sign in with Google
  Future<UserEntity> signInWithGoogle();

  /// Sign in with Apple
  Future<UserEntity> signInWithApple();

  /// Sign out
  Future<void> signOut();
}
