import 'package:isar_community/isar.dart';

part 'subscription_tier_cache.g.dart';

@collection
class SubscriptionTierCache {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String tier;

  late int wardrobeLimit;
  late int tryonLimit;
  late int videoLimit;
  late int chatLimit;
}
