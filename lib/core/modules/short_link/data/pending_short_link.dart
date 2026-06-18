import 'package:shared_preferences/shared_preferences.dart';

/// A short-link `code` captured while the user was unauthenticated, to be
/// recorded and navigated to once a session exists.
///
/// Written by the router (an installed-but-logged-out open of `/s/{code}`) and
/// by the ChottuLink SDK (a deferred install); flushed by `deferredLinkSync`
/// on sign-in. Centralizing the keys keeps both producers in sync.
class PendingShortLink {
  const PendingShortLink({required this.code, required this.source});

  final String code;
  final String source;

  static const _codeKey = 'pending_link_code';
  static const _sourceKey = 'pending_link_source';

  static Future<void> stash({
    required final String code,
    required final String source,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_codeKey, code);
    await prefs.setString(_sourceKey, source);
  }

  static Future<PendingShortLink?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_codeKey);
    if (code == null) return null;
    return PendingShortLink(
      code: code,
      source: prefs.getString(_sourceKey) ?? 'deferred',
    );
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_codeKey);
    await prefs.remove(_sourceKey);
  }
}
