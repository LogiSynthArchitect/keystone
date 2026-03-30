import 'package:flutter_test/flutter_test.dart';
import 'package:keystone/features/whatsapp_followup/data/models/follow_up_model.dart';
import 'package:keystone/features/whatsapp_followup/domain/entities/follow_up_entity.dart';

void main() {
  final tSentAt = DateTime(2023, 1, 1, 12, 0, 0);
  final tCreatedAt = DateTime(2023, 1, 1, 12, 0, 0);
  final tResponseUpdatedAt = DateTime(2023, 1, 1, 12, 5, 0);

  final tFollowUpEntity = FollowUpEntity(
    id: '1',
    jobId: 'job-1',
    userId: 'user-1',
    customerId: 'cust-1',
    messageText: 'Test message',
    sentAt: tSentAt,
    deliveryConfirmed: true,
    responseStatus: 'sent',
    responseUpdatedAt: null,
    createdAt: tCreatedAt,
  );

  group('Feature 24: Follow-Up Response Tracking Tests', () {

    test('1. FollowUpEntity.copyWith should update responseStatus', () {
      // Arrange
      const newStatus = 'responded';
      
      // Act
      final updatedEntity = tFollowUpEntity.copyWith(responseStatus: newStatus);

      // Assert
      expect(updatedEntity.responseStatus, newStatus);
      expect(updatedEntity.id, tFollowUpEntity.id); // Ensure other fields are unchanged
    });

    test('2. FollowUpEntity.responseStatus should default to "sent"', () {
      // Arrange & Act
      final entity = FollowUpEntity(
        id: '2',
        jobId: 'job-2',
        userId: 'user-2',
        customerId: 'cust-2',
        messageText: 'Another message',
        sentAt: tSentAt,
        deliveryConfirmed: false,
        createdAt: tCreatedAt,
        // responseStatus is omitted to test default
      );

      // Assert
      expect(entity.responseStatus, 'sent');
    });

    test('3. FollowUpModel.fromJson should parse response_status and response_updated_at', () {
      // Arrange
      final jsonMap = {
        'id': '3',
        'job_id': 'job-3',
        'user_id': 'user-3',
        'customer_id': 'cust-3',
        'message_text': 'JSON message',
        'sent_at': tSentAt.toIso8601String(),
        'delivery_confirmed': true,
        'response_status': 'responded',
        'response_updated_at': tResponseUpdatedAt.toIso8601String(),
        'created_at': tCreatedAt.toIso8601String(),
      };

      // Act
      final model = FollowUpModel.fromJson(jsonMap);

      // Assert
      expect(model.responseStatus, 'responded');
      expect(model.responseUpdatedAt, tResponseUpdatedAt.toIso8601String());
    });

    test('4. FollowUpModel.toJson should serialize response_status and response_updated_at', () {
      // Arrange
      final model = FollowUpModel(
        id: '4',
        jobId: 'job-4',
        userId: 'user-4',
        customerId: 'cust-4',
        messageText: 'Model to JSON',
        sentAt: tSentAt.toIso8601String(),
        createdAt: tCreatedAt.toIso8601String(),
        deliveryConfirmed: false,
        responseStatus: 'no_response',
        responseUpdatedAt: tResponseUpdatedAt.toIso8601String(),
      );

      // Act
      final json = model.toJson();

      // Assert
      expect(json['response_status'], 'no_response');
      expect(json['response_updated_at'], tResponseUpdatedAt.toIso8601String());
    });
  });
}
