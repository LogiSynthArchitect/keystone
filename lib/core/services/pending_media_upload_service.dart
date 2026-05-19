import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../storage/hive_service.dart';
import 'cloudinary_service.dart';

class PendingMediaUpload {
  final String id;
  final String filePath;
  final String jobId;
  final String userId;
  final String mediaType;
  final String label;
  final int retryCount;
  final DateTime createdAt;

  const PendingMediaUpload({
    required this.id,
    required this.filePath,
    required this.jobId,
    required this.userId,
    required this.mediaType,
    required this.label,
    this.retryCount = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'filePath': filePath,
    'jobId': jobId,
    'userId': userId,
    'mediaType': mediaType,
    'label': label,
    'retryCount': retryCount,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PendingMediaUpload.fromJson(Map<String, dynamic> json) => PendingMediaUpload(
    id: json['id'] as String,
    filePath: json['filePath'] as String,
    jobId: json['jobId'] as String,
    userId: json['userId'] as String,
    mediaType: json['mediaType'] as String,
    label: json['label'] as String,
    retryCount: json['retryCount'] as int? ?? 0,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  PendingMediaUpload copyWith({int? retryCount}) => PendingMediaUpload(
    id: id,
    filePath: filePath,
    jobId: jobId,
    userId: userId,
    mediaType: mediaType,
    label: label,
    retryCount: retryCount ?? this.retryCount,
    createdAt: createdAt,
  );
}

class PendingMediaUploadService {
  final CloudinaryService _cloudinary;

  static const _boxName = 'pending_media_uploads';
  static const _maxRetries = 3;
  static const _retryDelaySeconds = 60;

  PendingMediaUploadService() : _cloudinary = CloudinaryService();

  Box _box() => Hive.box(_boxName);

  List<PendingMediaUpload> get pending {
    final raw = _box().get('items', defaultValue: <Map<String, dynamic>>[]) as List;
    return raw.map((e) => PendingMediaUpload.fromJson(e as Map<String, dynamic>)).toList();
  }

  set pending(List<PendingMediaUpload> items) {
    _box().put('items', items.map((e) => e.toJson()).toList());
  }

  Future<void> enqueue(PendingMediaUpload upload) async {
    final items = pending;
    items.add(upload);
    this.pending = items;
    debugPrint('[KS:MEDIA] Queued pending upload: ${upload.filePath}');
  }

  Future<void> remove(String id) async {
    final items = pending.where((u) => u.id != id).toList();
    this.pending = items;
  }

  Future<int> retryAll({required String Function() getSupabaseUrl}) async {
    final items = pending;
    if (items.isEmpty) return 0;

    var successCount = 0;
    final remaining = <PendingMediaUpload>[];

    for (final upload in items) {
      if (upload.retryCount >= _maxRetries) {
        debugPrint('[KS:MEDIA] Dropping ${upload.id} after $_maxRetries failed retries');
        continue;
      }

      final file = File(upload.filePath);
      if (!file.existsSync()) {
        debugPrint('[KS:MEDIA] File gone for ${upload.id}, dropping');
        continue;
      }

      try {
        final url = await _cloudinary.uploadMedia(
          file: file,
          publicId: '${upload.userId}_${DateTime.now().millisecondsSinceEpoch}',
        );
        if (url != null) {
          successCount++;
          debugPrint('[KS:MEDIA] Successfully uploaded pending: ${upload.filePath}');
          continue;
        }
      } catch (_) {}

      remaining.add(upload.copyWith(retryCount: upload.retryCount + 1));
    }

    this.pending = remaining;

    if (remaining.isNotEmpty) {
      _scheduleRetry();
    }

    return successCount;
  }

  void _scheduleRetry() {
    Future.delayed(Duration(seconds: _retryDelaySeconds), () {
      retryAll(getSupabaseUrl: () => '');
    });
  }
}
