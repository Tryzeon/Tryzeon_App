import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/modules/short_link/providers/short_link_providers.dart';
import 'package:tryzeon/core/router/app_routes.dart';

/// Landing page for an in-app short link (tryzeon.com/s/{code}).
///
/// Records the identified open, resolves the code to a product/store and
/// redirects there. Shown only when the app is already installed and the OS
/// App Link opened the app directly; deferred installs are handled separately
/// via the platform SDK.
class LinkResolverPage extends HookConsumerWidget {
  const LinkResolverPage({required this.code, super.key});

  final String code;

  String get _platform => switch (defaultTargetPlatform) {
    TargetPlatform.iOS => 'ios',
    TargetPlatform.android => 'android',
    _ => 'other',
  };

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    useEffect(() {
      Future<void> resolve() async {
        try {
          final target = await ref
              .read(shortLinkRemoteDataSourceProvider)
              .recordOpen(code: code, platform: _platform, source: 'app');

          if (!context.mounted) return;

          if (target == null) {
            context.go(AppRoutes.personalHome);
            return;
          }

          context.go(
            target.targetType == 'store'
                ? AppRoutes.personalShopStorePath(target.targetId)
                : AppRoutes.personalShopProductPath(target.targetId),
          );
        } catch (_) {
          if (context.mounted) context.go(AppRoutes.personalHome);
        }
      }

      resolve();
      return null;
    }, const []);

    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
