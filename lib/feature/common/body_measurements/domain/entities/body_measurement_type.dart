/// The dimensions of a *person* the shopper can record.
///
/// These are body dimensions — chest/waist/hips are circumferences measured on
/// the body, not the flat measurements printed on a garment's size chart. The
/// garment side has its own vocabulary in `GarmentMeasurementType`; the two are
/// deliberately separate types and are only related through the fit domain.
enum BodyMeasurementType {
  height('height'),
  shoulder('shoulder'),
  chest('chest'),
  sleeve('sleeve'),
  waist('waist'),
  hips('hips');

  const BodyMeasurementType(this.value);

  final String value;
}
