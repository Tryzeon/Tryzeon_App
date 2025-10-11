class Product {
  final String? id;
  final String storeId;
  final String name;
  final String type;
  final double price;
  final String imagePath;
  final String purchaseLink;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    this.id,
    required this.storeId,
    required this.name,
    required this.type,
    required this.price,
    required this.imagePath,
    required this.purchaseLink,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'store_id': storeId,
      'name': name,
      'type': type,
      'price': price,
      'image_path': imagePath,
      'purchase_link': purchaseLink,
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'updated_at': updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      storeId: json['store_id'],
      name: json['name'],
      type: json['type'],
      price: (json['price'] as num).toDouble(),
      imagePath: json['image_path'],
      purchaseLink: json['purchase_link'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}