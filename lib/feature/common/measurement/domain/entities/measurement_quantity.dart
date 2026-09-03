/// Distinct from `MeasurementUnit`, which is the length-unit system
/// (cm/cun/inch) a store owner types garment sizes in.
enum MeasurementQuantity {
  length('cm'),
  mass('kg');

  const MeasurementQuantity(this.unitSuffix);

  final String unitSuffix;
}
