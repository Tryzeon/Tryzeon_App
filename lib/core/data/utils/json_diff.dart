import 'package:collection/collection.dart';

const _ordered = DeepCollectionEquality();
const _unordered = DeepCollectionEquality.unordered();

/// Returns only the [target] entries whose value differs from [original].
///
/// Keys absent from the result are left untouched by a Supabase `update`, so a
/// column the user never edited can't clobber a newer server-side value. An
/// empty result means the write can be skipped entirely.
///
/// Both maps are expected to come from the same model's `toJson()` — only
/// [target]'s keys are walked, so a key only [original] has is ignored.
///
/// A field cleared to null is reported as an explicit null, which relies on the
/// model keeping json_serializable's default `includeIfNull: true`. A model
/// that opts out would drop the key instead and the clear would be lost.
///
/// [unorderedKeys] names columns whose list order carries no meaning (they back
/// a `Set` in the domain layer); without it a re-ordered set reads as a change.
Map<String, dynamic> jsonDiff(
  final Map<String, dynamic> original,
  final Map<String, dynamic> target, {
  final Set<String> unorderedKeys = const {},
}) {
  final changes = <String, dynamic>{};

  for (final entry in target.entries) {
    final equality = unorderedKeys.contains(entry.key) ? _unordered : _ordered;
    if (!equality.equals(original[entry.key], entry.value)) {
      changes[entry.key] = entry.value;
    }
  }

  return changes;
}
