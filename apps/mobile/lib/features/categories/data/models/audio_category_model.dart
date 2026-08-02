import 'package:json_annotation/json_annotation.dart';
import 'package:vai_marcia/features/categories/domain/entities/audio_category.dart';

part 'audio_category_model.g.dart';

@JsonSerializable()
class AudioCategoryModel {
  const AudioCategoryModel({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorHex,
    this.sortOrder = 0,
    this.isUserCreated = false,
  });

  factory AudioCategoryModel.fromJson(Map<String, dynamic> json) => _$AudioCategoryModelFromJson(json);

  factory AudioCategoryModel.fromEntity(AudioCategory entity) {
    return AudioCategoryModel(
      id: entity.id,
      name: entity.name,
      iconName: entity.iconName,
      colorHex: entity.colorHex,
      sortOrder: entity.sortOrder,
      isUserCreated: entity.isUserCreated,
    );
  }

  final String id;
  final String name;
  final String iconName;
  final String colorHex;
  final int sortOrder;
  final bool isUserCreated;

  Map<String, dynamic> toJson() => _$AudioCategoryModelToJson(this);

  AudioCategory toEntity() {
    return AudioCategory(
      id: id,
      name: name,
      iconName: iconName,
      colorHex: colorHex,
      sortOrder: sortOrder,
      isUserCreated: isUserCreated,
    );
  }
}
