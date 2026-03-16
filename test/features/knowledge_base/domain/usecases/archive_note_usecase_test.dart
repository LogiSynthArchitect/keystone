import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:keystone/features/knowledge_base/domain/usecases/archive_note_usecase.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late ArchiveNoteUsecase usecase;
  late MockKnowledgeNoteRepository mockRepository;

  setUp(() {
    mockRepository = MockKnowledgeNoteRepository();
    usecase = ArchiveNoteUsecase(mockRepository);
  });

  group('ArchiveNoteUsecase', () {
    test('calls archiveNote on repository with correct id', () async {
      // TODO
    });

    test('archive is always reversible', () async {
      // TODO
    });
  });
}
