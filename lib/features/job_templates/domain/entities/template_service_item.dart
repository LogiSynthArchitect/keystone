class TemplateServiceItem {
  final String id;
  final String serviceType;
  final int quantity;
  final int? unitPrice; // in pesewas, snapshot at save time
  final int sortOrder;

  const TemplateServiceItem({
    required this.id,
    required this.serviceType,
    this.quantity = 1,
    this.unitPrice,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'service_type': serviceType,
    'quantity': quantity,
    'unit_price': unitPrice,
    'sort_order': sortOrder,
  };

  factory TemplateServiceItem.fromJson(Map<String, dynamic> json) =>
      TemplateServiceItem(
        id: json['id'] as String? ?? '',
        serviceType: json['service_type'] as String? ?? '',
        quantity: json['quantity'] as int? ?? 1,
        unitPrice: json['unit_price'] as int?,
        sortOrder: json['sort_order'] as int? ?? 0,
      );

  TemplateServiceItem copyWith({
    String? id,
    String? serviceType,
    int? quantity,
    int? unitPrice,
    int? sortOrder,
  }) =>
      TemplateServiceItem(
        id: id ?? this.id,
        serviceType: serviceType ?? this.serviceType,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice ?? this.unitPrice,
        sortOrder: sortOrder ?? this.sortOrder,
      );
}
