class GiftItem {
  final String id;
  final String name;
  final String category;
  final List<String> tags;
  final List<String> occasions;
  final List<String> relationships;
  final int minBudget;
  final int maxBudget;
  final String style; // "Practical" or "Surprise"
  final String description;

  const GiftItem({
    required this.id,
    required this.name,
    required this.category,
    required this.tags,
    required this.occasions,
    required this.relationships,
    required this.minBudget,
    required this.maxBudget,
    required this.style,
    required this.description,
  });

  factory GiftItem.fromJson(Map<String, dynamic> json) {
    return GiftItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      tags: List<String>.from(json['tags'] as List),
      occasions: List<String>.from(json['occasions'] as List),
      relationships: List<String>.from(json['relationships'] as List),
      minBudget: (json['minBudget'] as num).toInt(),
      maxBudget: (json['maxBudget'] as num).toInt(),
      style: json['style'] as String,
      description: json['description'] as String,
    );
  }
}
