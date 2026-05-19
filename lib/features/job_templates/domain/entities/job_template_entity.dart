class JobTemplateEntity {
  final String id;
  final String userId;
  final String name;
  final String serviceType;
  final String? notes;
  final List<Map<String, dynamic>> services;
  final List<Map<String, dynamic>> hardwareItems;
  final List<Map<String, dynamic>> parts;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JobTemplateEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.serviceType,
    this.notes,
    this.services = const [],
    this.hardwareItems = const [],
    this.parts = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  JobTemplateEntity copyWith({
    String? id,
    String? userId,
    String? name,
    String? serviceType,
    String? notes,
    List<Map<String, dynamic>>? services,
    List<Map<String, dynamic>>? hardwareItems,
    List<Map<String, dynamic>>? parts,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JobTemplateEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      serviceType: serviceType ?? this.serviceType,
      notes: notes ?? this.notes,
      services: services ?? this.services,
      hardwareItems: hardwareItems ?? this.hardwareItems,
      parts: parts ?? this.parts,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
