import 'package:isar_community/isar.dart';
import 'package:tryzeon/feature/common/body_measurements/data/collections/body_measurements_embedded.dart';

part 'user_profile_cache.g.dart';

@collection
class UserProfileCache {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String userId;

  late String name;
  late DateTime createdAt;
  late DateTime updatedAt;
  String? email;
  String? avatarPath;

  BodyMeasurementsEmbedded? measurements;

  String? gender;
  String? ageRange;
  List<String>? stylePreferences;
  late bool isOnboarded;
}
