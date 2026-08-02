import 'package:injectable/injectable.dart';
import 'package:vai_marcia/core/error/result.dart';
import 'package:vai_marcia/features/recording/domain/repositories/recording_repository.dart';

@injectable
class StartRecordingUseCase {
  const StartRecordingUseCase(this._repository);

  final RecordingRepository _repository;

  Future<Result<void>> call() => _repository.startRecording();
}

@injectable
class StopRecordingUseCase {
  const StopRecordingUseCase(this._repository);

  final RecordingRepository _repository;

  Future<Result<String>> call() => _repository.stopRecording();
}

@injectable
class SaveRecordingUseCase {
  const SaveRecordingUseCase(this._repository);

  final RecordingRepository _repository;

  Future<Result<String>> call({
    required String filePath,
    required String title,
    required String categoryId,
  }) {
    return _repository.saveRecording(filePath: filePath, title: title, categoryId: categoryId);
  }
}
