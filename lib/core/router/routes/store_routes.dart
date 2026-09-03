import 'package:go_router/go_router.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/router/shells/store_shell.dart';
import 'package:tryzeon/feature/store/account/presentation/pages/store_account_page.dart';
import 'package:tryzeon/feature/store/onboarding/presentation/pages/store_onboarding_page.dart';
import 'package:tryzeon/feature/store/product/presentation/pages/add_product_page.dart';
import 'package:tryzeon/feature/store/product/presentation/pages/edit_product_page.dart';
import 'package:tryzeon/feature/store/product/presentation/pages/store_products_page.dart';
import 'package:tryzeon/feature/store/settings/presentation/pages/profile_settings_page.dart';
import 'package:tryzeon/feature/store/settings/presentation/pages/settings_page.dart';

final storeShellRoute = StatefulShellRoute.indexedStack(
  builder: (final context, final state, final navigationShell) =>
      StoreShell(navigationShell: navigationShell),
  branches: [
    // Branch 0: Products
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: AppRoutes.dashboardProducts,
          builder: (final context, final state) => const StoreProductsPage(),
        ),
      ],
    ),
    // Branch 1: Account
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: AppRoutes.dashboardAccount,
          builder: (final context, final state) => const StoreAccountPage(),
        ),
      ],
    ),
  ],
);

final storeFullScreenRoutes = [
  GoRoute(
    path: AppRoutes.dashboardOnboarding,
    builder: (final context, final state) => const StoreOnboardingPage(),
  ),
  GoRoute(
    path: AppRoutes.dashboardSettings,
    builder: (final context, final state) => const StoreSettingsPage(),
    routes: [
      GoRoute(
        path: 'profile',
        builder: (final context, final state) => const StoreProfileSettingsPage(),
      ),
    ],
  ),
  // Must precede dashboardProductDetail ('/:id') so the static path wins.
  GoRoute(
    path: AppRoutes.dashboardProductAdd,
    builder: (final context, final state) => const AddProductPage(),
  ),
  GoRoute(
    path: AppRoutes.dashboardProductDetail,
    builder: (final context, final state) {
      final productId = state.pathParameters['id']!;
      return EditProductPage(productId: productId);
    },
  ),
];
