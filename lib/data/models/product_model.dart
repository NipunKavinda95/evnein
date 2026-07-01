class ProductModel {
  final String id;
  final String name;
  final String category; // 'juice' or 'cake'
  final double price;
  final int stockQuantity;
  final bool isAvailable;
  final String? imageUrl;
  final DateTime createdAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.stockQuantity,
    this.isAvailable = true,
    this.imageUrl,
    required this.createdAt,
  });

  // Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'stockQuantity': stockQuantity,
      'isAvailable': isAvailable,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from Firestore map
  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? 'juice',
      price: (map['price'] ?? 0).toDouble(),
      stockQuantity: map['stockQuantity'] ?? 0,
      isAvailable: map['isAvailable'] ?? true,
      imageUrl: map['imageUrl'],
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  // Copy with modifications
  ProductModel copyWith({
    String? name,
    String? category,
    double? price,
    int? stockQuantity,
    bool? isAvailable,
    String? imageUrl,
  }) {
    return ProductModel(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isAvailable: isAvailable ?? this.isAvailable,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt,
    );
  }
}
