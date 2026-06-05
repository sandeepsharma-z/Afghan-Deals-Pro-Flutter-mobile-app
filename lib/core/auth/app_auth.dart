import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/data/models/user_model.dart';

const _supabaseUrl = 'https://cmebycscxjeudegsqzmx.supabase.co';
const _supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNtZWJ5Y3NjeGpldWRlZ3Nxem14Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgxMzEzNDIsImV4cCI6MjA5MzcwNzM0Mn0.K0dMmJ7Oi2RV-YfTNaHGhsUFySD_PatUBo2k0iYRJuQ';

class AppAuth {
  static final fb.FirebaseAuth firebase = fb.FirebaseAuth.instance;

  static bool _firebaseMode = false;
  static String? _firebaseProfileId;
  static StreamSubscription<AuthState>? _supabaseAuthSubscription;

  static SupabaseClient get client => Supabase.instance.client;

  static bool get isFirebaseAuthenticated => firebase.currentUser != null;

  static bool get isAuthenticated =>
      firebase.currentUser != null ||
      (!_firebaseMode && Supabase.instance.client.auth.currentUser != null);

  static String? get currentAuthUid =>
      firebase.currentUser?.uid ??
      (_firebaseMode ? null : Supabase.instance.client.auth.currentUser?.id);

  static String? get currentUserId =>
      _firebaseMode
          ? _firebaseProfileId
          : Supabase.instance.client.auth.currentUser?.id;

  static String? get currentUserEmail =>
      firebase.currentUser?.email ??
      (_firebaseMode ? null : Supabase.instance.client.auth.currentUser?.email);

  static String? get currentUserPhone =>
      firebase.currentUser?.phoneNumber ??
      (_firebaseMode ? null : Supabase.instance.client.auth.currentUser?.phone);

  static String get profileIdColumn =>
      _firebaseProfileId != null ? 'id' : (isFirebaseAuthenticated ? 'firebase_uid' : 'id');
  static String get profileLookupColumn =>
      _firebaseProfileId != null ? 'id' : (isFirebaseAuthenticated ? 'firebase_uid' : 'id');
  static String? get currentProfileLookupValue => _firebaseProfileId ??
      (isFirebaseAuthenticated ? firebase.currentUser?.uid : currentUserId);

  static Map<String, dynamic> get currentUserMetadata =>
      _firebaseMode
          ? const <String, dynamic>{}
          : (Supabase.instance.client.auth.currentUser?.userMetadata ??
              const <String, dynamic>{});

  static UserEntity? get currentUserEntity {
    final firebaseUser = firebase.currentUser;
    if (firebaseUser != null) {
      return UserEntity(
        id: _firebaseProfileId ?? firebaseUser.uid,
        email: firebaseUser.email,
        phone: firebaseUser.phoneNumber,
        name: firebaseUser.displayName ?? firebaseUser.phoneNumber ?? 'User',
        avatarUrl: firebaseUser.photoURL,
        isVerified: firebaseUser.phoneNumber != null || firebaseUser.emailVerified,
        createdAt: firebaseUser.metadata.creationTime,
      );
    }

    if (_firebaseMode) return null;

    final supabaseUser = Supabase.instance.client.auth.currentUser;
    if (supabaseUser != null) {
      return UserModel.fromSupabaseUser(supabaseUser);
    }
    return null;
  }

  static String _digitsOnly(String? value) {
    return (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
  }

  static Stream<UserEntity?> authStateChanges() {
    final controller = StreamController<UserEntity?>.broadcast();

    void emitCurrent() {
      if (!controller.isClosed) {
        controller.add(currentUserEntity);
      }
    }

    controller.onListen = emitCurrent;

    final firebaseSub = firebase.authStateChanges().listen((_) async {
      try {
        if (firebase.currentUser != null) {
          await ensureFirebaseSupabaseMode();
          await ensureFirebaseProfileId();
        } else if (_firebaseMode) {
          await ensureSupabaseMode();
        }
      } catch (_) {
        // Do not let profile/bootstrap failures block the app shell.
      }
      emitCurrent();
    });

    _supabaseAuthSubscription?.cancel();
    _supabaseAuthSubscription = null;
    if (!_firebaseMode) {
      _supabaseAuthSubscription =
          Supabase.instance.client.auth.onAuthStateChange.listen((_) {
        if (!_firebaseMode) {
          emitCurrent();
        }
      });
    }

    controller.onCancel = () async {
      await firebaseSub.cancel();
      await _supabaseAuthSubscription?.cancel();
      _supabaseAuthSubscription = null;
    };

    return controller.stream;
  }

  static Future<void> initializeSupabaseForCurrentAuth() async {
    if (firebase.currentUser != null) {
      await ensureFirebaseSupabaseMode();
    } else {
      await ensureSupabaseMode();
    }
  }

  static Future<void> ensureFirebaseSupabaseMode() async {
    if (_firebaseMode) return;
    await _supabaseAuthSubscription?.cancel();
    _supabaseAuthSubscription = null;
    await Supabase.instance.dispose();
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
      accessToken: () async => await firebase.currentUser?.getIdToken(),
    );
    _firebaseMode = true;
  }

