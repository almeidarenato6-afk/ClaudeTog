import 'package:json_annotation/json_annotation.dart';
import 'package:vai_marcia/features/audio_playback/domain/entities/audio_clip.dart';

part 'audio_clip_model.g.dart';

@JsonSerializable()
class AudioClipModel {
  const AudioClipModel({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.remoteUrl,
    required this.durationMs,
    this.localFilePath,
    this.isCustomRecording = false,
    this.ownerUserId,
    this.tags = const <String>[],
    this.playCount = 0,
  });

  factory AudioClipModel.fromJson(Map<String, dynamic> json) => _$AudioClipModelFromJson(json);

  factory AudioClipModel.fromEntity(AudioClip entity) {
    return AudioClipModel(
      id: entity.id,
      title: entity.title,
      categoryId: entity.categoryId,
      remoteUrl: entity.remoteUrl,
      durationMs: entity.durationMs,
      localFilePath: entity.localFilePath,
      isCustomRecording: entity.isCustomRecording,
      ownerUserId: entity.ownerUserId,
      tags: entity.tags,
      playCount: entity.playCount,
    );
  }

  final String id;
  final String title;
  final String categoryId;
  final String remoteUrl;
  final int durationMs;
  final String? localFilePath;
  final bool isCustomRecording;
  final String? ownerUserId;
  final List<String> tags;
  final int playCount;

  Map<String, dynamic> toJson() => _$AudioClipModelToJson(this);

  AudioClip toEntity() {
    return AudioClip(
      id: id,
      title: title,
      categoryId: categoryId,
      remoteUrl: remoteUrl,
      durationMs: durationMs,
      availability: localFilePath != null
          ? AudioClipAvailability.downloaded
          : AudioClipAvailability.remoteOnly,
      localFilePath: localFilePath,
      isCustomRecording: isCustomRecording,
      ownerUserId: ownerUserId,
      tags: tags,
      playCount: playCount,
    );
  }
}
