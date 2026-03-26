import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String? email;
  final String? phone;
  final String? name;
  final String? avatarUrl;
  final bool isVerified;
  final DateTime? createdAt;

  const UserEntity({
    required this.id,
    this.email,
    this.phone,
    this.name,
    this.avatarUrl,
    this.isVerified = false,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id, email, phone, name, avatarUrl, isVerified];
}
