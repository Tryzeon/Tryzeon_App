/// The dimensions of a *garment* a store owner can publish on a size chart.
///
/// These are flat measurements taken on the laid-out garment, not body
/// circumferences — `chestWidth` is the width across the chest, roughly half of
/// the corresponding body circumference. The vocabulary is deliberately
/// separate from `BodyMeasurementType`: the two sets evolve independently (a
/// garment has a hem length, a body does not; a body has a height, a garment
/// does not) and translating between them is fit-domain knowledge, not a
/// property of either type.
///
/// [length] is the garment's own top-to-bottom length, whatever the garment is
/// — a top's body length, a pair of trousers' inseam-to-hem length, a skirt's
/// hem length. One dimension covers all three because the garment category
/// already says which one is meant, and `WardrobeCategory` itself does not
/// separate trousers from skirts. It is displayed to shoppers but carries no
/// fit signal on its own, so it has no body counterpart. See
/// `GarmentFitDimension` in the shop feature.
enum GarmentMeasurementType {
  shoulderWidth('shoulder_width'),
  chestWidth('chest_width'),
  sleeveLength('sleeve_length'),
  waistWidth('waist_width'),
  hipWidth('hip_width'),
  length('length');

  const GarmentMeasurementType(this.value);

  final String value;
}
