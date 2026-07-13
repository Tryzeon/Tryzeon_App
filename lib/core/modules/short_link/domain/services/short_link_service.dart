import 'package:tryzeon/core/modules/short_link/domain/entities/link_target.dart';

/// Short-link resolution service.
abstract class ShortLinkService {
  /// Records an identified link open (the user is authenticated) and resolves
  /// the code to its destination so the caller can navigate.
  ///
  /// [source] is 'app' for an installed open or 'deferred' for an open
  /// delivered by the platform SDK after a deferred install.
  ///
  /// Returns `null` when the code is unknown or inactive.
  Future<LinkTarget?> recordOpen({
    required final String code,
    required final String platform,
    required final String source,
  });
}
