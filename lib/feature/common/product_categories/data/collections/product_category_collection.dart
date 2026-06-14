import 'package:isar_community/isar.dart';

part 'product_category_collection.g.dart';

@collection
class ProductCategoryCollection {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String categoryId;

  late String name;

  String? gender;

  String? wardrobeCategory;

  String? imageMale;

  String? imageFemale;

  String? imageMaleUrl;

  String? imageFemaleUrl;
}
