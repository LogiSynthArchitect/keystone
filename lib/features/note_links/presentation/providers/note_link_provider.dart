import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keystone/core/providers/supabase_provider.dart';
import 'package:keystone/core/providers/connectivity_provider.dart';
import 'package:keystone/features/knowledge_base/domain/entities/note_job_link_entity.dart';
import '../../data/datasources/note_link_local_datasource.dart';
import '../../data/datasources/note_link_remote_datasource.dart';
import '../../data/repositories/note_link_repository_impl.dart';
import '../../domain/repositories/note_link_repository.dart';
import '../../domain/usecases/get_links_for_note_usecase.dart';
import '../../domain/usecases/get_links_for_job_usecase.dart';
import '../../domain/usecases/create_note_link_usecase.dart';
import '../../domain/usecases/delete_note_link_usecase.dart';

final noteLinkLocalDatasourceProvider = Provider<NoteLinkLocalDatasource>(
  (ref) => NoteLinkLocalDatasource());

final noteLinkRemoteDatasourceProvider = Provider<NoteLinkRemoteDatasource>(
  (ref) => NoteLinkRemoteDatasource(ref.watch(supabaseClientProvider)));

final noteLinkRepositoryProvider = Provider<NoteLinkRepository>((ref) =>
  NoteLinkRepositoryImpl(
    ref.watch(noteLinkLocalDatasourceProvider),
    ref.watch(noteLinkRemoteDatasourceProvider),
    ref.watch(connectivityServiceProvider),
  ));

final getLinksForNoteUsecaseProvider = Provider<GetLinksForNoteUsecase>(
  (ref) => GetLinksForNoteUsecase(ref.watch(noteLinkRepositoryProvider)));

final getLinksForJobUsecaseProvider = Provider<GetLinksForJobUsecase>(
  (ref) => GetLinksForJobUsecase(ref.watch(noteLinkRepositoryProvider)));

final createNoteLinkUsecaseProvider = Provider<CreateNoteLinkUsecase>(
  (ref) => CreateNoteLinkUsecase(ref.watch(noteLinkRepositoryProvider)));

final deleteNoteLinkUsecaseProvider = Provider<DeleteNoteLinkUsecase>(
  (ref) => DeleteNoteLinkUsecase(ref.watch(noteLinkRepositoryProvider)));

class NoteLinkNotifier extends StateNotifier<AsyncValue<List<NoteJobLinkEntity>>> {
  final Ref _ref;
  NoteLinkNotifier(this._ref) : super(const AsyncValue.loading());

  void reset() => state = const AsyncValue.loading();

  Future<void> loadForNote(String noteId) async {
    state = const AsyncValue.loading();
    try {
      final links = await _ref.read(getLinksForNoteUsecaseProvider).call(noteId);
      state = AsyncValue.data(links);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadForJob(String jobId) async {
    state = const AsyncValue.loading();
    try {
      final links = await _ref.read(getLinksForJobUsecaseProvider).call(jobId);
      state = AsyncValue.data(links);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<NoteJobLinkEntity?> createLink(String noteId, String jobId) async {
    final supabase = _ref.read(supabaseClientProvider);
    final userId = supabase.auth.currentUser?.id ?? '';
    try {
      final link = await _ref.read(createNoteLinkUsecaseProvider).call(
        CreateNoteLinkParams(noteId: noteId, jobId: jobId, userId: userId),
      );
      final current = state.value ?? [];
      state = AsyncValue.data([link, ...current]);
      return link;
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteLink(String id) async {
    try {
      await _ref.read(deleteNoteLinkUsecaseProvider).call(id);
      final current = state.value ?? [];
      state = AsyncValue.data(current.where((l) => l.id != id).toList());
    } catch (_) {}
  }
}

final noteLinkByNoteProvider = StateNotifierProvider.autoDispose
    .family<NoteLinkNotifier, AsyncValue<List<NoteJobLinkEntity>>, String>(
  (ref, noteId) {
    final notifier = NoteLinkNotifier(ref);
    notifier.loadForNote(noteId);
    return notifier;
  },
);

final noteLinkByJobProvider = StateNotifierProvider.autoDispose
    .family<NoteLinkNotifier, AsyncValue<List<NoteJobLinkEntity>>, String>(
  (ref, jobId) {
    final notifier = NoteLinkNotifier(ref);
    notifier.loadForJob(jobId);
    return notifier;
  },
);
