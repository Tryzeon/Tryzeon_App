import 'package:tryzeon/core/modules/short_link/data/pending_short_link.dart';
import 'package:tryzeon/core/modules/short_link/domain/services/short_link_service.dart';
import 'package:tryzeon/core/router/app_routes.dart';

/// Records the short-link open and returns the in-app destination path.
///
/// Always calls [clearPending] (success, unknown code, or error) so an
/// unknown/inactive code or a recording failure can never loop the router
/// back to the resolver. The recorded `source` is [pending]'s source when its
/// code matches [code] (a deferred/installed capture), otherwise `'app'` (an
/// OS-opened App Link with no captured intent). Returns
/// [AppRoutes.personalHome] for an unknown/inactive code or on error.
Future<String> resolveShortLinkDestination({
  required final String code,
  required final ShortLinkService service,
  required final PendingShortLink? pending,
  required final void Function() clearPending,
  required final String platform,
}) async {
  final source = pending?.code == code ? pending!.source : 'app';
  try {
    final target = await service.recordOpen(
      code: code,
      platform: platform,
      source: source,
    );
    clearPending();
    if (target == null) return AppRoutes.personalHome;
    return target.targetType == 'store'
        ? AppRoutes.personalShopStorePath(target.targetId)
        : AppRoutes.personalShopProductPath(target.targetId);
  } catch (_) {
    clearPending();
    return AppRoutes.personalHome;
  }
}
