import 'package:tryzeon/core/error/failures.dart';

/// Result of a try-on orchestration, decoupling the controller's logic from the
/// UI reaction (haptics, notifications, upgrade dialog) the page performs.
sealed class TryOnOutcome {
  const TryOnOutcome();
}

/// Try-on completed and the gallery was updated.
class TryOnSucceeded extends TryOnOutcome {
  const TryOnSucceeded();
}

/// No avatar was available — the user must upload a photo first.
class TryOnAvatarMissing extends TryOnOutcome {
  const TryOnAvatarMissing();
}

/// The custom avatar image failed to load, so try-on was aborted.
class TryOnAvatarLoadFailed extends TryOnOutcome {
  const TryOnAvatarLoadFailed();
}

/// The daily try-on quota was exhausted; [isVideo] selects the upgrade copy.
class TryOnRateLimited extends TryOnOutcome {
  const TryOnRateLimited({required this.isVideo});

  final bool isVideo;
}

/// Try-on failed for any other reason.
class TryOnFailed extends TryOnOutcome {
  const TryOnFailed(this.failure);

  final Failure failure;
}
