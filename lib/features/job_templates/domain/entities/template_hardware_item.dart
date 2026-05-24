class TemplateHardwareItem {
  final String id;
  final String name;
  final int quantity;
  final int? unitSalePrice; // in pesewas, snapshot at save time
  final String? inventoryItemId; // optional link back to inventory

  const TemplateHardwareItem({
    required this.id,
    required this.name,
    this.quantity = 1,
    this.unitSalePrice,
    this.inventoryItemId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'quantity': quantity,
    'unit_sale_price': unitSalePrice,
    'inventory_item_id': inventoryItemId,
  };

  factory TemplateHardwareItem.fromJson(Map<String, dynamic> json) =>
      TemplateHardwareItem(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        quantity: json['quantity'] as int? ?? 1,
        unitSalePrice: json['unit_sale_price'] as int?,
        inventoryItemId: json['inventory_item_id'] as String?,
      );

  TemplateHardwareItem copyWith({
    String? id,
    String? name,
    int? quantity,
    int? unitSalePrice,
    String? inventoryItemId,
  }) =>
      TemplateHardwareItem(
        id: id ?? this.id,
        name: name ?? this.name,
        quantity: quantity ?? this.quantity,
        unitSalePrice: unitSalePrice ?? this.unitSalePrice,
        inventoryItemId: inventoryItemId ?? this.inventoryItemId,
      );
}
