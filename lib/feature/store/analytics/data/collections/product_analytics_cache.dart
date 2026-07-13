import 'package:isar_community/isar.dart';

part 'product_analytics_cache.g.dart';

@collection
class ProductAnalyticsCache {
  Id id = Isar.autoIncrement;

  @Index(composite: [CompositeIndex('year'), CompositeIndex('month')])
  late String storeId;
  @Index()
  late String productId;
  late int year;
  late int month;
  late int viewCount;
  late int tryonCount;
  late int purchaseClickCount;
}
