import 'package:tryzeon/feature/personal/data/mappers/personal_mappr.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/models/wardrobe_item_model.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';

const _mappr = PersonalMappr();

/// Decodes a raw `wardrobe_items` row straight to the domain entity.
///
/// This is the wardrobe feature's public row contract (exported via
/// `wardrobe.dart`) so other features can consume wardrobe rows without
/// touching `wardrobe/data/**`.
WardrobeItem decodeWardrobeItemRow(final Map<String, dynamic> row) =>
    _mappr.convert<WardrobeItemModel, WardrobeItem>(WardrobeItemModel.fromJson(row));
