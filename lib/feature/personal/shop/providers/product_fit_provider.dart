import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/personal/shop/domain/services/product_fit_resolver.dart';

part 'product_fit_provider.g.dart';

/// Supplies the shopper context every fit judgement needs, so the product grid,
/// the store page, and the product detail page answer the same question the
/// same way.
///
/// Rebuilds only when the shopper's profile changes, which is what keeps the
/// grid from re-reading it on every scroll frame.
///
/// Reads through to `null` while the profile loads rather than blocking: a fit
/// banner is an enhancement to a browsable catalog, not a precondition for one,
/// and [ProductFitResolver] already reports "no measurements" as its own state.
@riverpod
ProductFitResolver productFitResolver(final Ref ref) {
  final userProfile = ref
      .watch(userProfileProvider)
      .maybeWhen(data: (final p) => p, orElse: () => null);
  return ProductFitResolver(body: userProfile?.measurements);
}
