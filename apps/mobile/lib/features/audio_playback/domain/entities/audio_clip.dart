import 'package:equatable/equatable.dart';

/// Onde os bytes de um clipe estão atualmente — determina se
/// [PlayAudioUseCase] consegue atingir o orçamento de latência < 150ms
/// (apenas clipes [downloaded]/[bundled] se qualificam; [remoteOnly]
/// precisa ser baixado primeiro).
enum AudioClipAvailability { bundled, downloaded, remoteOnly }

class AudioClip extends Equatable {
  const AudioClip({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.remoteUrl,
    required this.durationMs,
    required this.availability,
    this.localFilePath,
    this.isCustomRecording = false,
    this.ownerUserId,
    this.tags = const <String>[],
    this.playCount = 0,
  });

  final String id;
  final String title;
  final String categoryId;
  final String remoteUrl;
  final int durationMs;
  final AudioClipAvailability availability;
  final String? localFilePath;
  final bool isCustomRecording;
  final String? ownerUserId;
  final List<String> tags;
  final int playCount;

  bool get isReadyForInstantPlayback =>
      availability != AudioClipAvailability.remoteOnly && localFilePath != null;

  AudioClip copyWith({
    String? localFilePath,
    AudioClipAvailability? availability,
    int? playCount,
  }) {
    return AudioClip(
      id: id,
      title: title,
      categoryId: categoryId,
      remoteUrl: remoteUrl,
      durationMs: durationMs,
      availability: availability ?? this.availability,
      localFilePath: localFilePath ?? this.localFilePath,
      isCustomRecording: isCustomRecording,
      ownerUserId: ownerUserId,
      tags: tags,
      playCount: playCount ?? this.playCount,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        title,
        categoryId,
        remoteUrl,
        durationMs,
        availability,
        localFilePath,
        isCustomRecording,
        ownerUserId,
        tags,
        playCount,
      ];
}
