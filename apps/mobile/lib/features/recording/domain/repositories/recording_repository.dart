import 'package:vai_marcia/core/error/result.dart';

abstract interface class RecordingRepository {
  Future<Result<void>> startRecording();

  Future<Result<String>> stopRecording();

  /// Runs the recorded file through [AudioProcessingPipeline] (today just
  /// [PassthroughStage]), then uploads it and creates the corresponding
  /// `AudioClip` in the "Personalizados" category.
  Future<Result<String>> saveRecording({
    required String filePath,
    required String title,
    required String categoryId,
  });

  Future<Result<void>> discardRecording(String filePath);

  Future<Result<bool>> hasMicrophonePermission();

  Future<Result<bool>> requestMicrophonePermission();
}
