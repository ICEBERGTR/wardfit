class ClothingItem {
  final int id;
  final String name;
  final String category; // Shirts, Pants, Outwear, Shoes
  final String color;
  final String tags;
  final String imageKey;
  final bool isFavorite;

  const ClothingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.color,
    required this.tags,
    required this.imageKey,
    this.isFavorite = false,
  });

  ClothingItem copyWith({
    int? id,
    String? name,
    String? category,
    String? color,
    String? tags,
    String? imageKey,
    bool? isFavorite,
  }) {
    return ClothingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      color: color ?? this.color,
      tags: tags ?? this.tags,
      imageKey: imageKey ?? this.imageKey,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  factory ClothingItem.fromJson(Map<String, dynamic> json) {
    return ClothingItem(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'Outwear',
      color: json['color'] as String? ?? '',
      tags: json['tags'] as String? ?? '',
      imageKey: json['image_key'] as String? ?? 'grey_jacket',
      isFavorite: json['is_favorite'] == true || json['is_favorite'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'color': color,
      'tags': tags,
      'image_key': imageKey,
      'is_favorite': isFavorite,
    };
  }
}
