import 'package:collection/collection.dart';

const _ordered = DeepCollectionEquality();

/// Returns only the [target] entries whose value differs from [original].
///
/// Keys absent from the result are left untouched by a Supabase `update`, so a
/// column the user never edited can't clobber a newer server-side value.
///
/// Clearing a field to null relies on the model keeping json_serializable's
/// default `includeIfNull: true`; a model that opts out would drop the key and
/// the clear would be lost.
Map<String, dynamic> jsonDiff(
  final Map<String, dynamic> original,
  final Map<String, dynamic> target,
) {
  final changes = <String, dynamic>{};

  for (final entry in target.entries) {
    if (!_ordered.equals(original[entry.key], entry.value)) {
      changes[entry.key] = entry.value;
    }
  }

  return changes;
}
