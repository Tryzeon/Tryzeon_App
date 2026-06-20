enum AgeRange {
  under12('under_12'),
  age13to17('13_17'),
  age18to24('18_24'),
  age25to34('25_34'),
  age35to54('35_54'),
  age55plus('55_plus');

  const AgeRange(this.value);
  final String value;

  String get label => switch (this) {
    AgeRange.under12 => '12 歲以下',
    AgeRange.age13to17 => '13–17 歲',
    AgeRange.age18to24 => '18–24 歲',
    AgeRange.age25to34 => '25–34 歲',
    AgeRange.age35to54 => '35–54 歲',
    AgeRange.age55plus => '55 歲以上',
  };

  static AgeRange? tryFromString(final String? value) =>
      AgeRange.values.where((final e) => e.value == value).firstOrNull;
}
