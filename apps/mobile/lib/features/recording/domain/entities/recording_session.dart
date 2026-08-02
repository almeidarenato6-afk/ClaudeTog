import 'package:equatable/equatable.dart';

enum RecordingStatus { idle, recording, stopped, processing, saved }

class RecordingSession extends Equatable {
  const RecordingSession({
    required this.status,
    this.filePath,
    this.elapsed = Duration.zero,
  });

  final RecordingStatus status;
  final String? filePath;
  final Duration elapsed;

  RecordingSession copyWith({
    RecordingStatus? status,
    String? filePath,
    Duration? elapsed,
  }) {
    return RecordingSession(
      status: status ?? this.status,
      filePath: filePath ?? this.filePath,
      elapsed: elapsed ?? this.elapsed,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, filePath, elapsed];
}
