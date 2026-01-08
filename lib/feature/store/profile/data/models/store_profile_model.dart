import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/feature/store/profile/domain/entities/store_profile.dart';

class StoreProfileModel extends StoreProfile {
  StoreProfileModel({
    required super.id,
    required super.ownerId,
    required super.name,
    super.address,
    super.logoPath,
    super.logoUrl,
  });

  factory StoreProfileModel.fromJson(final Map<String, dynamic> json) {
    final logoPath = json['logo_path'] as String?;
    return StoreProfileModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      logoPath: logoPath,
      logoUrl: logoPath != null
          ? Supabase.instance.client.storage.from('store').getPublicUrl(logoPath)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'address': address,
      'logo_path': logoPath,
    };
  }
}
