import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:keystone/features/whatsapp_followup/domain/usecases/send_followup_usecase.dart';
import 'package:keystone/features/whatsapp_followup/domain/entities/follow_up_entity.dart';
import '../../../../helpers/mocks.dart';

class FakeFollowUp extends Fake implements FollowUpEntity {}
class FakeLaunchOptions extends Fake implements LaunchOptions {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SendFollowupUsecase usecase;
  late MockFollowUpRepository mockRepository;
  late MockUrlLauncher mockUrlLauncher;

  setUpAll(() {
    registerFallbackValue(FakeFollowUp());
    registerFallbackValue(FakeLaunchOptions());
    mockUrlLauncher = MockUrlLauncher();
    UrlLauncherPlatform.instance = mockUrlLauncher;
  });

  setUp(() {
    mockRepository = MockFollowUpRepository();
    usecase = SendFollowupUsecase(mockRepository);

    // Default mock behavior for url_launcher
    when(() => mockUrlLauncher.canLaunch(any()))
        .thenAnswer((_) async => true);
    when(() => mockUrlLauncher.launchUrl(any(), any()))
        .thenAnswer((_) async => true);
  });

  const validParams = SendFollowupParams(
    userId: 'user-123',
    jobId: '550e8400-e29b-41d4-a716-446655440000',
    customerId: 'customer-123',
    customerPhone: '+233244123456',
    messageText: 'Hello Kwame, thank you for choosing our service today.',
  );

  final fakeFollowUp = FollowUpEntity(
    id: 'followup-123',
    jobId: '550e8400-e29b-41d4-a716-446655440000',
    userId: 'user-123',
    customerId: 'customer-123',
    messageText: 'Hello Kwame, thank you for choosing our service today.',
    sentAt: DateTime.now(),
    deliveryConfirmed: false,
    createdAt: DateTime.now(),
  );

  group('SendFollowupUsecase', () {
    test('returns existing follow up if already sent for this job', () async {
      when(() => mockRepository.getFollowUpByJobId(any()))
          .thenAnswer((_) async => fakeFollowUp);

      final result = await usecase(validParams);

      expect(result.jobId, equals('550e8400-e29b-41d4-a716-446655440000'));
      verifyNever(() => mockRepository.createFollowUp(any()));
    });

    test('delivery confirmed is always false in V1', () async {
      when(() => mockRepository.getFollowUpByJobId(any()))
          .thenAnswer((_) async => fakeFollowUp);

      final result = await usecase(validParams);

      expect(result.deliveryConfirmed, isFalse);
    });

    test('does not create follow up when one already exists', () async {
      when(() => mockRepository.getFollowUpByJobId(any()))
          .thenAnswer((_) async => fakeFollowUp);

      await usecase(validParams);

      verifyNever(() => mockRepository.createFollowUp(any()));
    });

    test('skips database write when jobId is not a valid UUID', () async {
      when(() => mockRepository.getFollowUpByJobId(any()))
          .thenAnswer((_) async => null);

      const localOnlyParams = SendFollowupParams(
        userId: 'user-123',
        jobId: 'local-temp-id-not-uuid',
        customerId: 'customer-123',
        customerPhone: '+233244123456',
        messageText: 'Hello Kwame, thank you for choosing our service today.',
      );

      final result = await usecase(localOnlyParams);

      expect(result.jobId, equals('local-temp-id-not-uuid'));
      verifyNever(() => mockRepository.createFollowUp(any()));
    });
  });
}
