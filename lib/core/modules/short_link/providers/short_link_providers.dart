import 'dart:async';

import 'package:chottu_link/chottu_link.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/modules/short_link/data/datasources/short_link_remote_datasource.dart';
import 'package:tryzeon/core/modules/short_link/data/pending_short_link.dart';
import 'package:tryzeon/core/modules/short_link/data/short_link_code.dart';
import 'package:tryzeon/core/router/app_router.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/utils/app_logger.dart';

part 'short_link_providers.g.dart';

/// Short Link Remote DataSource Provider
@riverpod
ShortLinkRemoteDataSource shortLinkRemoteDataSource(final Ref ref) {
  return ShortLinkRemoteDataSource(Supabase.instance.client);
}

String _currentPlatform() => switch (defaultTargetPlatform) {
  TargetPlatform.iOS => 'ios',
  TargetPlatform.android => 'android',
  _ => 'other',
};

/// Bridges ChottuLink deferred deep links into the app.
///
/// A deferred link can arrive (via the ChottuLink SDK) before the user has
/// authenticated, so the code is stashed and flushed once a session exists — at
/// which point we record the identified open and navigate to its target.
///
/// Must be kept alive for the whole app lifecycle — read it once at the root
/// widget so the subscriptions are established at startup.
@Riverpod(keepAlive: true)
void deferredLinkSync(final Ref ref) {
  final auth = Supabase.instance.client.auth;

  Future<void> flush() async {
    if (auth.currentUser == null) return;

    final pending = await PendingShortLink.read();
    if (pending == null) return;

    try {
      final target = await ref
          .read(shortLinkRemoteDataSourceProvider)
          .recordOpen(
            code: pending.code,
            source: pending.source,
            platform: _currentPlatform(),
          );

      await PendingShortLink.clear();

      if (target != null) {
        ref
            .read(appRouterProvider)
            .go(
              target.targetType == 'store'
                  ? AppRoutes.personalShopStorePath(target.targetId)
                  : AppRoutes.personalShopProductPath(target.targetId),
            );
      }
    } catch (e, stack) {
      AppLogger.error('Deferred link flush failed (ignored)', e, stack);
    }
  }

  final linkSub = ChottuLink.onLinkReceivedWithMeta.listen((final resolved) async {
    // Prefer `resolved.link` (our destination URL, tryzeon.com/s/{code}); the
    // short URLs are ChottuLink's own branded slugs, not our code.
    final code = resolveShortLinkCode(
      link: resolved.link,
      shortLink: resolved.shortLink,
      shortLinkRaw: resolved.shortLinkRaw,
    );
    if (code == null) {
      AppLogger.warning('Deferred link had no resolvable code: ${resolved.shortLink}');
      return;
    }

    await PendingShortLink.stash(code: code, source: 'deferred');

    await flush();
  });

  final authSub = auth.onAuthStateChange.listen((final state) {
    if (state.event == AuthChangeEvent.signedIn) {
      unawaited(flush());
    }
  });

  ref.onDispose(() {
    linkSub.cancel();
    authSub.cancel();
  });
}
