/// Extension seam for future AI-assisted audio processing
/// (ARCHITECTURE.md §8 / docs/DEVICE_DETECTION.md are silent on this by
/// design — this is purely a `recording` feature concern).
///
/// TODAY only [PassthroughStage] is wired in: a recorded clip goes
/// straight from mic to storage, unmodified. The interface exists now so
/// that when AI processing ships, it plugs in as additional [stages]
/// without touching [RecordAudioUseCase], the recording UI, or the
/// storage/upload code path at all.
///
/// Documented (not implemented) future stages:
/// - [NoiseReductionStage]: suppress wind/crowd noise from courtside
///   recordings.
/// - [VoiceEnhancementStage]: normalize loudness/EQ for consistent
///   playback volume across user-recorded clips.
/// - [PhraseSegmentationStage]: auto-trim silence and split a single
///   recording into multiple short clips.
/// - [AutoCategorizationStage]: suggest a category (Motivação, Humor,
///   etc.) from the transcribed/analyzed content.
abstract interface class AudioProcessingStage {
  String get name;

  /// Takes the path to a raw (or previous-stage-processed) audio file and
  /// returns the path to its output — implementations may return the same
  /// path unchanged (as [PassthroughStage] does).
  Future<String> process(String inputFilePath);
}

class AudioProcessingPipeline {
  const AudioProcessingPipeline(this.stages);

  final List<AudioProcessingStage> stages;

  Future<String> run(String inputFilePath) async {
    String current = inputFilePath;
    for (final AudioProcessingStage stage in stages) {
      current = await stage.process(current);
    }
    return current;
  }
}

/// The only stage wired in today: audio passes through unmodified.
class PassthroughStage implements AudioProcessingStage {
  const PassthroughStage();

  @override
  String get name => 'passthrough';

  @override
  Future<String> process(String inputFilePath) async => inputFilePath;
}

/// NOT IMPLEMENTED — documented extension point only. See class doc above.
abstract interface class NoiseReductionStage implements AudioProcessingStage {}

/// NOT IMPLEMENTED — documented extension point only. See class doc above.
abstract interface class VoiceEnhancementStage implements AudioProcessingStage {}

/// NOT IMPLEMENTED — documented extension point only. See class doc above.
abstract interface class PhraseSegmentationStage implements AudioProcessingStage {}

/// NOT IMPLEMENTED — documented extension point only. See class doc above.
abstract interface class AutoCategorizationStage implements AudioProcessingStage {}
