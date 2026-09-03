import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_filter.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/providers/shop_providers.dart';
import 'package:typed_result/typed_result.dart';

part 'shop_products_notifier.freezed.dart';
part 'shop_products_notifier.g.dart';

@freezed
sealed class ShopProductsState with _$ShopProductsState {
  const factory ShopProductsState({
    required final List<ShopProduct> items,
    required final bool hasMore,
    @Default(false) final bool isLoadingMore,
  }) = _ShopProductsState;
}

@riverpod
class ShopProductsNotifier extends _$ShopProductsNotifier {
  static const _pageSize = 20;

  @override
  Future<ShopProductsState> build(final ShopFilter filter) async {
    final useCase = ref.watch(listShopProductsProvider);
    final result = await useCase(filter: filter, limit: _pageSize, offset: 0);
    if (result.isFailure) {
      throw result.getError()!;
    }
    final items = result.get()!;
    return ShopProductsState(items: items, hasMore: items.length == _pageSize);
  }

  Future<void> loadMore() async {
    final ref = this.ref; // capture THIS build's Ref to detect rebuild/dispose
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    final useCase = ref.read(listShopProductsProvider);
    final result = await useCase(
      filter: filter,
      limit: _pageSize,
      offset: current.items.length,
    );

    if (!ref.mounted) return;

    if (result.isFailure) {
      AppLogger.warning('Failed to load more shop products', result.getError());
      state = AsyncData(current.copyWith(isLoadingMore: false));
      return;
    }

    final more = result.get()!;
    state = AsyncData(
      ShopProductsState(
        items: [...current.items, ...more],
        hasMore: more.length == _pageSize,
        isLoadingMore: false,
      ),
    );
  }
}
