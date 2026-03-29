import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/errors/network_exception.dart';
import '../models/service_type_model.dart';

class ServiceTypeRemoteDatasource {
  final SupabaseClient _supabase;
  ServiceTypeRemoteDatasource(this._supabase);

  Future<List<ServiceTypeModel>> getServiceTypes() async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.serviceTypesTable)
          .select()
          .order('display_order', ascending: true);
      return (data as List).map((json) => ServiceTypeModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not fetch service types.', code: 'FETCH_FAILED', cause: e);
    }
  }

  Future<ServiceTypeModel> createServiceType(Map<String, dynamic> json) async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.serviceTypesTable)
          .insert(json)
          .select()
          .single();
      return ServiceTypeModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not create service type.', code: 'CREATE_FAILED', cause: e);
    }
  }
}
