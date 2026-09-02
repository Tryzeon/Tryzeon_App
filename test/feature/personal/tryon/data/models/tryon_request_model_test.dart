import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/personal/tryon/data/models/tryon_request_model.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_engine.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_garment.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_request.dart';

void main() {
  const garments = [TryonGarment.product(productId: 'p1')];

  test('omits the avatar field entirely when there is no override', () {
    final body = TryonRequestModel.fromDomain(
      const TryonRequest.generate(
        requestId: 'r1',
        garments: garments,
        mode: TryonMode.image,
        engine: TryonEngine.standard,
      ),
    ).toJson();

    expect(body.containsKey('avatar'), isFalse);
    expect(body['garments'], [
      {'productId': 'p1'},
    ]);
  });

  test('sends a custom avatar as inline base64', () {
    final body = TryonRequestModel.fromDomain(
      const TryonRequest.generate(
        requestId: 'r1',
        garments: garments,
        mode: TryonMode.image,
        engine: TryonEngine.standard,
        avatarBase64: 'AAAA',
      ),
    ).toJson();

    expect(body['avatar'], {'base64': 'AAAA'});
  });

  test('sends a product garment with its size when one is known', () {
    final body = TryonRequestModel.fromDomain(
      const TryonRequest.generate(
        requestId: 'r1',
        garments: [TryonGarment.product(productId: 'p1', sizeId: 's1')],
        mode: TryonMode.image,
        engine: TryonEngine.standard,
      ),
    ).toJson();

    expect(body['garments'], [
      {'productId': 'p1', 'sizeId': 's1'},
    ]);
  });

  test('sends a wardrobe garment as a bare item reference', () {
    final body = TryonRequestModel.fromDomain(
      const TryonRequest.generate(
        requestId: 'r1',
        garments: [TryonGarment.wardrobe(wardrobeItemId: 'w1')],
        mode: TryonMode.image,
        engine: TryonEngine.standard,
      ),
    ).toJson();

    expect(body['garments'], [
      {'wardrobeItemId': 'w1'},
    ]);
  });

  test('omits the sizeId key entirely when no size is known', () {
    final body = TryonRequestModel.fromDomain(
      const TryonRequest.generate(
        requestId: 'r1',
        garments: garments,
        mode: TryonMode.image,
        engine: TryonEngine.standard,
      ),
    ).toJson();

    expect(body['garments'], [
      {'productId': 'p1'},
    ]);
  });

  test('sends an animate request as a baseImage with no garments', () {
    final body = TryonRequestModel.fromDomain(
      const TryonRequest.animate(
        requestId: 'r1',
        baseImageBase64: 'FINISHED',
        engine: TryonEngine.standard,
        transitionPrompt: 'spin',
      ),
    ).toJson();

    expect(body['mode'], 'video');
    expect(body['baseImage'], {'base64': 'FINISHED'});
    expect(body['transitionPrompt'], 'spin');
    expect(body.containsKey('garments'), isFalse);
    expect(body.containsKey('avatar'), isFalse);
    expect(body.containsKey('scenePrompt'), isFalse);
    expect(body.containsKey('stylingPrompt'), isFalse);
  });

  test('omits the transitionPrompt when the user set no style', () {
    final body = TryonRequestModel.fromDomain(
      const TryonRequest.animate(
        requestId: 'r1',
        baseImageBase64: 'FINISHED',
        engine: TryonEngine.standard,
      ),
    ).toJson();

    expect(body.containsKey('transitionPrompt'), isFalse);
  });

  test('a generate request never carries a baseImage', () {
    final body = TryonRequestModel.fromDomain(
      const TryonRequest.generate(
        requestId: 'r1',
        garments: garments,
        mode: TryonMode.video,
        engine: TryonEngine.standard,
      ),
    ).toJson();

    expect(body.containsKey('baseImage'), isFalse);
    expect(body['garments'], [
      {'productId': 'p1'},
    ]);
  });

  test('sends the stylingPrompt when the user set one', () {
    final body = TryonRequestModel.fromDomain(
      const TryonRequest.generate(
        requestId: 'r1',
        garments: garments,
        mode: TryonMode.image,
        engine: TryonEngine.standard,
        stylingPrompt: '紮進褲頭',
      ),
    ).toJson();

    expect(body['stylingPrompt'], '紮進褲頭');
  });

  test('omits the stylingPrompt when the user set no styling', () {
    final body = TryonRequestModel.fromDomain(
      const TryonRequest.generate(
        requestId: 'r1',
        garments: garments,
        mode: TryonMode.image,
        engine: TryonEngine.standard,
      ),
    ).toJson();

    expect(body.containsKey('stylingPrompt'), isFalse);
  });

  test('sends the engine only when the user picked the advanced one', () {
    final body = TryonRequestModel.fromDomain(
      const TryonRequest.generate(
        requestId: 'r1',
        garments: garments,
        mode: TryonMode.image,
        engine: TryonEngine.advanced,
      ),
    ).toJson();

    expect(body['engine'], 'advanced');
  });

  test('names the engine on every body, the standard one included', () {
    final body = TryonRequestModel.fromDomain(
      const TryonRequest.generate(
        requestId: 'r1',
        garments: garments,
        mode: TryonMode.image,
        engine: TryonEngine.standard,
      ),
    ).toJson();

    expect(body['engine'], 'standard');
  });

  test('an animate request carries the engine even though no image is generated', () {
    final body = TryonRequestModel.fromDomain(
      const TryonRequest.animate(
        requestId: 'r1',
        baseImageBase64: 'FINISHED',
        engine: TryonEngine.advanced,
      ),
    ).toJson();

    expect(body['engine'], 'advanced');
  });

  test('an animate request reports video as its mode', () {
    const request = TryonRequest.animate(
      requestId: 'r1',
      baseImageBase64: 'FINISHED',
      engine: TryonEngine.standard,
    );

    expect(request.mode, TryonMode.video);
  });
}
