import '../../domain/entities/service_type_entity.dart';
import '../../../../core/utils/forward_compatible.dart';

class ServiceTypeModel {
  static const _kKnown = {
    'id', 'user_id', 'name', 'is_default', 'category', 'icon_name',
    'default_price', 'created_at', 'updated_at', 'correction_fields',
    'updated_by', 'is_deleted',
  };

  final String id;
  final String userId;
  final String name;
  final bool isDefault;
  final String category;
  final String iconName;
  final int? defaultPrice;
  final String createdAt;
  final String updatedAt;
  final List<String> correctionFields;
  final String updatedBy;
  final bool isDeleted;
  final Map<String, dynamic> preserved;

  ServiceTypeModel({
    required this.id,
    required this.userId,
    required this.name,
    this.isDefault = false,
    this.category = 'General',
    this.iconName = 'tools',
    this.defaultPrice,
    required this.createdAt,
    required this.updatedAt,
    this.correctionFields = const [],
    this.updatedBy = 'mobile',
    this.isDeleted = false,
    this.preserved = const {},
  });

  factory ServiceTypeModel.fromJson(Map<String, dynamic> json) => ServiceTypeModel(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    name: json['name'] as String,
    isDefault: json['is_default'] as bool? ?? false,
    category: json['category'] as String? ?? 'General',
    iconName: json['icon_name'] as String? ?? 'tools',
    defaultPrice: json['default_price'] as int?,
    createdAt: json['created_at'] as String,
    updatedAt: json['updated_at'] as String,
    correctionFields: json['correction_fields'] != null
        ? List<String>.from(json['correction_fields'] as List)
        : [],
    updatedBy: json['updated_by'] as String? ?? 'mobile',
    isDeleted: json['is_deleted'] as bool? ?? false,
    preserved: ForwardCompatible.extractPreserved(json, _kKnown),
  );

  Map<String, dynamic> toJson() => ForwardCompatible.buildJson(preserved, {
    'id': id,
    'user_id': userId,
    'name': name,
    'is_default': isDefault,
    'category': category,
    'icon_name': iconName,
    'default_price': defaultPrice,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'updated_by': updatedBy,
    if (isDeleted) 'is_deleted': true,
  });

  /// Build a PATCH payload — only transmits fields listed in [correctionFields].
  Map<String, dynamic> toPatchJson() {
    final patch = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
      'correction_fields': correctionFields,
    'updated_by': updatedBy,
    if (isDeleted) 'is_deleted': true,
    };
    if (correctionFields.contains('name')) patch['name'] = name;
    if (correctionFields.contains('default_price')) patch['default_price'] = defaultPrice;
    if (correctionFields.contains('category')) patch['category'] = category;
    if (correctionFields.contains('icon_name')) patch['icon_name'] = iconName;
    if (correctionFields.contains('is_default')) patch['is_default'] = isDefault;
    return patch;
  }

  ServiceTypeEntity toEntity() => ServiceTypeEntity(
    id: id,
    userId: userId,
    name: name,
    isDefault: isDefault,
    category: category,
    iconName: iconName,
    defaultPrice: defaultPrice,
    createdAt: DateTime.parse(createdAt),
    updatedAt: DateTime.parse(updatedAt),
    correctionFields: correctionFields,
    updatedBy: updatedBy,
    isDeleted: isDeleted,
  );

  factory ServiceTypeModel.fromEntity(ServiceTypeEntity entity) => ServiceTypeModel(
    id: entity.id,
    userId: entity.userId,
    name: entity.name,
    isDefault: entity.isDefault,
    category: entity.category,
    iconName: entity.iconName,
    defaultPrice: entity.defaultPrice,
    createdAt: entity.createdAt.toIso8601String(),
    updatedAt: entity.updatedAt.toIso8601String(),
    correctionFields: entity.correctionFields,
    updatedBy: entity.updatedBy,
    isDeleted: entity.isDeleted,
  );

  ServiceTypeModel copyWith({
    String? id,
    String? userId,
    String? name,
    bool? isDefault,
    String? category,
    String? iconName,
    int? defaultPrice,
    String? createdAt,
    String? updatedAt,
    List<String>? correctionFields,
    String? updatedBy,
    bool? isDeleted,
    Map<String, dynamic>? preserved,
  }) {
    return ServiceTypeModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
      category: category ?? this.category,
      iconName: iconName ?? this.iconName,
      defaultPrice: defaultPrice ?? this.defaultPrice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      correctionFields: correctionFields ?? this.correctionFields,
      updatedBy: updatedBy ?? this.updatedBy,
      isDeleted: isDeleted ?? this.isDeleted,
      preserved: preserved ?? this.preserved,
    );
  }
}
