class GroceryItem {
  final int? id;
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'isPurchased': isPurchased ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'barcode': barcode,
    };
  }

  static GroceryItem fromMap(Map<String, dynamic> map) {
    return GroceryItem(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      isPurchased: map['isPurchased'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      barcode: map['barcode'],
    );
  }

  GroceryItem copyWith({
    int? id,
    String? name,
    String? category,
    bool? isPurchased,
    DateTime? createdAt,
    String? barcode,
  }) {
    return GroceryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      isPurchased: isPurchased ?? this.isPurchased,
      createdAt: createdAt ?? this.createdAt,
      barcode: barcode ?? this.barcode,
    );
  }
}