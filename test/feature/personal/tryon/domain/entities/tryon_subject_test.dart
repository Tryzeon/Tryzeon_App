import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_garment.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_image_source.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_subject.dart';

void main() {
  const product = TryonSubject.generate(
    garments: [TryonGarment.product(productId: 'p1', sizeId: 's1')],
    mode: TryonMode.image,
  );

  const ownPhoto = TryonSubject.generate(
    garments: [
      TryonGarment.images(images: [TryonImageSource.base64('AAAA')]),
    ],
    mode: TryonMode.image,
  );

  const wardrobe = TryonSubject.generate(
    garments: [TryonGarment.wardrobe(wardrobeItemId: 'w1')],
    mode: TryonMode.image,
  );

  test('a generate subject reports the mode it was asked for', () {
    expect(product.mode, TryonMode.image);
    expect(
      const TryonSubject.generate(garments: [], mode: TryonMode.video).mode,
      TryonMode.video,
    );
  });

  test('an animated subject is always a video', () {
    const subject = TryonSubject.animated(baseImageUrl: 'u', origin: product);

    expect(subject.mode, TryonMode.video);
  });

  test('a product try-on names the product it is of', () {
    expect(product.productId, 'p1');
  });

  test("a try-on of the user's own photo names no product", () {
    expect(ownPhoto.productId, isNull);
  });

  test('an animated subject names the product its base image was of', () {
    const subject = TryonSubject.animated(baseImageUrl: 'u', origin: product);

    expect(subject.productId, 'p1');
  });

  test('animating a photo of no product still names no product', () {
    const subject = TryonSubject.animated(baseImageUrl: 'u', origin: ownPhoto);

    expect(subject.productId, isNull);
  });

  test('a wardrobe try-on names the item it is of, and no product', () {
    expect(wardrobe.wardrobeItemId, 'w1');
    expect(wardrobe.productId, isNull);
  });

  test('an animated subject names the wardrobe item its base image was of', () {
    const subject = TryonSubject.animated(baseImageUrl: 'u', origin: wardrobe);

    expect(subject.wardrobeItemId, 'w1');
  });

  test('a product try-on names no wardrobe item', () {
    expect(product.wardrobeItemId, isNull);
  });
}
