import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:keystone/features/customer_history/domain/usecases/get_customers_usecase.dart';
import 'package:keystone/features/customer_history/domain/entities/customer_entity.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late GetCustomersUsecase usecase;
  late MockCustomerRepository mockRepository;

  setUp(() {
    mockRepository = MockCustomerRepository();
    usecase = GetCustomersUsecase(mockRepository);
  });

  group('GetCustomersUsecase', () {
    test('returns list of customers from repository', () async {
      // TODO
    });

    test('returns empty list when no customers exist', () async {
      // TODO
    });
  });
}
