import '../entities/follow_up_entity.dart';

abstract class FollowUpRepository {
  Future<FollowUpEntity> createFollowUp(FollowUpEntity followUp);
  Future<FollowUpEntity?> getFollowUpByJobId(String jobId);
  Future<List<FollowUpEntity>> getFollowUps({int limit = 25, int offset = 0});
}
