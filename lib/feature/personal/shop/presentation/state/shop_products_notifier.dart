import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_filter.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/providers/shop_providers.dart';
import 'package:typed_result/typed_result.dart';

part 'shop_products_notifier.freezed.dart';
part 'shop_products_notifier.g.dart';

/// The accumulated shop product list plus paging flags.
///
/// [items] accumulates across pages; [hasMore] is false once a page returns
/// fewer than [ShopProductsNotifier._pageSize] rows; [isLoadingMore] guards the
/// footer spinner and re-entrancy in [ShopProductsNotifier.loadMore].
@freezed
sealed class ShopProductsState with _$ShopProductsState {
  const factory ShopProductsState({
    required final List<ShopProduct> items,
    required final bool hasMore,
    @Default(false) final bool isLoadingMore,
  }) = _ShopProductsState;
}

/// Offset-paginated shop product list, keyed by [ShopFilter].
///
/// Supplies `limit`/`offset` to the use case, which the backend already
/// exposes as `p_limit`/`p_offset`. The family argument [filter] is available
/// as a generated getter and reused inside [loadMore].
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

  /// Appends the next page. No-op while a page is in flight, when the first
  /// page has not resolved, or once the end is reached. A failed page keeps
  /// the already-loaded items and just clears the spinner (logged, no throw).
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
