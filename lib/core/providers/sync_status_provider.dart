import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared_feature_providers.dart';

final syncStatusProvider = Provider<int>((ref) {
  final jobState = ref.watch(jobListProvider);
  return jobState.pendingCount;
});
