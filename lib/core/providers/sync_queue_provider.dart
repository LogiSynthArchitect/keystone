import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sync/sync_queue_service.dart';

final syncQueueServiceProvider = Provider<SyncQueueService>((ref) {
  return SyncQueueService();
});
