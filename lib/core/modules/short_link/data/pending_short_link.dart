/// A short-link `code` captured while the user was unauthenticated, to be
/// recorded and navigated to once a session exists.
///
/// Held in memory only — the single source of truth is `pendingLinkProvider`.
/// A capture lives for the current app session; it is not persisted, so a cold
/// restart before the link is consumed drops it.
class PendingShortLink {
  const PendingShortLink({required this.code, required this.source});

  final String code;
  final String source;

  @override
  bool operator ==(final Object other) =>
      other is PendingShortLink && other.code == code && other.source == source;

  @override
  int get hashCode => Object.hash(code, source);
}
