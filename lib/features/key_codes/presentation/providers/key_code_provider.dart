import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../../customer_history/domain/entities/key_code_entry_entity.dart';
import '../../data/datasources/key_code_local_datasource.dart';
import '../../data/datasources/key_code_remote_datasource.dart';
import '../../data/repositories/key_code_repository_impl.dart';
import '../../domain/repositories/key_code_repository.dart';
import '../../domain/usecases/get_key_codes_usecase.dart';
import '../../domain/usecases/create_key_code_usecase.dart';
import '../../domain/usecases/update_key_code_usecase.dart';
import '../../domain/usecases/delete_key_code_usecase.dart';

final keyCodeLocalDatasourceProvider = Provider<KeyCodeLocalDatasource>(
  (ref) => KeyCodeLocalDatasource());

final keyCodeRemoteDatasourceProvider = Provider<KeyCodeRemoteDatasource>(
  (ref) => KeyCodeRemoteDatasource(ref.watch(supabaseClientProvider)));

final keyCodeRepositoryProvider = Provider<KeyCodeRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final userId = supabase.auth.currentUser?.id ?? '';
  return KeyCodeRepositoryImpl(
    ref.watch(keyCodeLocalDatasourceProvider),
    ref.watch(keyCodeRemoteDatasourceProvider),
    ref.watch(connectivityServiceProvider),
    userId,
  );
});

final getKeyCodesUsecaseProvider = Provider<GetKeyCodesUsecase>(
  (ref) => GetKeyCodesUsecase(ref.watch(keyCodeRepositoryProvider)));

final createKeyCodeUsecaseProvider = Provider<CreateKeyCodeUsecase>(
  (ref) => CreateKeyCodeUsecase(ref.watch(keyCodeRepositoryProvider)));

final updateKeyCodeUsecaseProvider = Provider<UpdateKeyCodeUsecase>(
  (ref) => UpdateKeyCodeUsecase(ref.watch(keyCodeRepositoryProvider)));

final deleteKeyCodeUsecaseProvider = Provider<DeleteKeyCodeUsecase>(
  (ref) => DeleteKeyCodeUsecase(ref.watch(keyCodeRepositoryProvider)));

class KeyCodeState {
  final List<KeyCodeEntryEntity> entries;
  final bool isLoading;
  final String? errorMessage;

  const KeyCodeState({
    this.entries = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  KeyCodeState copyWith({
    List<KeyCodeEntryEntity>? entries,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) =>
      KeyCodeState(
        entries: entries ?? this.entries,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}

class KeyCodeNotifier extends StateNotifier<KeyCodeState> {
  final Ref _ref;
  KeyCodeNotifier(this._ref) : super(const KeyCodeState());

  void reset() {
    state = const KeyCodeState();
  }

  Future<void> loadForCustomer(String customerId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final entries = await _ref.read(getKeyCodesUsecaseProvider).call(customerId);
      state = state.copyWith(entries: entries, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Could not load key codes.');
    }
  }

  Future<void> create(CreateKeyCodeParams params) async {
    try {
      final entry = await _ref.read(createKeyCodeUsecaseProvider).call(params);
      state = state.copyWith(entries: [entry, ...state.entries]);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Could not save key code.');
    }
  }

  Future<void> update(KeyCodeEntryEntity entry) async {
    try {
      final updated = await _ref.read(updateKeyCodeUsecaseProvider).call(entry);
      state = state.copyWith(
        entries: state.entries.map((e) => e.id == updated.id ? updated : e).toList(),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Could not update key code.');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _ref.read(deleteKeyCodeUsecaseProvider).call(id);
      state = state.copyWith(entries: state.entries.where((e) => e.id != id).toList());
    } catch (e) {
      state = state.copyWith(errorMessage: 'Could not delete key code.');
    }
  }
}

final keyCodeProvider = StateNotifierProvider.autoDispose
    .family<KeyCodeNotifier, KeyCodeState, String>((ref, customerId) {
  final notifier = KeyCodeNotifier(ref);
  notifier.loadForCustomer(customerId);
  return notifier;
});
