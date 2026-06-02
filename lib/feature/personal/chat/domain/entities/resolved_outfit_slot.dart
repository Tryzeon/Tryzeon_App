import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';

part 'resolved_outfit_slot.freezed.dart';

@freezed
sealed class ResolvedOutfitSlot with _$ResolvedOutfitSlot {
  const factory ResolvedOutfitSlot.wardrobe({
    required final String slotLabel,
    required final String reason,
    required final List<WardrobeItem> items,
  }) = ResolvedOutfitSlotWardrobe;

  const factory ResolvedOutfitSlot.shop({
    required final String slotLabel,
    required final String reason,
    required final List<ShopProduct> products,
  }) = ResolvedOutfitSlotShop;

  const factory ResolvedOutfitSlot.empty({
    required final String slotLabel,
    required final String reason,
  }) = ResolvedOutfitSlotEmpty;
}
