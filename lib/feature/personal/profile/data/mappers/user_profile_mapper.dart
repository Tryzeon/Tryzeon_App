import 'package:tryzeon/core/data/mappers/body_measurements_mapper.dart';
import 'package:tryzeon/core/domain/entities/body_measurements.dart';

import '../collections/user_profile_collection.dart';
import '../models/user_profile_model.dart';

extension UserProfileModelMapper on UserProfileModel {
  UserProfileCollection toCollection() {
    return UserProfileCollection()
      ..userId = userId
      ..name = name
      ..avatarPath = avatarPath
      ..measurements = measurements.toCollection()
      ..createdAt = createdAt
      ..updatedAt = updatedAt;
  }
}

extension UserProfileCollectionMapper on UserProfileCollection {
  UserProfileModel toModel() {
    return UserProfileModel(
      userId: userId,
      name: name ?? '',
      measurements: measurements?.toModel() ?? const BodyMeasurements(),
      avatarPath: avatarPath,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
