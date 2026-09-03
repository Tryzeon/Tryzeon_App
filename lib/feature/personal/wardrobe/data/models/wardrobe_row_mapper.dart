import 'package:tryzeon/feature/personal/data/mappers/personal_mappr.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/models/wardrobe_item_model.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';

const _mappr = PersonalMappr();

WardrobeItem decodeWardrobeItemRow(final Map<String, dynamic> row) =>
    _mappr.convert<WardrobeItemModel, WardrobeItem>(WardrobeItemModel.fromJson(row));
