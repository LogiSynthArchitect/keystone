import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:keystone/features/job_logging/domain/entities/job_entity.dart';

class FakeJob extends Fake implements JobEntity {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeJob());
  });

  group('JobRepositoryImpl offline-first', () {
    test('writes local first then attempts remote when online', () async {
      // TODO
    });

    test('saves with pending status when offline', () async {
      // TODO
    });

    test('returns local data when offline', () async {
      // TODO
    });

    test('never loses data when remote fails', () async {
      // TODO
    });
  });
}
