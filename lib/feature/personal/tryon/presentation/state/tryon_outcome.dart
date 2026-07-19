import 'package:tryzeon/core/error/failures.dart';

/// Result of a try-on orchestration, decoupling the controller's logic from the
/// UI reaction (haptics, notifications, upgrade dialog) the page performs.
sealed class TryonOutcome {
  const TryonOutcome();
}

/// A try-on [outcome] tagged with a monotonic [seq]. The seq guarantees that two
/// otherwise-identical outcomes are still delivered as distinct events to
/// `ref.listen` — Dart canonicalizes a `const TryonSucceeded()` to a single
/// instance, so consecutive successes would otherwise compare equal and be
/// swallowed.
class TryonOutcomeEvent {
  const TryonOutcomeEvent(this.seq, this.outcome);

  final int seq;
  final TryonOutcome outcome;
}

/// Try-on completed and the gallery was updated.
class TryonSucceeded extends TryonOutcome {
  const TryonSucceeded();
}

/// No avatar was available — the user must upload a photo first.
class TryonAvatarMissing extends TryonOutcome {
  const TryonAvatarMissing();
}

/// The daily try-on quota was exhausted; [isVideo] selects the upgrade copy.
class TryonRateLimited extends TryonOutcome {
  const TryonRateLimited({required this.isVideo});

  final bool isVideo;
}

/// Try-on failed for any other reason.
class TryonFailed extends TryonOutcome {
  const TryonFailed(this.failure);

  final Failure failure;
}
