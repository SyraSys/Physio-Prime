class CategoryModel {
  final String id;
  final int? numericId;
  final String title;
  final String slug;
  final String description;
  final String? image;
  final String? color;
  final List<String> conditions;
  final int? sortOrder;

  const CategoryModel({
    required this.id,
    this.numericId,
    required this.title,
    required this.slug,
    required this.description,
    this.image,
    this.color,
    this.conditions = const [],
    this.sortOrder,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      numericId: json['numericId'] is int ? json['numericId'] : int.tryParse(json['numericId']?.toString() ?? ''),
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      image: json['image']?.toString(),
      color: json['color']?.toString(),
      conditions: (json['conditions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      sortOrder: json['sortOrder'] is int ? json['sortOrder'] : int.tryParse(json['sortOrder']?.toString() ?? ''),
    );
  }
}
