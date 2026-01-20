import 'package:equatable/equatable.dart';

class StoreProfile extends Equatable {
  const StoreProfile({
    required this.id,
    required this.ownerId,
    required this.name,
    this.address,
    this.logoPath,
    this.logoUrl,
  });

  final String id;
  final String ownerId;
  final String name;
  final String? address;
  final String? logoPath;
  final String? logoUrl;

  @override
  List<Object?> get props => [id, ownerId, name, address, logoPath, logoUrl];

  StoreProfile copyWith({
    final String? id,
    final String? ownerId,
    final String? name,
    final String? address,
    final String? logoPath,
    final String? logoUrl,
  }) {
    return StoreProfile(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      address: address ?? this.address,
      logoPath: logoPath ?? this.logoPath,
      logoUrl: logoUrl ?? this.logoUrl,
    );
  }
}
