import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../../../core/usecases/use_case.dart';
import '../../data/datasources/service_type_local_datasource.dart';
import '../../data/datasources/service_type_remote_datasource.dart';
import '../../data/repositories/service_type_repository_impl.dart';
import '../../domain/entities/service_type_entity.dart';
import '../../domain/repositories/service_type_repository.dart';
import '../../domain/usecases/get_service_types_usecase.dart';
import '../../domain/usecases/create_service_type_usecase.dart';
import '../../domain/usecases/update_service_type_usecase.dart';
import '../../domain/usecases/delete_service_type_usecase.dart';

final serviceTypeLocalDatasourceProvider = Provider<ServiceTypeLocalDatasource>((ref) => ServiceTypeLocalDatasource());
final serviceTypeRemoteDatasourceProvider = Provider<ServiceTypeRemoteDatasource>((ref) => ServiceTypeRemoteDatasource(ref.watch(supabaseClientProvider)));

final serviceTypeRepositoryProvider = Provider<ServiceTypeRepository>((ref) => ServiceTypeRepositoryImpl(
  ref.watch(serviceTypeRemoteDatasourceProvider),
  ref.watch(serviceTypeLocalDatasourceProvider),
  ref.watch(connectivityServiceProvider),
));

final getServiceTypesUsecaseProvider = Provider<GetServiceTypesUsecase>((ref) => GetServiceTypesUsecase(ref.watch(serviceTypeRepositoryProvider)));
final createServiceTypeUsecaseProvider = Provider<CreateServiceTypeUsecase>((ref) => CreateServiceTypeUsecase(ref.watch(serviceTypeRepositoryProvider)));
final updateServiceTypeUsecaseProvider = Provider<UpdateServiceTypeUsecase>((ref) => UpdateServiceTypeUsecase(ref.watch(serviceTypeRepositoryProvider)));
final deleteServiceTypeUsecaseProvider = Provider<DeleteServiceTypeUsecase>((ref) => DeleteServiceTypeUsecase(ref.watch(serviceTypeRepositoryProvider)));

class ServiceTypeNotifier extends StateNotifier<AsyncValue<List<ServiceTypeEntity>>> {
  final Ref _ref;
  ServiceTypeNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadServiceTypes();
  }

  Future<void> loadServiceTypes() async {
    state = const AsyncValue.loading();
    try {
      final types = await _ref.read(getServiceTypesUsecaseProvider).call(const NoParams());

      if (types.isEmpty) {
        final userId = _ref.read(supabaseClientProvider).auth.currentUser?.id;
        if (userId != null) {
          // Server-authoritative seed — RPC atomically checks flag, inserts,
          // and marks seeded. No client-side seed logic needed.
          final seeded = await _ref.read(supabaseClientProvider)
              .rpc('seed_default_service_types', params: {'p_user_id': userId});

          // Pull remote types (newly seeded or already existed)
          final repo = _ref.read(serviceTypeRepositoryProvider);
          await repo.syncServiceTypes();
          final syncedTypes = await repo.getServiceTypes();
          state = AsyncValue.data(syncedTypes);
          return;
        }
      }

      state = AsyncValue.data(types);
    } catch (e, st) {
      // Network error: show error state with retry — never fall through to seeding
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createServiceType(String name) async {
    final userId = _ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _ref.read(createServiceTypeUsecaseProvider).call(CreateServiceTypeParams(userId: userId, name: name));
      await loadServiceTypes();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateServiceType(ServiceTypeEntity serviceType) async {
    try {
      await _ref.read(updateServiceTypeUsecaseProvider).call(UpdateServiceTypeParams(serviceType));
      await loadServiceTypes();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Save price locally. Returns true if local save succeeded.
  /// Uses scoped PATCH payload — only transmits default_price, never name/category/icon.
  Future<bool> savePriceOnly(String id, int? defaultPrice) async {
    final current = state.valueOrNull;
    if (current == null) return false;
    final index = current.indexWhere((t) => t.id == id);
    if (index == -1) return false;
    final updated = current[index].copyWith(
      defaultPrice: defaultPrice,
      correctionFields: ['default_price'],
      updatedBy: 'mobile',
    );

    try {
      await _ref.read(updateServiceTypeUsecaseProvider).call(UpdateServiceTypeParams(updated));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Apply a price update to the in-memory state AFTER user-facing
  /// animation (success moment) has completed.
  void applyPriceUpdate(String id, int? defaultPrice) {
    final current = state.valueOrNull;
    if (current == null) return;
    final index = current.indexWhere((t) => t.id == id);
    if (index == -1) return;
    final updated = current[index].copyWith(defaultPrice: defaultPrice);
    final updatedList = [...current];
    updatedList[index] = updated;
    state = AsyncValue.data(updatedList);
  }

  /// Convenience — saves AND applies in one call (for callers that
  /// don't need animation sequencing).
  Future<void> updateServiceTypePrice(String id, int? defaultPrice) async {
    await savePriceOnly(id, defaultPrice);
    applyPriceUpdate(id, defaultPrice);
  }

  Future<void> deleteServiceType(String id) async {
    try {
      await _ref.read(deleteServiceTypeUsecaseProvider).call(id);
      await loadServiceTypes();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() {
    loadServiceTypes();
  }
}

final serviceTypeProvider = StateNotifierProvider<ServiceTypeNotifier, AsyncValue<List<ServiceTypeEntity>>>((ref) {
  return ServiceTypeNotifier(ref);
});
