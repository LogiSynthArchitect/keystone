import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:keystone/features/knowledge_base/domain/usecases/update_note_usecase.dart';
import 'package:keystone/features/knowledge_base/domain/entities/knowledge_note_entity.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late UpdateNoteUsecase usecase;
  late MockKnowledgeNoteRepository mockRepo;

  final base = KnowledgeNoteEntity(
    id: 'note-1',
    userId: 'user-1',
    title: 'Test Note',
    description: 'This is a long enough description for testing.',
    tags: ['lock', 'repair'],
    isArchived: false,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );

  setUp(() {
    mockRepo = MockKnowledgeNoteRepository();
    usecase = UpdateNoteUsecase(mockRepo);
  });

  setUpAll(() {
    registerFallbackValue(base);
  });

  group('UpdateNoteUsecase', () {
    test('sets lastEditedAt to now on save', () async {
      final before = DateTime.now();

      when(() => mockRepo.updateNote(any())).thenAnswer((invocation) async {
        return invocation.positionalArguments[0] as KnowledgeNoteEntity;
      });

      final result = await usecase(UpdateNoteParams(note: base));

      expect(result.lastEditedAt, isNotNull);
      expect(result.lastEditedAt!.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
    });

    test('throws ValidationException when title is too short', () async {
      final short = base.copyWith(title: 'ab');
      expect(
        () => usecase(UpdateNoteParams(note: short)),
        throwsA(predicate((e) => e.toString().contains('TITLE_TOO_SHORT'))),
      );
    });

    test('throws ValidationException when description is too short', () async {
      final short = base.copyWith(description: 'too short');
      expect(
        () => usecase(UpdateNoteParams(note: short)),
        throwsA(predicate((e) => e.toString().contains('DESCRIPTION_TOO_SHORT'))),
      );
    });

    test('normalises tags to lowercase with underscores', () async {
      when(() => mockRepo.updateNote(any())).thenAnswer((invocation) async {
        return invocation.positionalArguments[0] as KnowledgeNoteEntity;
      });

      final withTags = base.copyWith(tags: ['Lock Repair', 'Door Install']);
      final result = await usecase(UpdateNoteParams(note: withTags));

      expect(result.tags, equals(['lock_repair', 'door_install']));
    });
  });
}
