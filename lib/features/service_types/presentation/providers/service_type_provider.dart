import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../../../core/providers/auth_provider.dart';
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

  /// Default services used when server-side RPC is unavailable.
  static const _defaultServices = [
    ('Car Key Replacement',        'Automotive',      'car',        25000),
    ('Transponder Key Programming','Automotive',      'car',        25000),
    ('Car Lockout',                'Automotive',      'unlock',      6500),
    ('Trunk/Boot Unlock',          'Automotive',      'unlock',      5000),
    ('Key Fob Programming',        'Automotive',      'wifi',       20000),
    ('Ignition Repair',            'Automotive',      'key',        15000),
    ('Broken Key Extraction',      'Automotive',      'tools',      12000),
    ('Motorcycle Keys',            'Automotive',      'motorcycle', 15000),
    ('House Lockout',              'Residential',     'door-open',   6500),
    ('Lock Installation',          'Residential',     'lock',       15000),
    ('Lock Rekeying',              'Residential',     'key',         8000),
    ('Lock Repair',                'Residential',     'wrench',      8000),
    ('Key Duplication',            'Residential',     'key',         1500),
    ('Smart Lock Install',         'Residential',     'mobile-alt', 25000),
    ('Garage Door Locks',          'Residential',     'lock',       12000),
    ('Padlock Sales/Installation', 'Residential',     'lock',        8000),
    ('Mailbox Locks',              'Residential',     'envelope',    6000),
    ('Window Locks',               'Residential',     'lock',        6000),
    ('Commercial Lockout',         'Commercial',      'building',    8000),
    ('Master Key Systems',         'Commercial',      'network-wired', 50000),
    ('Panic Bar Installation',     'Commercial',      'door-closed',25000),
    ('Door Closer Install',        'Commercial',      'tools',      15000),
    ('Electric Strike Installation','Commercial',     'bolt',       18000),
    ('High-Security Locks',        'Commercial',      'shield-alt', 35000),
    ('File Cabinet Locks',         'Commercial',      'archive',     8000),
    ('Storefront Locks',           'Commercial',      'store',      12000),
    ('CCTV Installation',          'Security Systems','video',      25000),
    ('Video Doorbell Installation', 'Security Systems','video',      15000),
    ('Access Control',              'Security Systems','id-card',    30000),
    ('Burglar Alarms',              'Security Systems','bell',       20000),
    ('Intercom Systems',            'Security Systems','phone',      25000),
    ('Electric Gate Motor Repair',  'Security Systems','tools',      20000),
    ('Electric Fence Installation', 'Security Systems','bolt',       35000),
    ('Rolling Shutter Repair',      'Security Systems','wrench',     15000),
    ('Key Cutting',                 'Specialty',       'cut',         1000),
    ('Safe Opening',                'Specialty',       'unlock',     35000),
    ('Safe Installation',           'Specialty',       'lock',       25000),
    ('Gate Automation',             'Specialty',       'tools',      45000),
    ('Eviction Services',           'Specialty',       'gavel',      30000),
  ];

  Future<void> loadServiceTypes() async {
    debugPrint('[KS:PRICING] loadServiceTypes — start');
    state = const AsyncValue.loading();
    try {
      final types = await _ref.read(getServiceTypesUsecaseProvider).call(const NoParams());
      debugPrint('[KS:PRICING] getServiceTypes returned ${types.length} types');

      if (types.isEmpty) {
        final supabase = _ref.read(supabaseClientProvider);
        final authId = supabase.auth.currentUser?.id;
        debugPrint('[KS:PRICING] auth.currentUser?.id = $authId');
        if (authId != null) {
          // Try server-side RPC first
          bool seeded = false;
          try {
            seeded = await supabase
                .rpc('seed_default_service_types', params: {'p_user_id': authId});
            debugPrint('[KS:PRICING] RPC seed result: $seeded');
          } catch (e) {
            debugPrint('[KS:PRICING] RPC failed: $e');
          }

          if (!seeded) {
            // Client-side fallback: get internal users.id, batch insert defaults
            debugPrint('[KS:PRICING] falling back to client-side seed');
            final currentUserAsync = _ref.read(currentUserProvider);
            debugPrint('[KS:PRICING] currentUserProvider state: $currentUserAsync');
            final authUser = currentUserAsync.valueOrNull;
            debugPrint('[KS:PRICING] currentUser: ${authUser?.id} / authId: ${authUser?.authId}');
            final userId = authUser?.id;
            if (userId != null) {
              final now = DateTime.now().toIso8601String();
              final rows = _defaultServices.map((d) => {
                    'user_id': userId,
                    'name': d.$1,
                    'is_default': true,
                    'category': d.$2,
                    'icon_name': d.$3,
                    'default_price': d.$4,
                    'created_at': now,
                    'updated_at': now,
                  }).toList();
              debugPrint('[KS:PRICING] inserting ${rows.length} default services for userId=$userId');
              try {
                await supabase.from('service_types').insert(rows);
                debugPrint('[KS:PRICING] batch insert succeeded');
              } catch (insertErr) {
                debugPrint('[KS:PRICING] batch insert FAILED: $insertErr');
                rethrow;
              }
            } else {
              debugPrint('[KS:PRICING] userId is null — cannot seed client-side');
            }
          }

          // Pull seeded types
          debugPrint('[KS:PRICING] pulling seeded types via sync+get');
          final repo = _ref.read(serviceTypeRepositoryProvider);
          await repo.syncServiceTypes();
          final syncedTypes = await repo.getServiceTypes();
          debugPrint('[KS:PRICING] syncedTypes count: ${syncedTypes.length}');
          state = AsyncValue.data(syncedTypes);
          return;
        } else {
          debugPrint('[KS:PRICING] authId is null — skipping seed entirely');
        }
      }

      debugPrint('[KS:PRICING] setting state with ${types.length} types');
      state = AsyncValue.data(types);
    } catch (e, st) {
      debugPrint('[KS:PRICING] CATASTROPHIC ERROR — $e\n$st');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createServiceType(String name, String category, String iconName) async {
    final authUser = _ref.read(currentUserProvider).valueOrNull;
    final userId = authUser?.id;
    if (userId == null) return;

    try {
      await _ref.read(createServiceTypeUsecaseProvider).call(CreateServiceTypeParams(
        userId: userId,
        name: name,
        category: category,
        iconName: iconName,
      ));
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
