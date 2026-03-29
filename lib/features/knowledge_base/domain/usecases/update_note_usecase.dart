import '../../../../core/errors/validation_exception.dart';
import '../../../../core/usecases/use_case.dart';
import '../entities/knowledge_note_entity.dart';
import '../repositories/knowledge_note_repository.dart';

class UpdateNoteParams {
  final KnowledgeNoteEntity note;

  UpdateNoteParams({required this.note});
}

class UpdateNoteUsecase implements UseCase<KnowledgeNoteEntity, UpdateNoteParams> {
  final KnowledgeNoteRepository _repository;
  UpdateNoteUsecase(this._repository);

  @override
  Future<KnowledgeNoteEntity> call(UpdateNoteParams params) async {
    final note = params.note;

    if (note.title.trim().length < 3) {
      throw const ValidationException(
        message: 'Title must be at least 3 characters.',
        code: 'TITLE_TOO_SHORT',
        field: 'title',
      );
    }
    
    if (note.description.trim().length < 10) {
      throw const ValidationException(
        message: 'Description must be at least 10 characters.',
        code: 'DESCRIPTION_TOO_SHORT',
        field: 'description',
      );
    }

    final updatedNote = KnowledgeNoteEntity(
      id: note.id,
      userId: note.userId,
      title: note.title.trim(),
      description: note.description.trim(),
      tags: note.tags.map((t) => t.toLowerCase().replaceAll(' ', '_')).toList(),
      photoUrl: note.photoUrl,
      serviceType: note.serviceType,
      isArchived: note.isArchived,
      lastEditedAt: DateTime.now(),
      createdAt: note.createdAt,
      updatedAt: DateTime.now(),
    );

    return _repository.updateNote(updatedNote);
  }
}
