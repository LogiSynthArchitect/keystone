import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CreateNoteUsecase', () {
    test('creates note with valid title and description', () async {
      // TODO
    });

    test('throws ValidationException when title is too short', () async {
      // TODO
    });

    test('throws ValidationException when description is too short', () async {
      // TODO
    });

    test('throws ValidationException when more than 10 tags', () async {
      // TODO
    });

    test('normalizes tags to lowercase with underscores', () async {
      // TODO
    });
  });
}
