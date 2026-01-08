class StoreProfile {
  StoreProfile({
    required this.id,
    required this.ownerId,
    required this.name,
    this.address,
    this.logoPath,
  });

  final String id;
  final String ownerId;
  final String name;
  final String? address;
  final String? logoPath;

  StoreProfile copyWith({
    final String? id,
    final String? ownerId,
    final String? name,
    final String? address,
    final String? logoPath,
  }) {
    return StoreProfile(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      address: address ?? this.address,
      logoPath: logoPath ?? this.logoPath,
    );
  }

  Map<String, dynamic> getDirtyFields(final StoreProfile target) {
    final updates = <String, dynamic>{};

    if (name != target.name) {
      updates['name'] = target.name;
    }

    if (address != target.address) {
      updates['address'] = target.address;
    }

    if (logoPath != target.logoPath) {
      updates['logo_path'] = target.logoPath;
    }

    return updates;
  }
}
