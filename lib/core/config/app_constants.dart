class AppConstants {
  // URLs
  static const String storeOnboardingFormUrl =
      'https://docs.google.com/forms/d/e/1FAIpQLScu_hKsOTUVcuB0R3sKnRh9cAbn7zchO7W8izdgG1N9-WC9AQ/viewform';
  static const String authCallbackUrl = 'io.supabase.tryzeon://login-callback';

  // Supabase Tables
  static const String tableStoreProfile = 'store_profile';
  static const String tableProducts = 'products';
  static const String tableProductSizes = 'product_sizes';
  static const String tableProductCategories = 'product_categories';
  static const String tableUserProfile = 'user_profile';
  static const String tableWardrobeItems = 'wardrobe_items';

  // Supabase Buckets
  static const String bucketStore = 'store';
  static const String bucketAvatars = 'avatars';
  static const String bucketWardrobe = 'wardrobe';

  // Supabase Functions
  static const String functionChat = 'chat';
  static const String functionTryon = 'tryon';

  // Assets
  static const String defaultProfileImage = 'assets/images/profile/default.png';

  // Timeouts & Durations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  static const Duration toastDuration = Duration(seconds: 3);
  static const Duration errorToastDuration = Duration(seconds: 10);

  // Logic
  static const int otpResendCountdownSeconds = 60;
  static const int otpCodeLength = 6;
}
