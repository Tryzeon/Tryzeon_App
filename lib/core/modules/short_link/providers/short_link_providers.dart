import 'package:chottu_link/chottu_link.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/modules/short_link/data/datasources/short_link_remote_datasource.dart';
import 'package:tryzeon/core/modules/short_link/data/short_link_code.dart';
import 'package:tryzeon/core/modules/short_link/providers/pending_link_provider.dart';
import 'package:tryzeon/core/utils/app_logger.dart';

part 'short_link_providers.g.dart';

/// Short Link Remote DataSource Provider
@riverpod
ShortLinkRemoteDataSource shortLinkRemoteDataSource(final Ref ref) {
  return ShortLinkRemoteDataSource(Supabase.instance.client);
}

/// Captures ChottuLink deferred deep links into [pendingLinkProvider].
///
/// Navigation is owned by the router redirect (which consumes the pending link
/// after auth + onboarding) and [LinkResolverPage] — this provider only
/// captures. A deferred link can arrive before authentication, so it is stashed
/// and consumed later. Kept alive for the whole app lifecycle — read it once at
/// the root widget so the subscription is established at startup.
@Riverpod(keepAlive: true)
void deferredLinkSync(final Ref ref) {
  final linkSub = ChottuLink.onLinkReceivedWithMeta.listen((final resolved) {
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

    ref
        .read(pendingLinkProvider.notifier)
        .set(code: code, source: (resolved.isDeferred ?? false) ? 'deferred' : 'app');
  });

  ref.onDispose(linkSub.cancel);
}