  static Future<String?> ensureFirebaseProfileId({
    String? displayName,
    String? email,
    String? phone,
  }) async {
    final firebaseUser = firebase.currentUser;
    if (firebaseUser == null) return null;
    if (!_firebaseMode) {
      await ensureFirebaseSupabaseMode();
    }
    if (_firebaseProfileId != null && _firebaseProfileId!.isNotEmpty) {
      return _firebaseProfileId;
    }

    final resolvedEmail = email ?? firebaseUser.email;
    final resolvedPhone = phone ?? firebaseUser.phoneNumber;
    final payload = <String, dynamic>{
      'firebase_uid': firebaseUser.uid,
      'name': displayName?.trim().isNotEmpty == true
          ? displayName!.trim()
          : (firebaseUser.displayName?.trim().isNotEmpty == true
              ? firebaseUser.displayName!.trim()
              : (resolvedPhone ?? 'User')),
      'email': resolvedEmail,
      'phone': resolvedPhone,
      'is_verified': true,
      'country': 'Afghanistan',
    };

    try {
      final client = Supabase.instance.client;

      Map<String, dynamic>? existing = await client
          .from('profiles')
          .select('id')
          .eq('firebase_uid', firebaseUser.uid)
          .maybeSingle();

      if (existing == null &&
          resolvedPhone != null &&
          resolvedPhone.trim().isNotEmpty) {
        final phoneDigits = _digitsOnly(resolvedPhone);
        final phoneCandidates = <String>{
          resolvedPhone.trim(),
          phoneDigits,
          if (phoneDigits.isNotEmpty) '+$phoneDigits',
        }.where((e) => e.isNotEmpty).toList();

        for (final candidate in phoneCandidates) {
          final match = await client
              .from('profiles')
              .select('id, phone')
              .eq('phone', candidate)
              .limit(5);
          for (final row in match as List<dynamic>) {
            final map = Map<String, dynamic>.from(row as Map);
            if (_digitsOnly(map['phone']?.toString()) == phoneDigits) {
              existing = map;
              break;
            }
          }
          if (existing != null) break;
        }
      }

      if (existing == null &&
          resolvedEmail != null &&
          resolvedEmail.trim().isNotEmpty) {
        existing = await client
            .from('profiles')
            .select('id')
            .ilike('email', resolvedEmail.trim())
            .maybeSingle();
      }

      Map<String, dynamic> row;
      if (existing != null) {
        _firebaseProfileId = existing['id']?.toString();
        try {
          row = await client
              .from('profiles')
              .update(payload)
              .eq('id', existing['id'])
              .select('id')
              .single();
          _firebaseProfileId = row['id']?.toString() ?? _firebaseProfileId;
        } catch (_) {
          return _firebaseProfileId;
        }
      } else {
        row = await client
            .from('profiles')
            .upsert(payload, onConflict: 'firebase_uid')
            .select('id')
            .single();
        _firebaseProfileId = row['id']?.toString();
      }
    } catch (_) {
      return _firebaseProfileId;
    }
    return _firebaseProfileId;
  }

  static Future<void> ensureSupabaseMode() async {
    if (!_firebaseMode && Supabase.instance.isInitialized) return;
    await _supabaseAuthSubscription?.cancel();
    _supabaseAuthSubscription = null;
    if (Supabase.instance.isInitialized) {
      await Supabase.instance.dispose();
    }
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    _firebaseMode = false;
    _firebaseProfileId = null;
  }

  static Future<void> signOutAll() async {
    final supabaseClient = Supabase.instance.client;
    final firebaseUser = firebase.currentUser;

    final lookupValue = currentProfileLookupValue;
    if (lookupValue != null) {
      try {
        await supabaseClient
            .from('profiles')
            .update({'fcm_token': null}).eq(profileLookupColumn, lookupValue);
      } catch (_) {}
    }

    if (firebaseUser != null) {
      await firebase.signOut();
      await ensureSupabaseMode();
      return;
    }

    await supabaseClient.auth.signOut();
  }

  static Future<void> updateSupabaseUserMetadata(Map<String, dynamic> metadata) async {
    if (isFirebaseAuthenticated || metadata.isEmpty) {
      return;
    }
    await Supabase.instance.client.auth.updateUser(
      UserAttributes(data: metadata),
    );
  }
}
