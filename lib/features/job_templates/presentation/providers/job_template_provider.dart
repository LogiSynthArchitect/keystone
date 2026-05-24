import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../data/datasources/job_template_local_datasource.dart';
import '../../data/datasources/job_template_remote_datasource.dart';
import '../../data/repositories/job_template_repository_impl.dart';
import '../../domain/entities/job_template_entity.dart';
import '../../domain/repositories/job_template_repository.dart';

final jobTemplateLocalDatasourceProvider = Provider<JobTemplateLocalDatasource>((ref) => JobTemplateLocalDatasource());

final jobTemplateRemoteDatasourceProvider = Provider<JobTemplateRemoteDatasource?>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return JobTemplateRemoteDatasource(supabase);
});

final jobTemplateRepositoryProvider = Provider<JobTemplateRepository>((ref) {
  final local = ref.watch(jobTemplateLocalDatasourceProvider);
  final remote = ref.watch(jobTemplateRemoteDatasourceProvider);
  return JobTemplateRepositoryImpl(local, remote);
});

class JobTemplateNotifier extends StateNotifier<AsyncValue<List<JobTemplateEntity>>> {
  final Ref _ref;
  JobTemplateNotifier(this._ref) : super(const AsyncValue.loading());

  Future<void> loadTemplates(String userId) async {
    state = const AsyncValue.loading();
    try {
      final templates = await _ref.read(jobTemplateRepositoryProvider).getTemplates(userId);
      state = AsyncValue.data(templates);
    } catch (e, st) {
      debugPrint('[KS:TEMPLATES] loadTemplates error: $e\n$st');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveTemplate(JobTemplateEntity template) async {
    try {
      await _ref.read(jobTemplateRepositoryProvider).saveTemplate(template);
      final userId = _ref.read(supabaseClientProvider).auth.currentUser?.id;
      if (userId != null) await loadTemplates(userId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteTemplate(String id) async {
    try {
      await _ref.read(jobTemplateRepositoryProvider).deleteTemplate(id);
      final userId = _ref.read(supabaseClientProvider).auth.currentUser?.id;
      if (userId != null) await loadTemplates(userId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> renameTemplate(String id, String newName) async {
    try {
      await _ref.read(jobTemplateRepositoryProvider).renameTemplate(id, newName);
      final userId = _ref.read(supabaseClientProvider).auth.currentUser?.id;
      if (userId != null) await loadTemplates(userId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final jobTemplateProvider = StateNotifierProvider<JobTemplateNotifier, AsyncValue<List<JobTemplateEntity>>>((ref) {
  return JobTemplateNotifier(ref);
});
