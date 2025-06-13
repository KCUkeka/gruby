class GroceryItem {
  final String? id;
  final String name;
  final String category;
  final bool isPurchased;
  final DateTime createdAt;
  final String? barcode;

  GroceryItem({
    this.id,
    required this.name,
    required this.category,
    this.isPurchased = false,
    required this.createdAt,
    this.barcode,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'category': category,
        'is_purchased': isPurchased,
        'created_at': createdAt.toIso8601String(),
        'barcode': barcode,
      };

  factory GroceryItem.fromMap(Map<String, dynamic> m) => GroceryItem(
        id: m['id'],
        name: m['name'],
        category: m['category'],
        isPurchased: m['is_purchased'] as bool,
        createdAt: DateTime.parse(m['created_at']),
        barcode: m['barcode'],
      );

  GroceryItem copyWith({
    String? id,
    String? name,
    String? category,
    bool? isPurchased,
    DateTime? createdAt,
    String? barcode,
  }) =>
      GroceryItem(
        id: id ?? this.id,
        name: name ?? this.name,
        category: category ?? this.category,
        isPurchased: isPurchased ?? this.isPurchased,
        createdAt: createdAt ?? this.createdAt,
        barcode: barcode ?? this.barcode,
      );
}
