import 'package:vai_marcia/core/error/result.dart';

abstract interface class RecordingRepository {
  Future<Result<void>> startRecording();

  Future<Result<String>> stopRecording();

  /// Passa o arquivo gravado pelo [AudioProcessingPipeline] (hoje apenas
  /// [PassthroughStage]), depois faz o upload e cria o `AudioClip`
  /// correspondente na categoria "Personalizados".
  Future<Result<String>> saveRecording({
    required String filePath,
    required String title,
    required String categoryId,
  });

  Future<Result<void>> discardRecording(String filePath);

  Future<Result<bool>> hasMicrophonePermission();

  Future<Result<bool>> requestMicrophonePermission();
}
