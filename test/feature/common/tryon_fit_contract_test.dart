import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/body_measurements/data/models/body_measurements_model.dart';
import 'package:tryzeon/feature/common/body_measurements/domain/entities/body_measurement_type.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/product_size/data/models/garment_measurements_model.dart';
import 'package:tryzeon/feature/personal/shop/domain/services/ease_table.dart';

/// `supabase/functions/_shared/tryon/fit.ts` hand-copies two things from this
/// tree: the JSON keys the measurement models emit, and twelve ease thresholds
/// derived from [EaseTable]. Nothing on the TypeScript side asserts either copy
/// stays correct — a rename makes the server silently stop attaching a
/// `GARMENT FIT` section, and a re-calibration makes it keep describing the old
/// bands, both without failing anywhere. These tests are the tripwire: if one
/// fails, update `fit.ts` (and `user-profile.ts`'s `BodyMeasurements`) to match
/// before touching anything else.
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

  test(
    "fit.ts's CIRCUMFERENCES ladders still match EaseTable "
    '(update supabase/functions/_shared/tryon/fit.ts if this fails)',
    () {
      // Verbatim from fit.ts. Each ladder flattens the ProductFit axis: slim's
      // min, regular's max, loose's max. Elasticity is `none` because fit.ts
      // derives from the base bands, before any stretch shift.
      const ladders = <BodyMeasurementType,
          ({double slimMin, double regularMax, double looseMax})>{
        BodyMeasurementType.chest: (
          slimMin: 4,
          regularMax: 15,
          looseMax: 24,
        ),
        BodyMeasurementType.waist: (slimMin: 0, regularMax: 4, looseMax: 8),
        BodyMeasurementType.hips: (slimMin: 2, regularMax: 9, looseMax: 14),
        BodyMeasurementType.thigh: (slimMin: 1, regularMax: 7, looseMax: 12),
      };

      for (final MapEntry(key: type, value: ladder) in ladders.entries) {
        EaseBand band(final ProductFit fit) =>
            EaseTable.bandFor(type, fit, ProductElasticity.none)!;

        expect(
          band(ProductFit.slim).min,
          ladder.slimMin,
          reason: '${type.name} slimMin',
        );
        expect(
          band(ProductFit.regular).max,
          ladder.regularMax,
          reason: '${type.name} regularMax',
        );
        expect(
          band(ProductFit.loose).max,
          ladder.looseMax,
          reason: '${type.name} looseMax',
        );
      }
    },
  );
}
