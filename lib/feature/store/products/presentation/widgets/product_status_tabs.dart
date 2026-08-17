import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/presentation/mappers/product_status_ui_mapper.dart';
import 'package:tryzeon/feature/store/products/providers/store_products_providers.dart';

/// The 上架中 / 已下架 split.
///
/// A `TabBar` used only as a selector — no `TabBarView` beneath it. The two
/// buckets are mutually exclusive sets of the same list, so one grid, one
/// scroll view and one `RefreshIndicator` still serve both; the controller
/// only drives which status [ProductQuery] filters on.
///
/// Counts come from the unfiltered list on purpose: a number that shrank while
/// the owner typed would answer "what matched" twice over, and the grid
/// already answers that.
class ProductStatusTabs extends HookConsumerWidget {
  const ProductStatusTabs({super.key});

  static const _statuses = ProductStatus.values;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final selected = ref.watch(
      productQueryProvider.select((final query) => query.status),
    );
    final controller = useTabController(
      initialLength: _statuses.length,
      initialIndex: _statuses.indexOf(selected),
    );

    final counts = _countByStatus(ref.watch(productsProvider).value);

    return TabBar(
      controller: controller,
      onTap: (final index) =>
          ref.read(productQueryProvider.notifier).updateStatus(_statuses[index]),
      tabs: [
        for (final status in _statuses)
          Tab(
            text: counts == null
                ? status.tabLabel
                : '${status.tabLabel} ${counts[status] ?? 0}',
          ),
      ],
    );
  }
}

Map<ProductStatus, int>? _countByStatus(final List<Product>? products) {
  if (products == null) return null;
  final counts = <ProductStatus, int>{};
  for (final product in products) {
    counts[product.status] = (counts[product.status] ?? 0) + 1;
  }
  return counts;
}
