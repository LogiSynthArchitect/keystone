import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:keystone/features/technician_profile/domain/usecases/update_profile_usecase.dart';
import 'package:keystone/features/technician_profile/domain/entities/profile_entity.dart';
import 'package:keystone/core/errors/validation_exception.dart';
import 'package:keystone/core/constants/app_enums.dart';
import '../../../../helpers/mocks.dart';

class FakeProfile extends Fake implements ProfileEntity {}

void main() {
  late UpdateProfileUsecase usecase;
  late MockProfileRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeProfile());
  });

  setUp(() {
    mockRepository = MockProfileRepository();
    usecase = UpdateProfileUsecase(mockRepository);
  });

  group('UpdateProfileUsecase', () {
    test('updates profile with valid data', () async {
      // TODO
    });

    test('throws ValidationException when display name is too short', () async {
      // TODO
    });

    test('throws ValidationException when services list is empty', () async {
      // TODO
    });
  });
}
