import '../../../../core/errors/validation_exception.dart';
import '../../../../core/usecases/use_case.dart';
import '../entities/knowledge_note_entity.dart';
import '../repositories/knowledge_note_repository.dart';

class CreateNoteParams {
  final String userId;
  final String title;
  final String description;
  final List<String> tags;
  final String? photoUrl;
  final String? serviceType;

  const CreateNoteParams({
    required this.userId,
    required this.title,
    required this.description,
    this.tags = const [],
    this.photoUrl,
    this.serviceType,
  });
}

class CreateNoteUsecase implements UseCase<KnowledgeNoteEntity, CreateNoteParams> {
  final KnowledgeNoteRepository _repository;
  CreateNoteUsecase(this._repository);

  @override
  Future<KnowledgeNoteEntity> call(CreateNoteParams params) async {
    if (params.title.trim().length < 3) {
      throw const ValidationException(
        message: 'Title must be at least 3 characters.',
        code: 'TITLE_TOO_SHORT',
        field: 'title',
      );
    }
    if (params.description.trim().length < 10) {
      throw const ValidationException(
        message: 'Description must be at least 10 characters.',
        code: 'DESCRIPTION_TOO_SHORT',
        field: 'description',
      );
    }
    if (params.tags.length > 10) {
      throw const ValidationException(
        message: 'Maximum 10 tags allowed.',
        code: 'TOO_MANY_TAGS',
        field: 'tags',
      );
    }
    final now = DateTime.now();
    final note = KnowledgeNoteEntity(
      id: '',
      userId: params.userId,
      title: params.title.trim(),
      description: params.description.trim(),
      tags: params.tags.map((t) => t.toLowerCase().replaceAll(' ', '_')).toList(),
      photoUrl: params.photoUrl,
      serviceType: params.serviceType,
      isArchived: false,
      createdAt: now,
      updatedAt: now,
    );
    return _repository.createNote(note);
  }
}
