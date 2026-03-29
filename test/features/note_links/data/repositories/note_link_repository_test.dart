import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:keystone/features/note_links/data/repositories/note_link_repository_impl.dart';
import 'package:keystone/features/note_links/data/datasources/note_link_local_datasource.dart';
import 'package:keystone/features/note_links/data/datasources/note_link_remote_datasource.dart';
import 'package:keystone/features/note_links/data/models/note_job_link_model.dart';
import 'package:keystone/features/knowledge_base/domain/entities/note_job_link_entity.dart';
import '../../../../helpers/mocks.dart';

class MockNoteLinkLocal extends Mock implements NoteLinkLocalDatasource {}
class MockNoteLinkRemote extends Mock implements NoteLinkRemoteDatasource {}

final _sampleModel = NoteJobLinkModel(
  id: 'link-1',
  noteId: 'note-1',
  jobId: 'job-1',
  userId: 'user-1',
  createdAt: '2024-01-01T00:00:00.000Z',
);

void main() {
  late NoteLinkRepositoryImpl repository;
  late MockNoteLinkLocal mockLocal;
  late MockNoteLinkRemote mockRemote;
  late MockConnectivityService mockConnectivity;

  setUpAll(() {
    registerFallbackValue(_sampleModel);
  });

  setUp(() {
    mockLocal       = MockNoteLinkLocal();
    mockRemote      = MockNoteLinkRemote();
    mockConnectivity = MockConnectivityService();
    repository      = NoteLinkRepositoryImpl(mockLocal, mockRemote, mockConnectivity);
  });

  group('NoteLinkRepository — offline-first', () {
    test('createLink saves locally and syncs remote when online', () async {
      when(() => mockConnectivity.isConnected).thenAnswer((_) async => true);
      when(() => mockLocal.save(any())).thenAnswer((_) async {});
      when(() => mockRemote.create(any())).thenAnswer((_) async => _sampleModel);

      final result = await repository.createLink('note-1', 'job-1', 'user-1');

      expect(result.noteId, equals('note-1'));
      expect(result.jobId, equals('job-1'));
      // local saved twice (before and after remote)
      verify(() => mockLocal.save(any())).called(2);
      verify(() => mockRemote.create(any())).called(1);
    });

    test('createLink saves locally only when offline', () async {
      when(() => mockConnectivity.isConnected).thenAnswer((_) async => false);
      when(() => mockLocal.save(any())).thenAnswer((_) async {});

      final result = await repository.createLink('note-1', 'job-1', 'user-1');

      expect(result.noteId, equals('note-1'));
      verify(() => mockLocal.save(any())).called(1);
      verifyNever(() => mockRemote.create(any()));
    });

    test('deleteLink removes locally and calls remote when online', () async {
      when(() => mockConnectivity.isConnected).thenAnswer((_) async => true);
      when(() => mockLocal.delete(any())).thenAnswer((_) async {});
      when(() => mockRemote.delete(any())).thenAnswer((_) async {});

      await repository.deleteLink('link-1');

      verify(() => mockLocal.delete('link-1')).called(1);
      verify(() => mockRemote.delete('link-1')).called(1);
    });

    test('deleteLink removes locally only when offline', () async {
      when(() => mockConnectivity.isConnected).thenAnswer((_) async => false);
      when(() => mockLocal.delete(any())).thenAnswer((_) async {});

      await repository.deleteLink('link-1');

      verify(() => mockLocal.delete('link-1')).called(1);
      verifyNever(() => mockRemote.delete(any()));
    });

    test('getLinksForNote returns local results when offline', () async {
      when(() => mockConnectivity.isConnected).thenAnswer((_) async => false);
      when(() => mockLocal.getForNote(any())).thenAnswer((_) async => [_sampleModel]);

      final result = await repository.getLinksForNote('note-1');

      expect(result.length, equals(1));
      expect(result.first, isA<NoteJobLinkEntity>());
      verifyNever(() => mockRemote.getForNote(any()));
    });
  });
}
