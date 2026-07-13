enum ClothingStyle {
  // 🌍 地區 / 國家風格
  japanese('japanese'),
  korean('korean'),
  western('western'),
  british('british'),
  chinese('chinese'),

  // 👕 日常 / 休閒風格
  minimalist('minimalist'),
  casual('casual'),
  sporty('sporty'),
  lazy('lazy'),
  streetwear('streetwear'),

  // 💼 專業 / 場景風格
  business('business'),
  preppy('preppy'),
  functional('functional'),

  // 🕰️ 氣質 / 經典風格
  vintage('vintage'),
  artsy('artsy'),
  literary('literary'),
  elegant('elegant'),

  // ✨ 個人特質 / 氛圍風格
  mature('mature'),
  neutral('neutral'),
  spicy('spicy'),
  sweet('sweet');

  const ClothingStyle(this.value);
  final String value;

  String get label => switch (this) {
    // 🌍 地區 / 國家風格
    ClothingStyle.japanese => '日系風',
    ClothingStyle.korean => '韓系風',
    ClothingStyle.western => '歐美風',
    ClothingStyle.british => '英式風',
    ClothingStyle.chinese => '中式感',

    // 👕 日常 / 休閒風格
    ClothingStyle.minimalist => '簡約風',
    ClothingStyle.casual => '休閒風',
    ClothingStyle.sporty => '運動風',
    ClothingStyle.lazy => '慵懶風',
    ClothingStyle.streetwear => '街頭風',

    // 💼 專業 / 場景風格
    ClothingStyle.business => '商務風',
    ClothingStyle.preppy => '學院風',
    ClothingStyle.functional => '機能風',

    // 🕰️ 氣質 / 經典風格
    ClothingStyle.vintage => '復古風',
    ClothingStyle.artsy => '文青風',
    ClothingStyle.literary => '文藝風',
    ClothingStyle.elegant => '優雅風',

    // ✨ 個人特質 / 氛圍風格
    ClothingStyle.mature => '輕熟風',
    ClothingStyle.neutral => '中性風',
    ClothingStyle.spicy => '辣妹風',
    ClothingStyle.sweet => '甜美風',
  };

  static ClothingStyle? tryFromString(final String? value) =>
      ClothingStyle.values.where((final e) => e.value == value).firstOrNull;

  static List<ClothingStyle>? listFromStrings(final Iterable<String>? values) =>
      values?.map(tryFromString).whereType<ClothingStyle>().toList();
}
