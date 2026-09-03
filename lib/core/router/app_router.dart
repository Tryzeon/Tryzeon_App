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

      // 1. Signed out → go to the login page
      if (!isLoggedIn) {
        return isAuthPath ? null : AppRoutes.login;
      }

      // 2. Signed in but still on the login page → go home
      if (isAuthPath) return _resolveHomePath(ref);

      // 3. Store onboarding gate (deep links and the onboarding pages
      //    themselves are excluded)
      final storeRedirect = _handleStoreOnboardingRedirect(
        path,
        ref.read(storeProfileProvider),
      );
      if (storeRedirect != null) return storeRedirect;

      // 4. Personal onboarding gate (deep-link content pages are exempted
      //    inside, so they take priority)
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

  // Listen for store profile changes to re-run redirect, rather than rebuilding
  // the whole GoRouter (which would clobber deep-link navigation).
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
