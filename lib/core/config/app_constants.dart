class AppConstants {
  // URLs
  static const String webBaseUrl = 'https://tryzeon.com';
  static const String storeOnboardingFormUrl =
      'https://docs.google.com/forms/d/e/1FAIpQLScu_hKsOTUVcuB0R3sKnRh9cAbn7zchO7W8izdgG1N9-WC9AQ/viewform';
  static const String authCallbackUrl = 'com.tryzeon.app://login-callback';
  static const String googleMapsQueryUrl =
      'https://www.google.com/maps/search/?api=1&query=';
  static const String googleServerClientId =
      '924030382971-ppc2nttqs2dn977e4b6j79i83g03bk11.apps.googleusercontent.com';
  static const String lineChannelId = '2010556446';

  // Supabase Tables
  static const String tableUserProfiles = 'user_profiles';
  static const String tableStoreProfiles = 'store_profiles';
  static const String tableProducts = 'products';
  static const String tableProductSizes = 'product_sizes';
  static const String tableProductCategories = 'product_categories';
  static const String tableSubscriptionTiers = 'subscription_tiers';
  static const String tableWardrobeItems = 'wardrobe_items';
  static const String tableAnalyticsEvents = 'analytics_events';
  static const String tableAnalyticsProductMonthlySummary =
      'analytics_product_monthly_summary';
  static const String tableUserDailyUsage = 'user_daily_usage';

  // Supabase Buckets
  static const String bucketUserAvatars = 'user-avatars';
  static const String bucketWardrobeImages = 'wardrobe-images';

  // Supabase Functions
  static const String functionChat = 'chat';
  static const String functionTryon = 'tryon';
  static const String functionDeleteAccount = 'delete-account';
  static const String functionLogAnalyticsEvents = 'log_analytics_events';
  static const String functionAnalyzeWardrobeImage = 'analyze-wardrobe-image';
  static const String functionAnalyzeProductImage = 'analyze-product-image';
  static const String functionRecordLinkOpen = 'record_link_open';
  static const String functionParseSizeVoice = 'parse-size-voice';
  static const String functionStoreImages = 'store-images';
  static const String functionStoreImagesPresignLogo =
      '$functionStoreImages/presign-logo';
  static const String functionStoreImagesPresignProducts =
      '$functionStoreImages/presign-products';
  static const String functionStoreImagesDelete = '$functionStoreImages/delete';
  static const String functionLineAuth = 'line-auth';

  // Assets
  static const String defaultProfileImage = 'assets/images/profile/default.png';
  static const List<String> tryonLoadingAnimations = [
    'assets/videos/tryon-loading-animation-1.mp4',
    'assets/videos/tryon-loading-animation-2.mp4',
    'assets/videos/tryon-loading-animation-3.mp4',
    'assets/videos/tryon-loading-animation-4.mp4',
    'assets/videos/tryon-loading-animation-5.mp4',
  ];
  static const String logoMark = 'assets/images/logo/tryzeon_logomark.png';
  static const String logoWordmarkText = 'assets/images/logo/tryzeon_wordmark.png';

  // Logic
  static const ({int x, int y}) avatarAspectRatio = (x: 9, y: 16);
  static const int maxProductImages = 3;
  static const int otpResendCountdownSeconds = 60;
  static const int otpCodeLength = 6;
  static const double productVisibilityThreshold = 0.5;
  static const int signedUrlTtlSeconds = 3600;

  // RevenueCat
  static const String entitlementFreeId = 'free';
  static const String entitlementProId = 'pro';
  static const String entitlementMaxId = 'max';

  // Tryon Params
  static const String paramMode = 'mode';
  static const String modeImage = 'image';
  static const String modeVideo = 'video';
  static const String paramScenePrompt = 'scenePrompt';
  static const String paramTransitionPrompt = 'transitionPrompt';
  static const String paramGarmentImages = 'images';
  static const String paramProductId = 'productId';

  // Shared Preferences Keys
  static const String keyVideoScenePrompt = 'video_scene_prompt';
  static const String keyVideoTransitionPrompt = 'video_transition_prompt';

  // Stale Durations
  static const Duration staleDurationProductCategories = Duration(days: 7);
  static const Duration staleDurationUserProfile = Duration(days: 7);
  static const Duration staleDurationStoreProfile = Duration(days: 7);
  static const Duration staleDurationSubscriptionTier = Duration(days: 7);
}
