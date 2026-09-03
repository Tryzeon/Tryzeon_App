/// 店家在尺寸表上可直接勾選的標準尺碼。宣告順序即畫面上的列順序。
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

  /// 只比對字面值，不做別名轉換：`XXL` 是自訂尺碼，不會被當成 `2XL`。店家想打
  /// 什麼就是什麼，畫面上已經有 `2XL` 可以直接點。語音辨識的別名收斂在
  /// `parse-size-voice` edge function 做，前端拿到的名稱已經是正規化過的。
  static StandardSizeLabel? tryParse(final String raw) {
    final key = matchKeyOf(raw);
    for (final label in values) {
      if (label.display == key) return label;
    }
    return null;
  }

  static String matchKeyOf(final String raw) => raw.trim().toUpperCase();
}

/// 標準尺碼照 [StandardSizeLabel] 宣告順序；自訂尺碼排在其餘標準尺碼之後、
/// 均碼之前。所有自訂尺碼同 rank，靠嚴格大於讓新的落在既有自訂之後（保持新增
/// 順序）—— 改成 `>=` 會把新增順序反轉。
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
