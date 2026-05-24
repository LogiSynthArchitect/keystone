class TemplatePartItem {
  final String id;
  final String name;
  final int quantity;
  final int? unitPrice; // in pesewas, snapshot at save time
  final String? inventoryItemId; // optional link back to inventory

  const TemplatePartItem({
    required this.id,
    required this.name,
    this.quantity = 1,
    this.unitPrice,
    this.inventoryItemId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'quantity': quantity,
    'unit_price': unitPrice,
    'inventory_item_id': inventoryItemId,
  };

  factory TemplatePartItem.fromJson(Map<String, dynamic> json) =>
      TemplatePartItem(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        quantity: json['quantity'] as int? ?? 1,
        unitPrice: json['unit_price'] as int?,
        inventoryItemId: json['inventory_item_id'] as String?,
      );

  TemplatePartItem copyWith({
    String? id,
    String? name,
    int? quantity,
    int? unitPrice,
    String? inventoryItemId,
  }) =>
      TemplatePartItem(
        id: id ?? this.id,
        name: name ?? this.name,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice ?? this.unitPrice,
        inventoryItemId: inventoryItemId ?? this.inventoryItemId,
      );
}
