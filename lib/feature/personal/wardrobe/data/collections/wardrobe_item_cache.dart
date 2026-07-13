import 'package:isar_community/isar.dart';

part 'wardrobe_item_cache.g.dart';

@collection
class WardrobeItemCache {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String itemId;

  late String imagePath;

  late String category;

  List<String>? tags;

  @Index()
  late DateTime createdAt;

  late DateTime updatedAt;
}
