import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/clothing_style/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/product_attributes/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_filter.dart';

void main() {
  test('new advanced-filter fields default to null', () {
    const filter = ShopFilter();
    expect(filter.materials, isNull);
    expect(filter.elasticities, isNull);
    expect(filter.fits, isNull);
    expect(filter.thicknesses, isNull);
    expect(filter.styles, isNull);
    expect(filter.seasons, isNull);
    expect(filter.channels, isNull);
  });

  test('filters differing only by elasticities are not equal (cache-key safe)', () {
    const a = ShopFilter(elasticities: {ProductElasticity.high});
    const b = ShopFilter(elasticities: {ProductElasticity.low});
    expect(a == b, isFalse);
  });

  test('copyWith preserves and overrides advanced filters', () {
    const base = ShopFilter(materials: {'棉'});
    final next = base.copyWith(styles: {ClothingStyle.casual});
    expect(next.materials, {'棉'});
    expect(next.styles, {ClothingStyle.casual});
  });

  test('activeFilterCount is 0 for an empty filter', () {
    expect(const ShopFilter().activeFilterCount, 0);
  });

  test('activeFilterCount counts each active sheet-managed group once', () {
    const filter = ShopFilter(
      channels: {StoreChannel.online},
      minPrice: 100,
      materials: {'棉'},
      elasticities: {ProductElasticity.high},
      fits: {'oversize'},
      thicknesses: {ProductThickness.low},
      styles: {ClothingStyle.casual},
      seasons: {ProductSeason.summer},
    );
    expect(filter.activeFilterCount, 8);
  });

  test('activeFilterCount treats price min OR max as one group', () {
    expect(const ShopFilter(maxPrice: 900).activeFilterCount, 1);
    expect(const ShopFilter(minPrice: 10, maxPrice: 900).activeFilterCount, 1);
  });
}
