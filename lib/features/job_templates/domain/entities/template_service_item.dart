import '../../../../core/utils/forward_compatible.dart';

class TemplateServiceItem {
  static const _kKnown = {'id', 'service_type', 'quantity', 'unit_price', 'sort_order'};

  final String id;
  final String serviceType;
  final int quantity;
  final int? unitPrice; // in pesewas, snapshot at save time
  final int sortOrder;
  final Map<String, dynamic> preserved;

  const TemplateServiceItem({
    required this.id,
    required this.serviceType,
    this.quantity = 1,
    this.unitPrice,
    this.sortOrder = 0,
    this.preserved = const {},
  });

  Map<String, dynamic> toJson() {
    final fields = <String, dynamic>{
      'id': id,
      'service_type': serviceType,
      'quantity': quantity,
      'unit_price': unitPrice,
      'sort_order': sortOrder,
    };
    return ForwardCompatible.buildJson(preserved, fields);
  }

  factory TemplateServiceItem.fromJson(Map<String, dynamic> json) =>
      TemplateServiceItem(
        id: json['id'] as String? ?? '',
        serviceType: json['service_type'] as String? ?? '',
        quantity: json['quantity'] as int? ?? 1,
        unitPrice: json['unit_price'] as int?,
        sortOrder: json['sort_order'] as int? ?? 0,
        preserved: ForwardCompatible.extractPreserved(json, _kKnown),
      );

  TemplateServiceItem copyWith({
    String? id,
    String? serviceType,
    int? quantity,
    int? unitPrice,
    int? sortOrder,
    Map<String, dynamic>? preserved,
  }) =>
      TemplateServiceItem(
        id: id ?? this.id,
        serviceType: serviceType ?? this.serviceType,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice ?? this.unitPrice,
        sortOrder: sortOrder ?? this.sortOrder,
        preserved: preserved ?? this.preserved,
      );
}
