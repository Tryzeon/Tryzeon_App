import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/body_measurements/data/models/body_measurements_model.dart';
import 'package:tryzeon/feature/common/product_size/data/models/garment_measurements_model.dart';

/// `supabase/functions/_shared/tryon/fit.ts`'s `SizeMeasurements` and
/// `supabase/functions/_shared/tryon/user-profile.ts`'s `BodyMeasurements`
/// hand-copy the JSON keys these two Dart models emit. Nothing on the
/// TypeScript side asserts that copy stays correct, so a field rename here
/// would make the server silently stop attaching a `GARMENT FIT` section
/// instead of failing anywhere. This test is the tripwire: if it fails,
/// update `fit.ts`'s `SizeMeasurements` and/or `user-profile.ts`'s
/// `BodyMeasurements` to match before touching anything else.
void main() {
  test(
    'GarmentMeasurementsModel serializes exactly the 7 keys fit.ts expects '
    '(update supabase/functions/_shared/tryon/fit.ts SizeMeasurements if this fails)',
    () {
      const model = GarmentMeasurementsModel(
        shoulderWidth: 45,
        chestCircumference: 104,
        sleeveLength: 22,
        waistCircumference: 90,
        hipCircumference: 100,
        thighCircumference: 55,
        length: 68,
      );

      expect(model.toJson().keys.toSet(), {
        'shoulder_width',
        'chest_circumference',
        'sleeve_length',
        'waist_circumference',
        'hip_circumference',
        'thigh_circumference',
        'length',
      });
    },
  );

  test(
    'BodyMeasurementsModel serializes exactly the 7 keys user-profile.ts expects '
    '(update supabase/functions/_shared/user-profile.ts BodyMeasurements if this fails)',
    () {
      const model = BodyMeasurementsModel(
        height: 170,
        weight: 60,
        shoulder: 43,
        chest: 92,
        waist: 76,
        hips: 96,
        thigh: 54,
      );

      expect(model.toJson().keys.toSet(), {
        'height',
        'weight',
        'shoulder',
        'chest',
        'waist',
        'hips',
        'thigh',
      });
    },
  );
}
