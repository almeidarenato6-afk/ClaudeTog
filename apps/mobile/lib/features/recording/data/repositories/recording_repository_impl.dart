import 'package:injectable/injectable.dart';
import 'package:vai_marcia/core/error/failure.dart';
import 'package:vai_marcia/core/error/result.dart';
import 'package:vai_marcia/features/recording/data/datasources/recording_local_datasource.dart';
import 'package:vai_marcia/features/recording/data/datasources/recording_remote_datasource.dart';
import 'package:vai_marcia/features/recording/domain/pipeline/audio_processing_pipeline.dart';
import 'package:vai_marcia/features/recording/domain/repositories/recording_repository.dart';

@LazySingleton(as: RecordingRepository)
class RecordingRepositoryImpl implements RecordingRepository {
  RecordingRepositoryImpl(
    this._local,
    this._remote, {
    AudioProcessingPipeline? pipeline,
  }) : _pipeline = pipeline ?? const AudioProcessingPipeline(<AudioProcessingStage>[PassthroughStage()]);

  final RecordingLocalDataSource _local;
  final RecordingRemoteDataSource _remote;
  final AudioProcessingPipeline _pipeline;

  @override
  Future<Result<void>> startRecording() async {
    try {
      await _local.start();
      return const Result<void>.ok(null);
    } on Object catch (e) {
      return Result<void>.err(RecordingFailure('Falha ao iniciar gravação', cause: e));
    }
  }

  @override
  Future<Result<String>> stopRecording() async {
    try {
      final String? path = await _local.stop();
      if (path == null) {
        return const Result<String>.err(RecordingFailure('Nenhuma gravação em andamento'));
      }
      return Result<String>.ok(path);
    } on Object catch (e) {
      return Result<String>.err(RecordingFailure('Falha ao parar gravação', cause: e));
    }
  }

  @override
  Future<Result<String>> saveRecording({
    required String filePath,
    required String title,
    required String categoryId,
  }) async {
    try {
      final String processedPath = await _pipeline.run(filePath);
      final String clipId = await _remote.uploadAndCreateClip(
        localFilePath: processedPath,
        title: title,
        categoryId: categoryId,
        durationMs: 0,
      );
      return Result<String>.ok(clipId);
    } on Object catch (e) {
      return Result<String>.err(RecordingFailure('Falha ao salvar gravação', cause: e));
    }
  }

  @override
  Future<Result<void>> discardRecording(String filePath) async {
    try {
      await _local.deleteFile(filePath);
      return const Result<void>.ok(null);
    } on Object catch (e) {
      return Result<void>.err(RecordingFailure('Falha ao descartar gravação', cause: e));
    }
  }

  @override
  Future<Result<bool>> hasMicrophonePermission() async {
    try {
      return Result<bool>.ok(await _local.hasMicrophonePermission());
    } on Object catch (e) {
      return Result<bool>.err(PermissionFailure('Falha ao verificar permissão de microfone', cause: e));
    }
  }

  @override
  Future<Result<bool>> requestMicrophonePermission() async {
    try {
      return Result<bool>.ok(await _local.requestMicrophonePermission());
    } on Object catch (e) {
      return Result<bool>.err(PermissionFailure('Falha ao solicitar permissão de microfone', cause: e));
    }
  }
}
