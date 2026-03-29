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
import '../../domain/usecases/seed_default_service_types_usecase.dart';

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
final seedDefaultServiceTypesUsecaseProvider = Provider<SeedDefaultServiceTypesUseCase>((ref) => SeedDefaultServiceTypesUseCase(ref.watch(serviceTypeRepositoryProvider)));

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
          await _ref.read(seedDefaultServiceTypesUsecaseProvider).call(userId);
          final seededTypes = await _ref.read(getServiceTypesUsecaseProvider).call(const NoParams());
          state = AsyncValue.data(seededTypes);
          return;
        }
      }
      
      state = AsyncValue.data(types);
    } catch (e, st) {
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
