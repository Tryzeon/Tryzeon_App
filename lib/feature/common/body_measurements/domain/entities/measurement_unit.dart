/// The unit a [BodyMeasurementType] value is entered and displayed in.
enum MeasurementUnit {
  cm('cm'),
  kg('kg');

  const MeasurementUnit(this.suffix);

  /// The suffix shown next to the input field (e.g. `cm`, `kg`).
  final String suffix;
}
