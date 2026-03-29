class KeyCodeEntryEntity {
  final String id;
  final String customerId;
  final String? jobId;
  final String keyCode;
  final String? keyType; // 'SC1', 'KW1', 'M1', etc.
  final String? bitting;
  final String? description;
  final DateTime createdAt;

  const KeyCodeEntryEntity({
    required this.id,
    required this.customerId,
    this.jobId,
    required this.keyCode,
    this.keyType,
    this.bitting,
    this.description,
    required this.createdAt,
  });
}
