import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/modules/short_link/data/short_link_code.dart';
import 'package:tryzeon/core/modules/short_link/providers/pending_link_provider.dart';
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

/// Matches deep link paths like `/store/<uuid>`.
final _storeDeepLinkPattern = RegExp(
  '^/store/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
);

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
    redirect: (final context, final state) async {
      final isLoggedIn = supabase.auth.currentSession != null;
      final path = state.matchedLocation;
      final isAuthPath = path == AppRoutes.login;

      // 1. 未登入 → 暫存 /s/{code} 掃碼意圖，導向登入頁
      if (!isLoggedIn) {
        if (isAuthPath) return null;
        if (path.startsWith('/s/')) {
          final shortCode = shortLinkCodeFromUrl(path);
          if (shortCode != null) {
            ref.read(pendingLinkProvider.notifier).set(code: shortCode, source: 'app');
          }
        }
        return AppRoutes.login;
      }

      // 2. 已登入 + 已 onboarding + 有 pending（且不在 resolver 上）→ 導向 /s/{code}。
      //    未 onboarding 時跳過，讓步驟 5 的 onboarding 攔截先跑；
      //    !path.startsWith('/s/') 可避免 resolver 自我重導的迴圈。
      final pending = ref.read(pendingLinkProvider);
      final isOnboarded =
          ref.read(userProfileProvider).asData?.value?.isOnboarded ?? false;
      if (pending != null && isOnboarded && !path.startsWith('/s/')) {
        return '/s/${pending.code}';
      }

      // 2b. 直接開 /s/{code} 但尚未 onboarding（已登入、未經 step 1 stash 的情況）→
      //     先暫存掃碼意圖、強制先 onboarding，完成後由步驟 2 消費，避免 resolver
      //     在 onboarding 前就消費掉目標。await profile 取得「確定」狀態，才不會在
      //     profile 仍載入時把已 onboarding 的使用者誤導去 onboarding 頁。
      if (path.startsWith('/s/')) {
        bool onboarded;
        try {
          final profile = await ref.read(userProfileProvider.future);
          onboarded = profile?.isOnboarded ?? false;
        } catch (_) {
          onboarded = true; // 載入失敗則不阻擋 resolver
        }
        if (!onboarded) {
          final shortCode = shortLinkCodeFromUrl(path);
          if (shortCode != null) {
            ref.read(pendingLinkProvider.notifier).set(code: shortCode, source: 'app');
          }
          return AppRoutes.personalOnboarding;
        }
      }

      // 3. 已登入但仍處於登入頁 → 導向首頁
      if (isAuthPath) return _resolveHomePath(ref);

      // 4. 商家 Onboarding 攔截 (排除 Deep Link 與 Onboarding 頁面本身)
      final storeProfileAsync = ref.read(storeProfileProvider);
      final storeRedirect = _handleStoreOnboardingRedirect(path, storeProfileAsync);
      if (storeRedirect != null) return storeRedirect;

      // 5. 個人 Onboarding 攔截
      final userProfileAsync = ref.read(userProfileProvider);
      final personalRedirect = _handlePersonalOnboardingRedirect(path, userProfileAsync);
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

  // 監聽 user profile 變化，觸發 redirect 重新評估（例如完成 onboarding 後）
  ref.listen(userProfileProvider, (final _, final _) {
    refreshListenable.refresh();
  });

  // 監聽 pending 短連結變化（例如 runtime 收到 deferred link、或啟動 hydrate），
  // 觸發 redirect 重新評估以消費它。
  ref.listen(pendingLinkProvider, (final _, final _) {
    refreshListenable.refresh();
  });

  return router;
}

/// 根據上次登入類型決定首頁路徑。
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
  if (!path.startsWith('/store')) return null;
  if (_storeDeepLinkPattern.hasMatch(path)) return null;
  if (storeProfileAsync.isLoading || storeProfileAsync.hasError) return null;

  final hasProfile = storeProfileAsync.asData?.value != null;
  if (path == AppRoutes.storeOnboarding) {
    return hasProfile ? AppRoutes.storeAccount : null;
  }

  return hasProfile ? null : AppRoutes.storeOnboarding;
}

String? _handlePersonalOnboardingRedirect(
  final String path,
  final AsyncValue<dynamic> userProfileAsync,
) {
  if (!path.startsWith('/personal')) return null;
  if (userProfileAsync.isLoading || userProfileAsync.hasError) return null;

  final profile = userProfileAsync.asData?.value;
  final isOnboarded = profile?.isOnboarded ?? false;
  if (path == AppRoutes.personalOnboarding) {
    return isOnboarded ? AppRoutes.personalHome : null;
  }

  return isOnboarded ? null : AppRoutes.personalOnboarding;
}
