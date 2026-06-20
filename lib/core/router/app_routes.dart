import 'package:tryzeon/feature/auth/domain/entities/user_type.dart';

abstract final class AppRoutes {
  // Auth
  static const String login = '/login';
  static const String authCallback = '/auth/callback';

  // Personal (tabs)
  static const String personalHome = '/personal/home';
  static const String personalShop = '/personal/shop';
  static const String personalShopProduct = '/personal/shop/product/:id';
  static const String personalShopStore = '/personal/shop/store/:storeId';
  static const String personalChat = '/personal/chat';
  static const String personalWardrobe = '/personal/wardrobe';
  static const String personalWardrobeItem = '/personal/wardrobe/item/:id';
  static const String personalAccount = '/personal/account';

  // Personal (full screen, outside shell)
  static const String personalOnboarding = '/personal/onboarding';
  static const String personalSettings = '/personal/settings';
  static const String personalSettingsProfile = '/personal/settings/profile';
  static const String personalSettingsBodyMeasurements =
      '/personal/settings/body-measurements';
  static const String personalSettingsPreferences = '/personal/settings/preferences';
  static const String personalSettingsStyle = '/personal/settings/style-preferences';
  static const String personalSubscription = '/personal/settings/subscription';
  static const String personalPaywall = '/personal/paywall';

  // Store owner dashboard (tabs)
  static const String dashboardProducts = '/dashboard/products';
  static const String dashboardAccount = '/dashboard/account';

  // Store owner dashboard (full screen, outside shell)
  static const String dashboardOnboarding = '/dashboard/onboarding';
  static const String dashboardSettings = '/dashboard/settings';
  static const String dashboardSettingsProfile = '/dashboard/settings/profile';
  static const String dashboardProductAdd = '/dashboard/products/add';
  static const String dashboardProductDetail = '/dashboard/products/:id';

  // Deep link content routes (top-level, redirect to feature routes)
  static const String deepLinkProduct = '/product/:productId';
  static const String deepLinkStore = '/store/:storeId';
  // Tracked short link (QR/shares/campaigns).
  static const String deepLinkShort = '/s/:code';

  static String homeForUserType(final UserType userType) {
    return userType == UserType.store ? dashboardAccount : personalHome;
  }

  static String personalShopProductPath(final String productId) =>
      '/personal/shop/product/$productId';

  static String personalShopStorePath(final String storeId) =>
      '/personal/shop/store/$storeId';

  static String personalWardrobeItemPath(final String itemId) =>
      '/personal/wardrobe/item/$itemId';

  static String dashboardProductDetailPath(final String productId) =>
      '/dashboard/products/$productId';
}
