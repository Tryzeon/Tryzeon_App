enum StoreChannel {
  physical('physical', '實體店面'),
  online('online', '線上店家');

  const StoreChannel(this.code, this.label);

  final String code;
  final String label;

  static const Set<StoreChannel> all = {physical, online};

  static StoreChannel? fromCode(final String code) {
    for (final c in values) {
      if (c.code == code) return c;
    }
    return null;
  }

  static Set<StoreChannel> setFromCodes(final List<String> codes) =>
      codes.map(StoreChannel.fromCode).whereType<StoreChannel>().toSet();

  static List<String> codesFromSet(final Set<StoreChannel> channels) {
    return values.where(channels.contains).map((final c) => c.code).toList();
  }
}
