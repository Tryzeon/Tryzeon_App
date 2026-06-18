// Pure helpers for turning a ChottuLink-resolved link into our short-link
// `code`. Kept free of SDK / Riverpod dependencies so it stays unit-testable.

/// The `code` is the last non-empty path segment of a `tryzeon.com/s/{code}`
/// URL (query string and trailing slashes are ignored).
String? shortLinkCodeFromUrl(final String? url) {
  final uri = Uri.tryParse(url ?? '');
  if (uri == null) return null;
  final segments = uri.pathSegments.where((final s) => s.isNotEmpty);
  return segments.isEmpty ? null : segments.last;
}

/// Resolves the short-link `code` from a ChottuLink result, preferring the
/// destination URL (`link`, e.g. `tryzeon.com/s/{code}`) — the only field that
/// carries OUR code — over ChottuLink's own branded short URLs, whose last
/// segment is ChottuLink's slug, not our code.
String? resolveShortLinkCode({
  required final String? link,
  required final String? shortLink,
  required final String? shortLinkRaw,
}) =>
    shortLinkCodeFromUrl(link) ??
    shortLinkCodeFromUrl(shortLink) ??
    shortLinkCodeFromUrl(shortLinkRaw);
