import 'package:tryzeon/feature/common/product_categories/domain/entities/product_category.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/outfit_slot.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/resolved_outfit_slot.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_filter.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';

typedef CategoriesByNameCallback = Future<Map<String, ProductCategory>> Function();
typedef GetWardrobeItemsCallback = Future<List<WardrobeItem>> Function();
typedef GetShopProductsCallback = Future<List<ShopProduct>> Function(ShopFilter filter);

class ResolveOutfitSlot {
  ResolveOutfitSlot({
    required final CategoriesByNameCallback getCategoriesByName,
    required final GetWardrobeItemsCallback getWardrobeItems,
    required final GetShopProductsCallback getShopProducts,
  }) : _getCategoriesByName = getCategoriesByName,
       _getWardrobeItems = getWardrobeItems,
       _getShopProducts = getShopProducts;

  static const int _maxPerSlot = 5;

  final CategoriesByNameCallback _getCategoriesByName;
  final GetWardrobeItemsCallback _getWardrobeItems;
  final GetShopProductsCallback _getShopProducts;

  Future<ResolvedOutfitSlot> call(final OutfitSlot slot) async {
    final categories = await _getCategoriesByName();
    final cat = categories[slot.categoryName];
    if (cat == null) {
      return ResolvedOutfitSlot.empty(slotLabel: slot.slotLabel, reason: slot.reason);
    }

    final wardrobeCategory = cat.wardrobeCategory;
    if (wardrobeCategory != null) {
      final items = await _getWardrobeItems();
      // Wardrobe match: same wardrobeCategory AND every slot tag present on
      // the item. Empty slot.tags → every() is vacuously true → category-only.
      final matches =
          items
              .where((final i) => i.category == wardrobeCategory)
              .where((final i) => slot.tags.every(i.tags.contains))
              .toList()
            ..sort((final a, final b) => b.createdAt.compareTo(a.createdAt));

      if (matches.isNotEmpty) {
        return ResolvedOutfitSlot.wardrobe(
          slotLabel: slot.slotLabel,
          reason: slot.reason,
          items: matches.take(_maxPerSlot).toList(),
        );
      }
    }

    final products = await _getShopProducts(
      ShopFilter(
        categories: {cat.id},
        searchQuery: slot.tags.isEmpty ? null : slot.tags.join(' '),
      ),
    );

    if (products.isNotEmpty) {
      return ResolvedOutfitSlot.shop(
        slotLabel: slot.slotLabel,
        reason: slot.reason,
        products: products.take(_maxPerSlot).toList(),
      );
    }

    return ResolvedOutfitSlot.empty(slotLabel: slot.slotLabel, reason: slot.reason);
  }
}
