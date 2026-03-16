import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:keystone/features/knowledge_base/domain/usecases/create_note_usecase.dart';
import 'package:keystone/features/knowledge_base/domain/entities/knowledge_note_entity.dart';
import 'package:keystone/core/errors/validation_exception.dart';
import '../../../../helpers/mocks.dart';

class FakeNote extends Fake implements KnowledgeNoteEntity {}

void main() {
  late CreateNoteUsecase usecase;
  late MockKnowledgeNoteRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeNote());
  });

  setUp(() {
    mockRepository = MockKnowledgeNoteRepository();
    usecase = CreateNoteUsecase(mockRepository);
  });

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
