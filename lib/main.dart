import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/env.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/revenue_cat/di/revenue_cat_providers.dart';
import 'package:tryzeon/core/presentation/widgets/app_upgrade_alert.dart';
import 'package:tryzeon/core/router/app_router.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:upgrader/upgrader.dart';
import 'firebase_options.dart';

// Global navigator key for upgrader dialog
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Duration? customRetry(final int retryCount, final Object error) {
  if (retryCount >= 3) return null;

  if (error is NetworkFailure) {
    return Duration(milliseconds: 200 * (1 << retryCount));
  }
  return null;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(!kDebugMode);

  FlutterError.onError = (final FlutterErrorDetails details) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  PlatformDispatcher.instance.onError = (final error, final stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
  );

  // RevenueCat SDK initialization
  try {
    if (kDebugMode) {
      await Purchases.setLogLevel(LogLevel.debug);
    }

    final purchasesConfig = PurchasesConfiguration(Env.revenueCatApiKey);
    await Purchases.configure(purchasesConfig);

  } catch (e, stack) {
    debugPrint('[RevenueCat] Initialization failed: $e');
    await FirebaseCrashlytics.instance.recordError(e, stack, fatal: false);
  }

  runApp(const ProviderScope(retry: customRetry, child: Tryzeon()));
}

class Tryzeon extends HookConsumerWidget {
  const Tryzeon({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    ref.watch(revenueCatIdentitySyncProvider);

    // Analytics Lifecycle Observer
    useOnAppLifecycleStateChange((final previous, final current) {
      if (current == AppLifecycleState.paused || current == AppLifecycleState.detached) {
        ref.read(analyticsEventQueueServiceProvider).forceFlush();
      }
    });

    final upgrader = useMemoized(
      () => Upgrader(durationUntilAlertAgain: const Duration(days: 3)),
    );

    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'TryZeon',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      builder: (final context, final child) =>
          AppUpgradeAlert(upgrader: upgrader, navigatorKey: navigatorKey, child: child),
    );
  }
}
