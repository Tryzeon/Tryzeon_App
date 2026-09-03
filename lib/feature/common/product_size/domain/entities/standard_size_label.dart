/// Standard sizes a store can tick straight from the size table. Declaration
/// order is the on-screen row order.
enum StandardSizeLabel {
  xs('XS'),
  s('S'),
  m('M'),
  l('L'),
  xl('XL'),
  xxl('2XL'),
  free('均碼');

  const StandardSizeLabel(this.display);

  final String display;

  /// Matches the literal only, with no alias folding: `XXL` is a custom size
  /// and never becomes `2XL`. Whatever the store types is what it gets, and
  /// `2XL` is already one tap away on screen. Alias folding for voice input
  /// happens in the `parse-size-voice` edge function, so labels reaching the
  /// client are already normalized.
  static StandardSizeLabel? tryParse(final String raw) {
    final key = matchKeyOf(raw);
    for (final label in values) {
      if (label.display == key) return label;
    }
    return null;
  }

  static String matchKeyOf(final String raw) => raw.trim().toUpperCase();
}

/// Standard sizes follow [StandardSizeLabel] declaration order; custom sizes
/// sort after the other standard sizes and before `均碼`. All custom sizes share
/// one rank, and the strict greater-than puts a new one after the existing
/// custom rows (preserving insertion order) — `>=` would reverse it.
int sizeRowInsertIndex(final List<String> existingLabels, final String label) {
  final rank = _rank(label);
  for (var i = 0; i < existingLabels.length; i++) {
    if (_rank(existingLabels[i]) > rank) return i;
  }
  return existingLabels.length;
}

int _rank(final String label) {
  final standard = StandardSizeLabel.tryParse(label);
  if (standard == StandardSizeLabel.free) return 1000;
  if (standard != null) return standard.index;
  return 500;
}
