/// Category entity for product classification.
class Category {
  /// Creates a category instance.
  const Category({
    required this.id,
    required this.name,
    this.iconUrl,
    this.parentId,
    required this.level,
    required this.sortOrder,
    required this.isActive,
  });

  /// Category unique identifier (UUID).
  final String id;

  /// Category name (Vietnamese).
  final String name;

  /// Category icon URL.
  final String? iconUrl;

  /// Parent category ID (null for root categories).
  final String? parentId;

  /// Hierarchy level (0 = root, 1 = subcategory, max 2 levels).
  final int level;

  /// Display order (lower numbers appear first).
  final int sortOrder;

  /// Active status (inactive categories hidden from UI).
  final bool isActive;

  /// Create Category from JSON.
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      iconUrl: json['iconUrl'] as String?,
      parentId: json['parentId'] as String?,
      level: json['level'] as int,
      sortOrder: json['sortOrder'] as int,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Convert Category to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'iconUrl': iconUrl,
      'parentId': parentId,
      'level': level,
      'sortOrder': sortOrder,
      'isActive': isActive,
    };
  }

  /// Create a copy with updated fields.
  Category copyWith({
    String? id,
    String? name,
    String? iconUrl,
    String? parentId,
    int? level,
    int? sortOrder,
    bool? isActive,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      iconUrl: iconUrl ?? this.iconUrl,
      parentId: parentId ?? this.parentId,
      level: level ?? this.level,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Check if this is a root category.
  bool get isRoot => level == 0 && parentId == null;

  /// Check if this is a subcategory.
  bool get isSubcategory => level == 1 && parentId != null;

  @override
  String toString() {
    return 'Category(id: $id, name: $name, level: $level)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
