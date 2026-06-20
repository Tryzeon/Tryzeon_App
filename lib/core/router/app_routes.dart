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
  static const String storeProducts = '/dashboard/products';
  static const String storeAccount = '/dashboard/account';

  // Store owner dashboard (full screen, outside shell)
  static const String storeOnboarding = '/dashboard/onboarding';
  static const String storeSettings = '/dashboard/settings';
  static const String storeSettingsProfile = '/dashboard/settings/profile';
  static const String storeProductAdd = '/dashboard/products/add';
  static const String storeProductDetail = '/dashboard/products/:id';

  // Deep link content routes (top-level, redirect to feature routes)
  static const String deepLinkProduct = '/product/:productId';
  static const String deepLinkStore = '/store/:storeId';
  // Tracked short link (QR/shares/campaigns).
  static const String deepLinkShort = '/s/:code';

  static String homeForUserType(final UserType userType) {
    return userType == UserType.store ? storeAccount : personalHome;
  }

  static String personalShopProductPath(final String productId) =>
      '/personal/shop/product/$productId';

  static String personalShopStorePath(final String storeId) =>
      '/personal/shop/store/$storeId';

  static String personalWardrobeItemPath(final String itemId) =>
      '/personal/wardrobe/item/$itemId';

  static String storeProductDetailPath(final String productId) =>
      '/dashboard/products/$productId';
}
