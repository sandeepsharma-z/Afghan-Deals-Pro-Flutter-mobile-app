import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    super.email,
    super.phone,
    super.name,
    super.avatarUrl,
    super.isVerified,
    super.createdAt,
  });

  static String? _firstNonEmpty(Iterable<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }

  static String? _metadataText(Map<String, dynamic> metadata, List<String> keys) {
    return _firstNonEmpty(keys.map((key) => metadata[key]?.toString()));
  }

  static String? _identityText(User user, List<String> keys) {
    for (final identity in user.identities ?? const <UserIdentity>[]) {
      final data = identity.identityData;
      if (data == null) continue;
      final value = _metadataText(data, keys);
      if (value != null) return value;
    }
    return null;
  }

  factory UserModel.fromSupabaseUser(User user) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};

    return UserModel(
      id: user.id,
      email: user.email,
      phone: user.phone,
      name: _firstNonEmpty([
        _metadataText(
          metadata,
          const ['name', 'full_name', 'display_name', 'preferred_username'],
        ),
        _identityText(
          user,
          const ['name', 'full_name', 'display_name', 'preferred_username'],
        ),
      ]),
      avatarUrl: _firstNonEmpty([
        _metadataText(
          metadata,
          const ['avatar_url', 'picture', 'photo_url', 'image'],
        ),
        _identityText(
          user,
          const ['avatar_url', 'picture', 'photo_url', 'image', 'avatar'],
        ),
      ]),
      isVerified:
          user.emailConfirmedAt != null || user.phoneConfirmedAt != null,
      createdAt: DateTime.parse(user.createdAt),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'name': name,
      'avatar_url': avatarUrl,
      'is_verified': isVerified,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
