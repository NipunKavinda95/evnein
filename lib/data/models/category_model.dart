class CategoryModel {
  final String id;
  final String name;
  final String emoji;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.emoji,
    this.sortOrder = 0,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'sortOrder': sortOrder,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CategoryModel.fromMap(Map<String, dynamic> map) => CategoryModel(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        emoji: map['emoji'] ?? '📦',
        sortOrder: map['sortOrder'] ?? 0,
        isActive: map['isActive'] ?? true,
        createdAt: DateTime.parse(
          map['createdAt'] ?? DateTime.now().toIso8601String(),
        ),
      );
}
