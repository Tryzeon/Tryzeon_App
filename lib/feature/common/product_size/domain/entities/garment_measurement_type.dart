/// The dimensions of a *garment* a store owner can publish on a size chart.
///
/// [chestCircumference], [waistCircumference] and [hipCircumference] are the
/// garment's own circumference at that point — the way a size chart is normally
/// printed and the way a store owner measures — not the flat width across the
/// laid-out garment, and not the wearer's body circumference. [shoulderWidth]
/// and [sleeveLength] stay linear because a garment has no circumference there.
///
/// The vocabulary is deliberately separate from `BodyMeasurementType` even
/// where the names now line up: the two sets evolve independently (a garment
/// has a hem length, a body does not; a body has a height, a garment does not),
/// and a garment circumference is not interchangeable with the body
/// circumference it must accommodate — the gap between them is ease. Bridging
/// them is fit-domain knowledge, not a property of either type.
///
/// [length] is the garment's own top-to-bottom length, whatever the garment is
/// — a top's body length, a pair of trousers' inseam-to-hem length, a skirt's
/// hem length. One dimension covers all three because the garment category
/// already says which one is meant, and `WardrobeCategory` itself does not
/// separate trousers from skirts. It is displayed to shoppers but carries no
/// fit signal on its own, so it has no body counterpart. See
/// `GarmentFitDimension` in the shop feature.
///
/// [thighCircumference] is the garment's own thigh circumference, mirroring
/// the other circumferences.
enum GarmentMeasurementType {
  shoulderWidth('shoulder_width', minCm: 20, maxCm: 70),
  chestCircumference('chest_circumference', minCm: 40, maxCm: 200),
  sleeveLength('sleeve_length', minCm: 20, maxCm: 100),
  waistCircumference('waist_circumference', minCm: 30, maxCm: 200),
  hipCircumference('hip_circumference', minCm: 40, maxCm: 200),
  thighCircumference('thigh_circumference', minCm: 25, maxCm: 120),
  length('length', minCm: 20, maxCm: 160);

  const GarmentMeasurementType(this.value, {required this.minCm, required this.maxCm});

  final String value;
  final double minCm;
  final double maxCm;
}
