import 'package:go_router/go_router.dart';
import 'package:tryzeon/core/router/app_routes.dart';

final deepLinkRoutes = [
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
