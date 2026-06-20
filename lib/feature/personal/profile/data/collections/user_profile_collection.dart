import 'package:isar_community/isar.dart';
import 'package:tryzeon/feature/common/measurements/collections/measurements_collection.dart';

part 'user_profile_collection.g.dart';

@collection
class UserProfileCollection {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String userId;

  late String name;
  late DateTime createdAt;
  late DateTime updatedAt;
  String? email;
  String? avatarPath;

  MeasurementsCollection? measurements;

  String? gender;
  String? ageRange;
  List<String>? stylePreferences;
  late bool isOnboarded;
}
