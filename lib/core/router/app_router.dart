import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/router/auth_refresh_listenable.dart';
import 'package:tryzeon/core/router/routes/auth_routes.dart';
import 'package:tryzeon/core/router/routes/deep_link_routes.dart';
import 'package:tryzeon/core/router/routes/personal_routes.dart';
import 'package:tryzeon/core/router/routes/store_routes.dart';
import 'package:tryzeon/feature/auth/domain/entities/user_type.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/store/profile/providers/store_profile_providers.dart';
import 'package:tryzeon/main.dart';
import 'package:typed_result/typed_result.dart';

part 'app_router.g.dart';

@riverpod
Raw<GoRouter> appRouter(final Ref ref) {
  final supabase = Supabase.instance.client;
  final authStream = supabase.auth.onAuthStateChange;
  final refreshListenable = AuthRefreshListenable(authStream);

  ref.onDispose(refreshListenable.dispose);

  final router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppRoutes.login,
    refreshListenable: refreshListenable,
    observers: [FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance)],
    redirect: (final context, final state) {
      final isLoggedIn = supabase.auth.currentSession != null;
      final path = state.matchedLocation;
      final isAuthPath = path == AppRoutes.login;

      // 1. 未登入 → 導向登入頁
      if (!isLoggedIn) {
        return isAuthPath ? null : AppRoutes.login;
      }

      // 2. 已登入但仍處於登入頁 → 導向首頁
      if (isAuthPath) return _resolveHomePath(ref);

      // 3. 商家 Onboarding 攔截（排除 Deep Link 與 Onboarding 頁面本身）
      final storeRedirect = _handleStoreOnboardingRedirect(
        path,
        ref.read(storeProfileProvider),
      );
      if (storeRedirect != null) return storeRedirect;

      // 4. 個人 Onboarding 攔截（deep link 內容頁在內部豁免，優先顯示）
      final personalRedirect = _handlePersonalOnboardingRedirect(
        path,
        ref.read(userProfileProvider),
      );
      if (personalRedirect != null) return personalRedirect;

      return null;
    },
    routes: [
      authRoutes,
      personalShellRoute,
      ...personalFullScreenRoutes,
      storeShellRoute,
      ...storeFullScreenRoutes,
      ...deepLinkRoutes,
    ],
  );

  // 監聽 store profile 變化，觸發 redirect 重新評估，
  // 而不是重建整個 GoRouter（避免覆蓋 deep link 導航）。
  ref.listen(storeProfileProvider, (final _, final _) {
    refreshListenable.refresh();
  });

  ref.listen(userProfileProvider, (final _, final _) {
    refreshListenable.refresh();
  });

  return router;
}

Future<String> _resolveHomePath(final Ref ref) async {
  final getLoginType = ref.read(getLastLoginTypeUseCaseProvider);
  final result = await getLoginType();
  final userType = result.get();
  return AppRoutes.homeForUserType(userType ?? UserType.personal);
}

String? _handleStoreOnboardingRedirect(
  final String path,
  final AsyncValue<dynamic> storeProfileAsync,
) {
  if (!path.startsWith('/dashboard')) return null;
  if (storeProfileAsync.isLoading || storeProfileAsync.hasError) return null;

  final hasProfile = storeProfileAsync.asData?.value != null;
  if (path == AppRoutes.dashboardOnboarding) {
    return hasProfile ? AppRoutes.dashboardAccount : null;
  }

  return hasProfile ? null : AppRoutes.dashboardOnboarding;
}

String? _handlePersonalOnboardingRedirect(
  final String path,
  final AsyncValue<dynamic> userProfileAsync,
) {
  if (!path.startsWith('/personal')) return null;

  if (path.startsWith('/personal/shop/product/') ||
      path.startsWith('/personal/shop/store/')) {
    return null;
  }

  if (userProfileAsync.isLoading || userProfileAsync.hasError) return null;

  final profile = userProfileAsync.asData?.value;
  final isOnboarded = (profile?.isOnboarded as bool?) ?? false;
  if (path == AppRoutes.personalOnboarding) {
    return isOnboarded ? AppRoutes.personalHome : null;
  }

  return isOnboarded ? null : AppRoutes.personalOnboarding;
}
