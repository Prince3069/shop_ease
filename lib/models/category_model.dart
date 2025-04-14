class CategoryModel {
  final String id;
  final String name;
  final String image;
  final String? description;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.image,
    this.description,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : this.order = order ?? 0,
        this.createdAt = createdAt ?? DateTime.now(),
        this.updatedAt = updatedAt ?? DateTime.now();

  factory CategoryModel.fromMap(Map<String, dynamic> data, String id) {
    return CategoryModel(
      id: id,
      name: data['name'] ?? '',
      image: data['image'] ?? '',
      description: data['description'],
      order: data['order'] ?? 0,
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'image': image,
      'description': description,
      'order': order,
      'createdAt': createdAt,
      'updatedAt': DateTime.now(),
    };
  }
}
