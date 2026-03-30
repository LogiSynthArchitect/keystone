import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keystone/features/job_logging/domain/entities/job_entity.dart';
import 'package:keystone/features/customer_history/domain/entities/customer_entity.dart';
import 'package:keystone/features/knowledge_base/domain/entities/knowledge_note_entity.dart';
import 'package:keystone/features/job_logging/presentation/providers/job_providers.dart';
import 'package:keystone/features/customer_history/presentation/providers/customer_providers.dart';
import 'package:keystone/features/knowledge_base/presentation/providers/notes_providers.dart';

class SearchResults {
  final List<JobEntity> jobs;
  final List<CustomerEntity> customers;
  final List<KnowledgeNoteEntity> notes;
  final bool isSearching;
  final String query;

  const SearchResults({
    this.jobs = const [],
    this.customers = const [],
    this.notes = const [],
    this.isSearching = false,
    this.query = '',
  });

  bool get isEmpty => jobs.isEmpty && customers.isEmpty && notes.isEmpty;
  int get totalCount => jobs.length + customers.length + notes.length;
}

class SearchNotifier extends StateNotifier<SearchResults> {
  final Ref _ref;
  Timer? _debounce;

  SearchNotifier(this._ref) : super(const SearchResults());

  void search(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      state = const SearchResults();
      return;
    }

    state = state.isSearching
        ? state
        : SearchResults(query: trimmed, isSearching: true);

    _debounce = Timer(const Duration(milliseconds: 350), () {
      _runSearch(trimmed);
    });
  }

  void _runSearch(String query) {
    final q = query.toLowerCase();

    // Jobs — search non-archived, non-deleted
    final allJobs = _ref.read(jobListProvider).allJobs;
    final jobs = allJobs.where((j) =>
      !j.isArchived && !j.isDeleted &&
      (
        j.serviceType.toLowerCase().contains(q) ||
        (j.notes?.toLowerCase().contains(q) ?? false) ||
        (j.location?.toLowerCase().contains(q) ?? false)
      )
    ).take(10).toList();

    // Customers
    final allCustomers = _ref.read(customerListProvider).customers;
    final customers = allCustomers.where((c) =>
      c.fullName.toLowerCase().contains(q) ||
      c.phoneNumber.toLowerCase().contains(q) ||
      (c.notes?.toLowerCase().contains(q) ?? false)
    ).take(10).toList();

    // Notes
    final allNotes = _ref.read(notesListProvider).notes;
    final notes = allNotes.where((n) =>
      !n.isArchived &&
      (
        n.title.toLowerCase().contains(q) ||
        n.description.toLowerCase().contains(q) ||
        n.tags.any((t) => t.toLowerCase().contains(q))
      )
    ).take(10).toList();

    state = SearchResults(
      query: query,
      isSearching: false,
      jobs: jobs,
      customers: customers,
      notes: notes,
    );
  }

  void clear() {
    _debounce?.cancel();
    state = const SearchResults();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final searchProvider = StateNotifierProvider.autoDispose<SearchNotifier, SearchResults>(
  (ref) => SearchNotifier(ref));
