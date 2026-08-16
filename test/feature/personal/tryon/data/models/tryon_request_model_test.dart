import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/personal/tryon/data/models/tryon_request_model.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_garment.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_request.dart';

void main() {
  const garments = [TryonGarment.product(productId: 'p1')];

  test('omits the avatar field entirely when there is no override', () {
    final body = TryonRequestModel.fromDomain(
      const TryonRequest(requestId: 'r1', garments: garments, mode: TryonMode.image),
    ).toJson();

    expect(body.containsKey('avatar'), isFalse);
    expect(body['garments'], [
      {'productId': 'p1'},
    ]);
  });

  test('sends a custom avatar as inline base64', () {
    final body = TryonRequestModel.fromDomain(
      const TryonRequest(
        requestId: 'r1',
        garments: garments,
        mode: TryonMode.image,
        avatarBase64: 'AAAA',
      ),
    ).toJson();

    expect(body['avatar'], {'base64': 'AAAA'});
  });

  test('sends a product garment with its size when one is known', () {
    final body = TryonRequestModel.fromDomain(
      const TryonRequest(
        requestId: 'r1',
        garments: [TryonGarment.product(productId: 'p1', sizeId: 's1')],
        mode: TryonMode.image,
      ),
    ).toJson();

    expect(body['garments'], [
      {'productId': 'p1', 'sizeId': 's1'},
    ]);
  });

  test('omits the sizeId key entirely when no size is known', () {
    final body = TryonRequestModel.fromDomain(
      const TryonRequest(requestId: 'r1', garments: garments, mode: TryonMode.image),
    ).toJson();

    expect(body['garments'], [
      {'productId': 'p1'},
    ]);
  });
}
