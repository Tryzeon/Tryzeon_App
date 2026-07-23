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
/// Length dimensions ([garmentLength], [pantsLength], [skirtLength]) are
/// displayed to shoppers but carry no fit signal on their own, so they have no
/// body counterpart. See `GarmentFitDimension` in the shop feature.
enum GarmentMeasurementType {
  shoulderWidth('shoulder_width'),
  chestWidth('chest_width'),
  sleeveLength('sleeve_length'),
  waistWidth('waist_width'),
  hipWidth('hip_width'),
  garmentLength('garment_length'),
  pantsLength('pants_length'),
  skirtLength('skirt_length');

  const GarmentMeasurementType(this.value);

  final String value;
}
