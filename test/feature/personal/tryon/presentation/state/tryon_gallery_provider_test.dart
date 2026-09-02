import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_garment.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_result.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_subject.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/tryon_gallery_entry.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/tryon_gallery_provider.dart';

void main() {
  const imageSubject = TryonSubject.generate(
    garments: [TryonGarment.product(productId: 'p1')],
    mode: TryonMode.image,
  );

  const videoSubject = TryonSubject.generate(
    garments: [TryonGarment.product(productId: 'p1')],
    mode: TryonMode.video,
  );

  TryonGalleryNotifier makeNotifier() {
    final container = ProviderContainer(
      overrides: [isAuthenticatedProvider.overrideWithValue(true)],
    );
    addTearDown(container.dispose);
    return container.read(tryonGalleryProvider.notifier);
  }

  test('a placeholder takes its mode from the subject it was started with', () {
    final notifier = makeNotifier()..addPending(id: 'a', subject: videoSubject);

    final entry = notifier.state.entries.single;
    expect(entry, isA<PendingTryonEntry>());
    expect(entry.mode, TryonMode.video);
  });

  test('the finished entry keeps the subject its own placeholder carried', () {
    // The one that finishes is not the first: with a single entry, a `complete`
    // reading the subject off the wrong row would still pass.
    final notifier = makeNotifier()
      ..addPending(id: 'a', subject: imageSubject)
      ..addPending(id: 'b', subject: videoSubject);

    final completed = notifier.complete(
      const TryonResult(id: 'b', mode: TryonMode.video, videoUrl: 'u'),
    );

    expect(completed, isTrue);
    final entry = notifier.state.entries.last;
    expect(entry, isA<FinishedTryonEntry>());
    expect(entry.subject, videoSubject);
  });

  test('completing an entry the user already dropped keeps it gone', () {
    final notifier = makeNotifier()..addPending(id: 'a', subject: imageSubject);
    notifier.removeById('a');

    final completed = notifier.complete(
      const TryonResult(id: 'a', mode: TryonMode.image, imageUrl: 'u'),
    );

    expect(completed, isFalse);
    expect(notifier.state.entries, isEmpty);
  });

  test('each entry keeps its own subject', () {
    final notifier = makeNotifier()
      ..addPending(id: 'a', subject: imageSubject)
      ..addPending(id: 'b', subject: videoSubject);

    expect(notifier.state.entries.map((final e) => e.subject), [
      imageSubject,
      videoSubject,
    ]);
  });
}
