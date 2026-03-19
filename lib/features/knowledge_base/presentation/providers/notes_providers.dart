import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/analytics/ks_analytics.dart';
import '../../../../core/analytics/analytics_constants.dart';
import '../../data/datasources/knowledge_note_local_datasource.dart';
import '../../data/datasources/knowledge_note_remote_datasource.dart';
import '../../data/repositories/knowledge_note_repository_impl.dart';
import '../../domain/entities/knowledge_note_entity.dart';
import '../../domain/repositories/knowledge_note_repository.dart';
import '../../domain/usecases/create_note_usecase.dart';
import '../../domain/usecases/get_notes_usecase.dart';
import '../../domain/usecases/archive_note_usecase.dart';
import '../../domain/usecases/sync_pending_notes_usecase.dart';
import '../../../../core/constants/app_enums.dart';

final knowledgeNoteLocalDatasourceProvider = Provider<KnowledgeNoteLocalDatasource>(
  (ref) => KnowledgeNoteLocalDatasource());

final knowledgeNoteRemoteDatasourceProvider = Provider<KnowledgeNoteRemoteDatasource>(
  (ref) => KnowledgeNoteRemoteDatasource(ref.watch(supabaseClientProvider)));

final knowledgeNoteRepositoryProvider = Provider<KnowledgeNoteRepository>(
  (ref) => KnowledgeNoteRepositoryImpl(
    ref.watch(knowledgeNoteRemoteDatasourceProvider),
    ref.watch(knowledgeNoteLocalDatasourceProvider),
    ref.watch(supabaseClientProvider),
  ));

final getNotesUsecaseProvider = Provider<GetNotesUsecase>(
  (ref) => GetNotesUsecase(ref.watch(knowledgeNoteRepositoryProvider)));

final createNoteUsecaseProvider = Provider<CreateNoteUsecase>(
  (ref) => CreateNoteUsecase(ref.watch(knowledgeNoteRepositoryProvider)));

final archiveNoteUsecaseProvider = Provider<ArchiveNoteUsecase>(
  (ref) => ArchiveNoteUsecase(ref.watch(knowledgeNoteRepositoryProvider)));

final syncPendingNotesUsecaseProvider = Provider<SyncPendingNotesUsecase>(
  (ref) => SyncPendingNotesUsecase(ref.watch(knowledgeNoteRepositoryProvider)));

class NotesListState {
  final List<KnowledgeNoteEntity> notes;
  final List<KnowledgeNoteEntity> searchResults;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final bool showArchived;
  final ServiceType? filterCategory;

  const NotesListState({
    this.notes = const [],
    this.searchResults = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.showArchived = false,
    this.filterCategory,
  });

  List<KnowledgeNoteEntity> get displayed {
    final baseList = searchQuery.isEmpty ? notes : searchResults;
    if (filterCategory == null) return baseList;
    return baseList.where((n) => n.serviceType == filterCategory).toList();
  }

  NotesListState copyWith({
    List<KnowledgeNoteEntity>? notes,
    List<KnowledgeNoteEntity>? searchResults,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    bool? showArchived,
    ServiceType? filterCategory,
    bool clearError = false,
    bool clearFilter = false,
  }) => NotesListState(
    notes: notes ?? this.notes,
    searchResults: searchResults ?? this.searchResults,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    searchQuery: searchQuery ?? this.searchQuery,
    showArchived: showArchived ?? this.showArchived,
    filterCategory: clearFilter ? null : (filterCategory ?? this.filterCategory),
  );
}

class NotesListNotifier extends StateNotifier<NotesListState> {
  final GetNotesUsecase _getNotes;
  final KnowledgeNoteRepository _repository;
  NotesListNotifier(this._getNotes, this._repository) : super(const NotesListState()) { load(); }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final notes = await _getNotes(includeArchived: state.showArchived);
      state = state.copyWith(notes: notes, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Could not load notes.');
    }
  }

  Future<void> toggleArchived() async {
    state = state.copyWith(showArchived: !state.showArchived);
    await load();
  }

  void filterByCategory(ServiceType? category) {
    if (category == null) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(filterCategory: category);
    }
  }

  Future<void> search(String query) async {
    state = state.copyWith(searchQuery: query);
    if (query.trim().isEmpty) {
      state = state.copyWith(searchResults: []);
      return;
    }
    try {
      final results = await _repository.searchNotes(query);
      state = state.copyWith(searchResults: results);
    } catch (e) {
      state = state.copyWith(searchResults: []);
    }
  }
  void addNote(KnowledgeNoteEntity note) {
    state = state.copyWith(notes: [note, ...state.notes]);
  }
  Future<void> archiveNote(String id) async {
    try {
      await _repository.archiveNote(id);
      state = state.copyWith(notes: state.notes.where((n) => n.id != id).toList());
    } catch (e) {
      state = state.copyWith(errorMessage: 'Could not archive note.');
    }
  }
  Future<void> refresh() async {
    await _repository.syncPendingNotes();
    await load();
  }
}

final notesListProvider = StateNotifierProvider<NotesListNotifier, NotesListState>(
  (ref) => NotesListNotifier(
    ref.watch(getNotesUsecaseProvider),
    ref.watch(knowledgeNoteRepositoryProvider),
  ));

class AddNoteState {
  final bool isLoading;
  final String? errorMessage;
  final bool saved;
  const AddNoteState({this.isLoading = false, this.errorMessage, this.saved = false});
  AddNoteState copyWith({bool? isLoading, String? errorMessage, bool? saved, bool clearError = false}) =>
    AddNoteState(isLoading: isLoading ?? this.isLoading, errorMessage: clearError ? null : (errorMessage ?? this.errorMessage), saved: saved ?? this.saved);
}

class AddNoteNotifier extends StateNotifier<AddNoteState> {
  final CreateNoteUsecase _createNote;
  final SupabaseClient _supabase;
  AddNoteNotifier(this._createNote, this._supabase) : super(const AddNoteState());
  void reset() => state = const AddNoteState();
  Future<KnowledgeNoteEntity?> save({
    required String title,
    required String description,
    required List<String> tags,
    ServiceType? serviceType,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final note = await _createNote(CreateNoteParams(
        userId: (() {
          final userId = _supabase.auth.currentUser?.id;
          if (userId == null) throw Exception('Authentication session expired. Please log in again.');
          return userId;
        })(),
        title: title,
        description: description,
        tags: tags,
        serviceType: serviceType,
      ));
      state = state.copyWith(isLoading: false, saved: true);
      KsAnalytics.log(AnalyticsEvents.noteSaved, properties: {
        'has_service_type': serviceType != null,
        'tag_count': tags.length,
      });
      return note;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }
}

final addNoteProvider = StateNotifierProvider<AddNoteNotifier, AddNoteState>(
  (ref) => AddNoteNotifier(ref.watch(createNoteUsecaseProvider), ref.watch(supabaseClientProvider)));
