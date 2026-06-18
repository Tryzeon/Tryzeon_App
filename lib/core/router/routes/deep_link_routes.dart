import 'package:go_router/go_router.dart';
import 'package:tryzeon/core/modules/short_link/presentation/pages/link_resolver_page.dart';
import 'package:tryzeon/core/router/app_routes.dart';

final deepLinkRoutes = [
  GoRoute(
    path: AppRoutes.deepLinkShort,
    builder: (final context, final state) =>
        LinkResolverPage(code: state.pathParameters['code']!),
  ),
  GoRoute(
    path: AppRoutes.deepLinkProduct,
    redirect: (final context, final state) {
      final productId = state.pathParameters['productId']!;
      return AppRoutes.personalShopProductPath(productId);
    },
  ),
  GoRoute(
    path: AppRoutes.deepLinkStore,
    redirect: (final context, final state) {
      final storeId = state.pathParameters['storeId']!;
      return AppRoutes.personalShopStorePath(storeId);
    },
  ),
];
