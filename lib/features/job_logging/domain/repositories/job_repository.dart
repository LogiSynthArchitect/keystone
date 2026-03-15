import '../entities/job_entity.dart';

abstract class JobRepository {
  Future<List<JobEntity>> getJobs({int limit = 25, int offset = 0, bool includeArchived = false});
  Future<JobEntity> getJobById(String id);
  Future<JobEntity> createJob(JobEntity job);
  Future<JobEntity> updateJob(JobEntity job);
  Future<void> archiveJob(String id);
  Future<List<JobEntity>> getPendingSyncJobs();
  Future<void> syncPendingJobs();
}
