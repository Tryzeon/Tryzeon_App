import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/product_attributes/entities/product_attributes.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_filter.dart';

void main() {
  test('new advanced-filter fields default to null', () {
    const filter = ShopFilter();
    expect(filter.material, isNull);
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
    const base = ShopFilter(material: 'cotton');
    final next = base.copyWith(seasons: {ProductSeason.summer});
    expect(next.material, 'cotton');
    expect(next.seasons, {ProductSeason.summer});
  });
}
