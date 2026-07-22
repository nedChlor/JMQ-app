class Category {
  final int id;
  final String nameRu;
  final String nameEn;
  final String? icon;
  final int? parentId;
  final int sortOrder;

  Category({
    required this.id,
    required this.nameRu,
    required this.nameEn,
    this.icon,
    this.parentId,
    this.sortOrder = 0,
  });

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: map['id'] as int,
        nameRu: map['name_ru'] as String,
        nameEn: map['name_en'] as String,
        icon: map['icon'] as String?,
        parentId: map['parent_id'] as int?,
        sortOrder: (map['sort_order'] as int?) ?? 0,
      );

  bool get isRoot => parentId == null;
}
