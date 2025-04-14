class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? discountPrice;
  final List<String> images;
  final String categoryId;
  final Map<String, dynamic> attributes;
  final int stockQuantity;
  final double rating;
  final int reviewCount;
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.discountPrice,
    required this.images,
    required this.categoryId,
    required this.attributes,
    required this.stockQuantity,
    required this.rating,
    required this.reviewCount,
    required this.isFeatured,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductModel.fromMap(Map<String, dynamic> data, String id) {
    return ProductModel(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      discountPrice: data['discountPrice']?.toDouble(),
      images: List<String>.from(data['images'] ?? []),
      categoryId: data['categoryId'] ?? '',
      attributes: Map<String, dynamic>.from(data['attributes'] ?? {}),
      stockQuantity: data['stockQuantity'] ?? 0,
      rating: (data['rating'] ?? 0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      isFeatured: data['isFeatured'] ?? false,
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'discountPrice': discountPrice,
      'images': images,
      'categoryId': categoryId,
      'attributes': attributes,
      'stockQuantity': stockQuantity,
      'rating': rating,
      'reviewCount': reviewCount,
      'isFeatured': isFeatured,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  bool get isOnSale => discountPrice != null && discountPrice! < price;

  double get salePrice => discountPrice ?? price;

  double get discountPercentage =>
      isOnSale ? ((price - salePrice) / price * 100) : 0;
}
