class PantryItem {
  final int? id;
  final String name;
  final String category;
  final int quantity;
  final DateTime? expiryDate;
  final DateTime addedAt;
  final String? barcode;

  PantryItem({
    this.id,
    required this.name,
    required this.category,
    this.quantity = 1,
    this.expiryDate,
    required this.addedAt,
    this.barcode,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'quantity': quantity,
      'expiryDate': expiryDate?.millisecondsSinceEpoch,
      'addedAt': addedAt.millisecondsSinceEpoch,
      'barcode': barcode,
    };
  }

  static PantryItem fromMap(Map<String, dynamic> map) {
    return PantryItem(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      quantity: map['quantity'],
      expiryDate: map['expiryDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['expiryDate'])
          : null,
      addedAt: DateTime.fromMillisecondsSinceEpoch(map['addedAt']),
      barcode: map['barcode'],
    );
  }

  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final daysUntilExpiry = expiryDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 3 && daysUntilExpiry >= 0;
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return expiryDate!.isBefore(DateTime.now());
  }

  PantryItem copyWith({
    int? id,
    String? name,
    String? category,
    int? quantity,
    DateTime? expiryDate,
    DateTime? addedAt,
    String? barcode,
  }) {
    return PantryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      expiryDate: expiryDate ?? this.expiryDate,
      addedAt: addedAt ?? this.addedAt,
      barcode: barcode ?? this.barcode,
    );
  }
}