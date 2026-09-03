import 'package:tryzeon/core/error/failures.dart';

/// Decouples the controller's logic from the UI reaction (haptics,
/// notifications, upgrade dialog) the page performs.
sealed class TryonOutcome {
  const TryonOutcome();
}

class TryonSucceeded extends TryonOutcome {
  const TryonSucceeded();
}

class TryonAvatarMissing extends TryonOutcome {
  const TryonAvatarMissing();
}

/// [isVideo] selects the upgrade copy.
class TryonRateLimited extends TryonOutcome {
  const TryonRateLimited({required this.isVideo});

  final bool isVideo;
}

class TryonFailed extends TryonOutcome {
  const TryonFailed(this.failure);

  final Failure failure;
}
