class ProductType {
  const ProductType({required this.name});

  final String name;

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;

    return other is ProductType && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}
