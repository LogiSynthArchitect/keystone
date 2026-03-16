import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:keystone/features/customer_history/domain/usecases/create_customer_usecase.dart';
import 'package:keystone/features/customer_history/domain/entities/customer_entity.dart';
import '../../../../helpers/mocks.dart';

class FakeCustomer extends Fake implements CustomerEntity {}

void main() {
  late CreateCustomerUsecase usecase;
  late MockCustomerRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeCustomer());
  });

  setUp(() {
    mockRepository = MockCustomerRepository();
    usecase = CreateCustomerUsecase(mockRepository);
  });

  group('CreateCustomerUsecase', () {
    test('creates new customer when phone does not exist', () async {
      // TODO
    });

    test('returns existing customer when phone already exists', () async {
      // TODO
    });

    test('does not create duplicate customer for same phone number', () async {
      // TODO
    });
  });
}
