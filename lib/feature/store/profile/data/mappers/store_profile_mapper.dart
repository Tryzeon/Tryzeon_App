import '../collections/store_profile_collection.dart';
import '../models/store_profile_model.dart';

extension StoreProfileModelMapper on StoreProfileModel {
  StoreProfileCollection toCollection() {
    return StoreProfileCollection()
      ..storeId = id
      ..ownerId = ownerId
      ..name = name
      ..address = address
      ..logoPath = logoPath
      ..logoUrl = logoUrl
      ..createdAt = createdAt
      ..updatedAt = updatedAt;
  }
}

extension StoreProfileCollectionMapper on StoreProfileCollection {
  StoreProfileModel toModel() {
    return StoreProfileModel(
      id: storeId,
      ownerId: ownerId,
      name: name,
      address: address,
      logoPath: logoPath,
      logoUrl: logoUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
