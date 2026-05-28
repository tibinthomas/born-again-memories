import '../data/memory_sparks.dart';

class CustomSpark {
  final String id;
  final String title;
  final String description;
  final SparkCategory category;

  const CustomSpark({
    required this.id,
    required this.title,
    required this.description,
    this.category = SparkCategory.play,
  });

  CustomSpark copyWith({
    String? title,
    String? description,
    SparkCategory? category,
  }) =>
      CustomSpark(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        category: category ?? this.category,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category.name,
      };

  factory CustomSpark.fromJson(Map<String, dynamic> j) => CustomSpark(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String? ?? '',
        category: SparkCategory.values.firstWhere(
          (c) => c.name == (j['category'] as String? ?? 'play'),
          orElse: () => SparkCategory.play,
        ),
      );
}
