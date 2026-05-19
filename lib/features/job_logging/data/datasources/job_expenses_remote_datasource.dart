import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/errors/network_exception.dart';
import '../models/job_expense_model.dart';

class JobExpensesRemoteDatasource {
  final SupabaseClient _supabase;
  JobExpensesRemoteDatasource(this._supabase);

  Future<List<JobExpenseModel>> getExpensesForJob(String jobId) async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.jobExpensesTable)
          .select()
          .eq('job_id', jobId);
      return (data as List).map((j) => JobExpenseModel.fromJson(j)).toList();
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not fetch job expenses.', code: 'FETCH_FAILED', cause: e);
    }
  }

  Future<JobExpenseModel> createExpense(Map<String, dynamic> json) async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.jobExpensesTable)
          .insert(json)
          .select()
          .single();
      return JobExpenseModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not create expense.', code: 'CREATE_FAILED', cause: e);
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _supabase.from(SupabaseConstants.jobExpensesTable).delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not delete expense.', code: 'DELETE_FAILED', cause: e);
    }
  }

  Future<List<JobExpenseModel>> upsertAll(List<Map<String, dynamic>> jsonList) async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.jobExpensesTable)
          .upsert(jsonList)
          .select();
      return (data as List).map((j) => JobExpenseModel.fromJson(j)).toList();
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not sync expenses.', code: 'UPSERT_FAILED', cause: e);
    }
  }
}
