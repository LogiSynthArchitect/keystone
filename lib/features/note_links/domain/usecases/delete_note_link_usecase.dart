import '../repositories/note_link_repository.dart';

class DeleteNoteLinkUsecase {
  final NoteLinkRepository _repository;
  DeleteNoteLinkUsecase(this._repository);
  Future<void> call(String id) => _repository.deleteLink(id);
}
