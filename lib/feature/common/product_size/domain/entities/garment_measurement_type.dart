/// The dimensions of a *garment* a store owner can publish on a size chart.
///
/// [chestCircumference], [waistCircumference], [hipCircumference] and
/// [thighCircumference] are the garment's own circumference at that point —
/// not the flat width across the laid-out garment, and not the wearer's body
/// circumference.
///
/// [length] is the garment's own top-to-bottom length, whatever the garment is
/// — a top's body length, a pair of trousers' inseam-to-hem length, a skirt's
/// hem length.
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
