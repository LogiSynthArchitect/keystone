import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:keystone/features/customer_history/domain/entities/customer_entity.dart';
import '../../../../helpers/mocks.dart';

class FakeCustomer extends Fake implements CustomerEntity {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeCustomer());
  });

  group('CustomerRepositoryImpl', () {
    test('returns local customers when offline', () async {
      // TODO
    });

    test('syncs pending customers when online', () async {
      // TODO
    });

    test('does not create duplicate customer for same phone', () async {
      // TODO
    });
  });
}
