import 'package:isar_community/isar.dart';

part 'wardrobe_item_collection.g.dart';

@collection
class WardrobeItemCollection {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String itemId;

  late String imagePath;
  late String category;
  List<String>? tags;

  @Index()
  DateTime? createdAt;

  DateTime? updatedAt;
}
