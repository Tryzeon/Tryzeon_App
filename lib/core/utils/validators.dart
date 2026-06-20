class AppValidators {
  static final _emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+\-/=?^_`{|}~]+@[a-zA-Z0-9]+(\.[a-zA-Z]+)+$",
  );

  static String? validateEmail(final String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return '請輸入電子郵件';
    }
    if (!_emailRegex.hasMatch(trimmed)) {
      return '請輸入有效的電子郵件';
    }
    return null;
  }

  static String? validateOtp(final String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return '請輸入驗證碼';
    }
    if (trimmed.length != 6 || int.tryParse(trimmed) == null) {
      return '請輸入 6 位數驗證碼';
    }
    return null;
  }

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

  static String? validateOffset({
    required final String? offsetValue,
    required final String? measurementValue,
  }) {
    if (offsetValue == null || offsetValue.trim().isEmpty) {
      return null;
    }

    if (measurementValue == null || measurementValue.trim().isEmpty) {
      return '請先輸入測量值';
    }

    final number = double.tryParse(offsetValue);
    if (number == null) {
      return '請輸入有效數字';
    }
    if (number < 0) {
      return '誤差不能小於 0';
    }
    if (number > 50) {
      return '誤差不能大於 50';
    }
    return null;
  }

  static String? validateNonEmpty(final Object? value, {required final String message}) {
    if (value == null) return message;
    if (value is Iterable && value.isEmpty) return message;
    if (value is String && value.trim().isEmpty) return message;
    return null;
  }
}
