import '../entities/job_entity.dart';
import '../entities/job_part_entity.dart';
import '../entities/job_photo_entity.dart';
import '../entities/job_audit_entry_entity.dart';

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
  Future<List<JobPhotoEntity>> getPhotosForJob(String jobId);
  Future<List<JobAuditEntryEntity>> getAuditLogForJob(String jobId);
  
  Future<JobEntity> editJob(String jobId, Map<String, dynamic> changes, String editedBy);
  Future<JobEntity> updateJobStatus(String jobId, String newStatus, String editedBy);
  Future<JobEntity> updatePaymentStatus(String jobId, String newStatus, String? method, String editedBy);
}
