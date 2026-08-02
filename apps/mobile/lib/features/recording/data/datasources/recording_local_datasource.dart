import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

abstract interface class RecordingLocalDataSource {
  Future<bool> hasMicrophonePermission();
  Future<bool> requestMicrophonePermission();
  Future<void> start();
  Future<String?> stop();
  Future<void> deleteFile(String filePath);
}

@LazySingleton(as: RecordingLocalDataSource)
class RecordingLocalDataSourceImpl implements RecordingLocalDataSource {
  final AudioRecorder _recorder = AudioRecorder();

  @override
  Future<bool> hasMicrophonePermission() async {
    return Permission.microphone.isGranted;
  }

  @override
  Future<bool> requestMicrophonePermission() async {
    final PermissionStatus status = await Permission.microphone.request();
    return status.isGranted;
  }

  @override
  Future<void> start() async {
    final Directory dir = await getTemporaryDirectory();
    final String path = p.join(dir.path, 'recording_${DateTime.now().millisecondsSinceEpoch}.m4a');
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100),
      path: path,
    );
  }

  @override
  Future<String?> stop() {
    return _recorder.stop();
  }

  @override
  Future<void> deleteFile(String filePath) async {
    final File file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
