import '../../domain/entities/profile_entity.dart';

class ProfileModel extends ProfileEntity {
  const ProfileModel({
    required super.id,
    super.name,
    super.email,
    super.phone,
    super.avatarUrl,
    required super.country,
    super.region,
    super.city,
    required super.isVerified,
    super.createdAt,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id'] as String,
      name: map['name'] as String?,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      country: map['country'] as String? ?? 'Afghanistan',
      region: map['region'] as String?,
      city: map['city'] as String?,
      isVerified: map['is_verified'] as bool? ?? false,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'avatar_url': avatarUrl,
      'country': country,
      'region': region,
      'city': city,
      'is_verified': isVerified,
    };
  }

  ProfileModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? country,
    String? region,
    String? city,
    bool? isVerified,
  }) {
    return ProfileModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      country: country ?? this.country,
      region: region ?? this.region,
      city: city ?? this.city,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt,
    );
  }
}
