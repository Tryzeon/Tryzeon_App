import 'package:go_router/go_router.dart';
import 'package:tryzeon/core/modules/revenue_cat/presentation/pages/paywall_page.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/router/shells/personal_shell.dart';
import 'package:tryzeon/feature/personal/account/presentation/pages/account_page.dart';
import 'package:tryzeon/feature/personal/chat/presentation/pages/chat_page.dart';
import 'package:tryzeon/feature/personal/onboarding/presentation/pages/personal_onboarding_page.dart';
import 'package:tryzeon/feature/personal/settings/presentation/pages/body_measurements_settings_page.dart';
import 'package:tryzeon/feature/personal/settings/presentation/pages/profile_settings_page.dart';
import 'package:tryzeon/feature/personal/settings/presentation/pages/settings_page.dart';
import 'package:tryzeon/feature/personal/settings/presentation/pages/style_preferences_settings_page.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/presentation/pages/product_detail_page.dart';
import 'package:tryzeon/feature/personal/shop/presentation/pages/shop_page.dart';
import 'package:tryzeon/feature/personal/shop/presentation/pages/store_page.dart';
import 'package:tryzeon/feature/personal/subscription/presentation/pages/subscription_page.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/pages/home_page.dart';
import 'package:tryzeon/feature/personal/wardrobe/presentation/pages/wardrobe_item_detail_page.dart';
import 'package:tryzeon/feature/personal/wardrobe/presentation/pages/wardrobe_page.dart';

final personalShellRoute = StatefulShellRoute.indexedStack(
  builder: (final context, final state, final navigationShell) =>
      PersonalShell(navigationShell: navigationShell),
  branches: [
    // Branch 0: Home
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: AppRoutes.personalHome,
          builder: (final context, final state) => const HomePage(),
        ),
      ],
    ),
    // Branch 1: Shop
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: AppRoutes.personalShop,
          builder: (final context, final state) => const ShopPage(),
          routes: [
            GoRoute(
              path: 'product/:id',
              builder: (final context, final state) {
                final productId = state.pathParameters['id']!;
                return ProductDetailPage(
                  productId: productId,
                  initialProduct: state.extra as ShopProduct?,
                );
              },
            ),
            GoRoute(
              path: 'store/:storeId',
              builder: (final context, final state) {
                final storeId = state.pathParameters['storeId']!;
                return StorePage(storeId: storeId);
              },
            ),
          ],
        ),
      ],
    ),
    // Branch 2: Chat
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: AppRoutes.personalChat,
          builder: (final context, final state) => const ChatPage(),
        ),
      ],
    ),
    // Branch 3: Wardrobe
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: AppRoutes.personalWardrobe,
          builder: (final context, final state) => const WardrobePage(),
          routes: [
            GoRoute(
              path: 'item/:id',
              builder: (final context, final state) {
                final itemId = state.pathParameters['id']!;
                return WardrobeItemDetailPage(itemId: itemId);
              },
            ),
          ],
        ),
      ],
    ),
    // Branch 4: Account
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: AppRoutes.personalAccount,
          builder: (final context, final state) => const AccountPage(),
        ),
      ],
    ),
  ],
);

final personalFullScreenRoutes = [
  GoRoute(
    path: AppRoutes.personalSettings,
    builder: (final context, final state) => const PersonalSettingsPage(),
    routes: [
      GoRoute(
        path: 'profile',
        builder: (final context, final state) => const PersonalProfileSettingsPage(),
      ),
      GoRoute(
        path: 'body-measurements',
        builder: (final context, final state) => const BodyMeasurementsSettingsPage(),
      ),
      GoRoute(
        path: 'style-preferences',
        builder: (final context, final state) => const StylePreferencesSettingsPage(),
      ),
      GoRoute(
        path: 'subscription',
        builder: (final context, final state) => const SubscriptionPage(),
      ),
    ],
  ),
  GoRoute(
    path: AppRoutes.personalOnboarding,
    builder: (final context, final state) => const PersonalOnboardingPage(),
  ),
  GoRoute(
    path: AppRoutes.personalPaywall,
    builder: (final context, final state) => const PaywallPage(),
  ),
];
