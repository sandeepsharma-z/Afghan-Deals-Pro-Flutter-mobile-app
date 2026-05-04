import 'package:equatable/equatable.dart';

class ProfileEntity extends Equatable {
  final String id;
  final String? name;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String country;
  final String? region;
  final String? city;
  final String? nationality;
  final String? gender;
  final String? dob;
  final bool isVerified;
  final DateTime? createdAt;

  const ProfileEntity({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.avatarUrl,
    required this.country,
    this.region,
    this.city,
    this.nationality,
    this.gender,
    this.dob,
    required this.isVerified,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        phone,
        name,
        country,
        region,
        city,
        nationality,
        gender,
        dob,
        isVerified,
      ];
}
