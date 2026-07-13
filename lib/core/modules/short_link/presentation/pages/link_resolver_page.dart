import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/modules/short_link/providers/pending_link_provider.dart';
import 'package:tryzeon/core/modules/short_link/providers/short_link_providers.dart';
import 'package:tryzeon/core/modules/short_link/short_link_destination.dart';

/// Resolver for an in-app short link (`tryzeon.com/s/{code}`).
///
/// Reached in every authenticated case (an installed App Link open, and the
/// router redirect after a captured link is consumed). Records the open, clears
/// the pending link, and navigates to the target — which the onboarding gate
/// lets through (deep-link content takes priority over onboarding).
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
        final destination = await resolveShortLinkDestination(
          code: code,
          service: ref.read(shortLinkServiceProvider),
          pending: ref.read(pendingLinkProvider),
          clearPending: ref.read(pendingLinkProvider.notifier).clear,
          platform: _platform,
        );
        if (context.mounted) context.go(destination);
      }

      resolve();
      return null;
    }, const []);

    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
