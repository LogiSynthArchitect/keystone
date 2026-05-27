import 'dart:io';

import '../entities/job_entity.dart';
import '../entities/job_part_entity.dart';
import '../entities/job_photo_entity.dart';
import '../entities/job_audit_entry_entity.dart';
import '../entities/job_service_entity.dart';
import '../entities/job_hardware_entity.dart';
import '../entities/job_expense_entity.dart';

abstract class JobRepository {
  Future<List<JobEntity>> getJobs({int limit = 200, int offset = 0, bool includeArchived = false});
  Future<JobEntity?> getJobById(String id);
  Future<JobEntity> createJob(JobEntity job);
  Future<JobEntity> updateJob(JobEntity job);
  Future<void> archiveJob(String id);
  Future<List<JobEntity>> getPendingSyncJobs();
  Future<void> syncPendingJobs();

  // V2 Methods
  Future<List<JobPartEntity>> getPartsForJob(String jobId);
  Future<void> saveParts(String jobId, List<JobPartEntity> parts);
  Future<List<JobPhotoEntity>> getPhotosForJob(String jobId);
  Future<void> savePhotos(String jobId, List<(File, String, String)> photos); // file, label, mediaType
  Future<void> deletePhoto(String photoId);
  Future<List<JobAuditEntryEntity>> getAuditLogForJob(String jobId);

  Future<JobEntity> editJob(String jobId, Map<String, dynamic> changes, String editedBy);
  Future<JobEntity> updateJobStatus(String jobId, String newStatus, String editedBy);
  Future<JobEntity> updatePaymentStatus(String jobId, String newStatus, String? method, String editedBy);

  // Services (multiple per job)
  Future<List<JobServiceEntity>> getServicesForJob(String jobId);
  Future<void> saveServices(String jobId, List<JobServiceEntity> services);

  // Hardware items (multiple per job)
  Future<List<JobHardwareEntity>> getHardwareForJob(String jobId);
  Future<void> saveHardwareItems(String jobId, List<JobHardwareEntity> items);

  // Expenses (transport, parking, subcontractor, etc.)
  Future<List<JobExpenseEntity>> getExpensesForJob(String jobId);
  Future<void> saveExpenses(String jobId, List<JobExpenseEntity> expenses);
}
