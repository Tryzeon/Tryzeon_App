/// The physical quantity a measurement expresses, with its canonical unit.
///
/// A body dimension is a [length] stored in centimeters; weight is a [mass]
/// stored in kilograms. This is distinct from `MeasurementUnit`
/// (`common/measurements`), which is the length-unit *system* (cm/cun/inch) a
/// store owner types garment sizes in.
enum MeasurementQuantity {
  length('cm'),
  mass('kg');

  const MeasurementQuantity(this.unitSuffix);

  /// The suffix shown next to an input field for this quantity (e.g. `cm`).
  final String unitSuffix;
}
