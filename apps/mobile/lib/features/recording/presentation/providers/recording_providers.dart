import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vai_marcia/core/di/injection.dart';
import 'package:vai_marcia/features/recording/domain/entities/recording_session.dart';
import 'package:vai_marcia/features/recording/domain/usecases/record_audio_usecase.dart';

final NotifierProvider<RecordingController, RecordingSession> recordingControllerProvider =
    NotifierProvider<RecordingController, RecordingSession>(RecordingController.new);

class RecordingController extends Notifier<RecordingSession> {
  late final StartRecordingUseCase _start = getIt<StartRecordingUseCase>();
  late final StopRecordingUseCase _stop = getIt<StopRecordingUseCase>();
  late final SaveRecordingUseCase _save = getIt<SaveRecordingUseCase>();

  @override
  RecordingSession build() => const RecordingSession(status: RecordingStatus.idle);

  Future<void> startRecording() async {
    final result = await _start();
    result.when(
      ok: (_) => state = state.copyWith(status: RecordingStatus.recording),
      err: (_) {},
    );
  }

  Future<void> stopRecording() async {
    final result = await _stop();
    result.when(
      ok: (String path) => state = state.copyWith(status: RecordingStatus.stopped, filePath: path),
      err: (_) {},
    );
  }

  Future<bool> saveRecording({required String title, required String categoryId}) async {
    final String? path = state.filePath;
    if (path == null) {
      return false;
    }
    state = state.copyWith(status: RecordingStatus.processing);
    final result = await _save(filePath: path, title: title, categoryId: categoryId);
    return result.when(
      ok: (_) {
        state = state.copyWith(status: RecordingStatus.saved);
        return true;
      },
      err: (_) {
        state = state.copyWith(status: RecordingStatus.stopped);
        return false;
      },
    );
  }

  void reset() => state = const RecordingSession(status: RecordingStatus.idle);
}
