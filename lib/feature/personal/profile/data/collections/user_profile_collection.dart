import 'package:isar_community/isar.dart';
import 'package:tryzeon/core/data/collections/body_measurements_collection.dart';

part 'user_profile_collection.g.dart';

@collection
class UserProfileCollection {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String userId;

  String? name;
  String? avatarPath;

  BodyMeasurementsCollection? measurements;

  @Index()
  DateTime? createdAt;

  DateTime? updatedAt;
}
