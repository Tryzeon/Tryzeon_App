import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/feature/store/account/presentation/state/unlist_reminder.dart';
import 'package:tryzeon/feature/store/analytics/providers/store_analytics_providers.dart';
import 'package:tryzeon/feature/store/products/providers/store_products_providers.dart';

part 'unlist_reminder_providers.g.dart';

/// Follows the dashboard's month filter, since the analytics it joins already
/// does.
@riverpod
Future<List<UnlistReminder>> unlistReminders(final Ref ref) async {
  final products = await ref.watch(productsProvider.future);
  final summaries = await ref.watch(productAnalyticsSummariesProvider.future);

  return selectUnlistReminders(products, {
    for (final summary in summaries) summary.productId: summary.purchaseClickCount,
  });
}
