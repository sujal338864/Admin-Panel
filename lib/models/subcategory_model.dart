class SubCategory {
  final int id;
  final String name;
  final int categoryId;
  final String categoryName;
  final DateTime createdAt;

  SubCategory({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.createdAt,
  });

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      id: json['subcategory_id'],
      name: json['name'],
      categoryId: json['category_id'],
      categoryName: json['category_name'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
