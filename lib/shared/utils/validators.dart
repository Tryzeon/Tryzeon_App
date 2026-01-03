class AppValidators {
  static String? validatePrice(final String? value) {
    if (value == null || value.trim().isEmpty) {
      return '請輸入價格';
    }
    final number = double.tryParse(value);
    if (number == null) {
      return '請輸入有效數字';
    }
    if (number < 0) {
      return '價格不能小於 0';
    }
    if (number > 999999999) {
      return '價格不能大於 999,999,999';
    }
    return null;
  }

  static String? validateMeasurement(final String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    final number = double.tryParse(value);
    if (number == null) {
      return '請輸入有效數字';
    }
    if (number <= 0) {
      return '數值必須大於 0';
    }
    if (number > 300) {
      return '數值不能大於 300';
    }
    return null;
  }

  static String? validateUrl(final String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional
    }
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return '請輸入有效的網址 (例如 https://example.com)';
    }
    return null;
  }

  static String? validateSizeName(final String? value) {
    if (value == null || value.trim().isEmpty) {
      return '請輸入尺寸名稱';
    }
    return null;
  }

  static String? validateProductName(final String? value) {
    if (value == null || value.trim().isEmpty) {
      return '請輸入商品名稱';
    }
    return null;
  }

  static String? validateStoreName(final String? value) {
    if (value == null || value.trim().isEmpty) {
      return '請輸入店家名稱';
    }
    return null;
  }

  static String? validateUserName(final String? value) {
    if (value == null || value.trim().isEmpty) {
      return '請輸入姓名';
    }
    return null;
  }
}
