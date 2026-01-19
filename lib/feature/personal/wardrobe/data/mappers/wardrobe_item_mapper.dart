import '../collections/wardrobe_item_collection.dart';
import '../models/wardrobe_item_model.dart';
import 'category_mapper.dart';

extension WardrobeItemModelMapper on WardrobeItemModel {
  WardrobeItemCollection toCollection() {
    return WardrobeItemCollection()
      ..itemId = id ?? ''
      ..imagePath = imagePath
      ..category = CategoryMapper.toApiString(category)
      ..tags = tags
      ..createdAt = createdAt
      ..updatedAt = updatedAt;
  }
}

extension WardrobeItemCollectionMapper on WardrobeItemCollection {
  WardrobeItemModel toModel() {
    return WardrobeItemModel(
      id: itemId,
      imagePath: imagePath,
      category: CategoryMapper.fromApiString(category),
      tags: tags ?? [],
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
