import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/storage/hive_service.dart';
import '../models/job_expense_model.dart';

class JobExpensesLocalDatasource {
  Future<List<JobExpenseModel>> getExpensesForJob(String jobId) async {
    return HiveService.jobExpenses.values
        .map((json) => JobExpenseModel.fromJson(Map<String, dynamic>.from(json)))
        .where((e) => e.jobId == jobId)
        .toList();
  }

  Future<void> saveExpense(JobExpenseModel model) async {
    await HiveService.jobExpenses.put(model.id, model.toJson());
    await HiveService.jobExpenses.flush();
  }

  Future<void> saveAll(List<JobExpenseModel> models) async {
    final map = {for (var m in models) m.id: m.toJson() as Map};
    await HiveService.jobExpenses.putAll(map);
    await HiveService.jobExpenses.flush();
  }

  Future<void> deleteExpense(String id) async {
    await HiveService.jobExpenses.delete(id);
    await HiveService.jobExpenses.flush();
  }

  Future<void> deleteExpensesForJob(String jobId) async {
    final keys = HiveService.jobExpenses.values
        .where((j) => j['job_id'] == jobId)
        .map((j) => j['id'] as String)
        .toList();
    await HiveService.jobExpenses.deleteAll(keys);
    await HiveService.jobExpenses.flush();
  }
}
