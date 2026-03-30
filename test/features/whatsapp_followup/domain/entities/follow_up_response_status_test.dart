import 'package:flutter_test/flutter_test.dart';
import 'package:keystone/features/whatsapp_followup/data/models/follow_up_model.dart';
import 'package:keystone/features/whatsapp_followup/domain/entities/follow_up_entity.dart';

void main() {
  final now = DateTime.now();
  final followUpEntity = FollowUpEntity(
    id: '1',
    jobId: 'job1',
    userId: 'user1',
    customerId: 'cust1',
    messageText: 'Hello',
    sentAt: now,
    deliveryConfirmed: false,
    createdAt: now,
    responseStatus: 'sent',
    responseUpdatedAt: now,
  );

  test('FollowUpEntity.copyWith should update responseStatus', () {
    final updatedEntity = followUpEntity.copyWith(responseStatus: 'responded');
    expect(updatedEntity.responseStatus, 'responded');
    expect(updatedEntity.jobId, 'job1');
  });

  test('FollowUpEntity.responseStatus should default to "sent"', () {
    final entity = FollowUpEntity(
      id: '2',
      jobId: 'job2',
      userId: 'user2',
      customerId: 'cust2',
      messageText: 'Test',
      sentAt: now,
      deliveryConfirmed: false,
      createdAt: now,
    );
    expect(entity.responseStatus, 'sent');
  });

  group('FollowUpModel', () {
    final now = DateTime.now();
    final isoNow = now.toIso8601String();

    final json = {
      'id': 'model1',
      'job_id': 'job_model1',
      'user_id': 'user_model1',
      'customer_id': 'cust_model1',
      'message_text': 'Model message',
      'sent_at': isoNow,
      'delivery_confirmed': true,
      'created_at': isoNow,
      'response_status': 'no_response',
      'response_updated_at': isoNow,
    };

    test('fromJson parses response_status and response_updated_at correctly', () {
      final model = FollowUpModel.fromJson(json);

      expect(model.id, 'model1');
      expect(model.responseStatus, 'no_response');
      expect(model.responseUpdatedAt, isoNow);
    });

    test('toJson serializes response_status and response_updated_at correctly', () {
      final model = FollowUpModel(
        id: 'model1',
        jobId: 'job_model1',
        userId: 'user_model1',
        customerId: 'cust_model1',
        messageText: 'Model message',
        sentAt: isoNow,
        deliveryConfirmed: true,
        createdAt: isoNow,
        responseStatus: 'no_response',
        responseUpdatedAt: isoNow,
      );

      final serializedJson = model.toJson();

      expect(serializedJson['response_status'], 'no_response');
      expect(serializedJson['response_updated_at'], isoNow);
    });
  });
}
