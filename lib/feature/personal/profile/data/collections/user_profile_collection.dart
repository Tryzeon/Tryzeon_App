import 'package:isar/isar.dart';

part 'user_profile_collection.g.dart';

@collection
class UserProfileCollection {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String userId;

  String? name;
  String? avatarPath;

  BodyMeasurementsCollection? measurements;
}

@embedded
class BodyMeasurementsCollection {
  double? height;
  double? weight;

  double? shoulderWidth;
  double? chest;
  double? waist;
  double? hips;
  double? sleeveLength;
}
