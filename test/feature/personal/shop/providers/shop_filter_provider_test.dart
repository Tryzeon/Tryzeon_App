import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/common/clothing_style/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/product_attributes/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/personal/shop/providers/shop_filter_provider.dart';

void main() {
  ProviderContainer makeContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  test('setStyles stores a non-empty selection', () {
    final container = makeContainer();
    container.read(shopFilterProvider.notifier).setStyles({ClothingStyle.casual});
    expect(container.read(shopFilterProvider).styles, {ClothingStyle.casual});
  });

  test('setStyles normalizes an empty set to null', () {
    final container = makeContainer();
    container.read(shopFilterProvider.notifier).setStyles(<ClothingStyle>{});
    expect(container.read(shopFilterProvider).styles, isNull);
  });

  test('setMaterials normalizes empty to null and stores non-empty', () {
    final container = makeContainer();
    final notifier = container.read(shopFilterProvider.notifier);
    notifier.setMaterials({'棉'});
    expect(container.read(shopFilterProvider).materials, {'棉'});
    notifier.setMaterials(<String>{});
    expect(container.read(shopFilterProvider).materials, isNull);
  });

  test('setElasticities stores selection', () {
    final container = makeContainer();
    container.read(shopFilterProvider.notifier).setElasticities({ProductElasticity.high});
    expect(container.read(shopFilterProvider).elasticities, {ProductElasticity.high});
  });

  test('reset clears filters but preserves gender', () {
    final container = makeContainer();
    final notifier = container.read(shopFilterProvider.notifier);
    notifier.setGender(ProductGender.female);
    notifier.setMaterials({'棉'});
    notifier.setChannels({StoreChannel.online});
    notifier.reset();
    final state = container.read(shopFilterProvider);
    expect(state.gender, ProductGender.female);
    expect(state.materials, isNull);
    expect(state.channels, isNull);
  });
}
