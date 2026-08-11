import 'package:equatable/equatable.dart';

enum WatchCommandType { playAudio, getCapabilities, ping }

/// Payload enviado do smartwatch para o telefone (Cenário B) ou do
/// telefone para o smartwatch. Propositalmente minimalista — conforme
/// ARCHITECTURE.md §4, apenas um `audioId` trafega pelo canal, nunca os
/// bytes do áudio.
class WatchCommand extends Equatable {
  const WatchCommand({required this.type, this.audioId});

  final WatchCommandType type;
  final String? audioId;

  Map<String, Object?> toMap() => <String, Object?>{'type': type.name, 'audioId': audioId};

  static WatchCommand fromMap(Map<Object?, Object?> map) {
    return WatchCommand(
      type: WatchCommandType.values.firstWhere(
        (WatchCommandType t) => t.name == map['type'],
        orElse: () => WatchCommandType.ping,
      ),
      audioId: map['audioId'] as String?,
    );
  }

  @override
  List<Object?> get props => <Object?>[type, audioId];
}
