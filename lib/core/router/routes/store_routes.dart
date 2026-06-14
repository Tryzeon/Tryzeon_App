import 'package:go_router/go_router.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/router/shells/store_shell.dart';
import 'package:tryzeon/feature/store/account/presentation/pages/store_account_page.dart';
import 'package:tryzeon/feature/store/onboarding/presentation/pages/store_onboarding_page.dart';
import 'package:tryzeon/feature/store/products/presentation/pages/add_product_page.dart';
import 'package:tryzeon/feature/store/products/presentation/pages/edit_product_page.dart';
import 'package:tryzeon/feature/store/products/presentation/pages/store_products_page.dart';
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
          path: AppRoutes.storeProducts,
          builder: (final context, final state) => const StoreProductsPage(),
        ),
      ],
    ),
    // Branch 1: Account
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: AppRoutes.storeAccount,
          builder: (final context, final state) => const StoreAccountPage(),
        ),
      ],
    ),
  ],
);

// Full-screen routes (no shell)
final storeFullScreenRoutes = [
  GoRoute(
    path: AppRoutes.storeOnboarding,
    builder: (final context, final state) => const StoreOnboardingPage(),
  ),
  GoRoute(
    path: AppRoutes.storeSettings,
    builder: (final context, final state) => const StoreSettingsPage(),
    routes: [
      GoRoute(
        path: 'profile',
        builder: (final context, final state) => const StoreProfileSettingsPage(),
      ),
    ],
  ),
  GoRoute(
    path: AppRoutes.storeProductAdd,
    builder: (final context, final state) => const AddProductPage(),
  ),
  GoRoute(
    path: AppRoutes.storeProductDetail,
    builder: (final context, final state) {
      final productId = state.pathParameters['id']!;
      return EditProductPage(productId: productId);
    },
  ),
];
