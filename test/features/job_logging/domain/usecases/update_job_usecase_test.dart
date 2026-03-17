import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:keystone/features/job_logging/domain/entities/job_entity.dart';

class FakeJob extends Fake implements JobEntity {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeJob());
  });

  group('Job 24 hour lock rule', () {
    test('allows updating notes after 24 hours', () async {
      // TODO
    });

    test('blocks changing serviceType after 24 hours', () async {
      // TODO
    });

    test('blocks changing jobDate after 24 hours', () async {
      // TODO
    });

    test('allows changing serviceType within 24 hours', () async {
      // TODO
    });

    test('allows changing jobDate within 24 hours', () async {
      // TODO
    });
  });
}
