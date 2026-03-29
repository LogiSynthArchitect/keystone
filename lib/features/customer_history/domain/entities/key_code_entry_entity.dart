class KeyCodeEntryEntity {
  final String id;
  final String customerId;
  final String? jobId;
  final String keyCode;
  final String? keyType; // 'SC1', 'KW1', 'M1', etc.
  final String? bitting;
  final String? description;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const KeyCodeEntryEntity({
    required this.id,
    required this.customerId,
    this.jobId,
    required this.keyCode,
    this.keyType,
    this.bitting,
    this.description,
    required this.createdAt,
    this.updatedAt,
  });

  KeyCodeEntryEntity copyWith({
    String? id,
    String? customerId,
    String? jobId,
    String? keyCode,
    String? keyType,
    String? bitting,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return KeyCodeEntryEntity(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      jobId: jobId ?? this.jobId,
      keyCode: keyCode ?? this.keyCode,
      keyType: keyType ?? this.keyType,
      bitting: bitting ?? this.bitting,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
