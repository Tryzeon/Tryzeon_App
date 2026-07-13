/// Destination a short link resolves to.
class LinkTarget {
  const LinkTarget({required this.targetType, required this.targetId});

  /// 'product' or 'store'.
  final String targetType;
  final String targetId;
}
