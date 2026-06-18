import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/modules/short_link/data/pending_short_link.dart';

part 'pending_link_provider.g.dart';

/// The single source of truth for a captured-but-not-yet-consumed short link.
///
/// In-memory only and kept alive for the app lifecycle: a capture survives
/// navigation and backgrounding within one session, but not a cold restart.
/// The router redirect reads this synchronously to decide navigation.
@Riverpod(keepAlive: true)
class PendingLink extends _$PendingLink {
  @override
  PendingShortLink? build() => null;

  /// Captures a link to be consumed after authentication + onboarding.
  void set({required final String code, required final String source}) =>
      state = PendingShortLink(code: code, source: source);

  /// Consumes the pending link. Called once the navigation destination has
  /// been decided, so a failed resolve cannot loop the router.
  void clear() => state = null;
}
