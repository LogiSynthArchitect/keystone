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

final serviceTypeLocalDatasourceProvider = Provider<ServiceTypeLocalDatasource>((ref) => ServiceTypeLocalDatasource());
final serviceTypeRemoteDatasourceProvider = Provider<ServiceTypeRemoteDatasource>((ref) => ServiceTypeRemoteDatasource(ref.watch(supabaseClientProvider)));

final serviceTypeRepositoryProvider = Provider<ServiceTypeRepository>((ref) => ServiceTypeRepositoryImpl(
  ref.watch(serviceTypeRemoteDatasourceProvider),
  ref.watch(serviceTypeLocalDatasourceProvider),
  ref.watch(connectivityServiceProvider),
));

final getServiceTypesUsecaseProvider = Provider<GetServiceTypesUsecase>((ref) => GetServiceTypesUsecase(ref.watch(serviceTypeRepositoryProvider)));

final serviceTypesProvider = FutureProvider<List<ServiceTypeEntity>>((ref) async {
  return await ref.watch(getServiceTypesUsecaseProvider).call(const NoParams());
});
