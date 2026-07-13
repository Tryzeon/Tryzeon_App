import 'package:isar_community/isar.dart';

part 'subscription_plan_cache.g.dart';

@collection
class SubscriptionPlanCache {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String planId;

  late String name;
  late int wardrobeLimit;
  late int tryonLimit;
  late int videoLimit;
  late int chatLimit;
  late int sortOrder;
  late bool isActive;
}
