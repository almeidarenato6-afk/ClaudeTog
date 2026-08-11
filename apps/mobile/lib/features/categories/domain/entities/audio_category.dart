import 'package:equatable/equatable.dart';

class AudioCategory extends Equatable {
  const AudioCategory({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorHex,
    this.sortOrder = 0,
    this.isUserCreated = false,
  });

  final String id;
  final String name;
  final String iconName;
  final String colorHex;
  final int sortOrder;
  final bool isUserCreated;

  @override
  List<Object?> get props => <Object?>[id, name, iconName, colorHex, sortOrder, isUserCreated];
}

/// Catálogo fixo pré-carregado para as dez categorias de lançamento
/// referenciadas em ARCHITECTURE.md — o Firestore continua sendo a fonte
/// de verdade (isto só sustenta o pacote offline inicial / UI de
/// primeira execução antes da primeira sincronização).
abstract final class DefaultCategories {
  static const List<AudioCategory> seed = <AudioCategory>[
    AudioCategory(id: 'motivacao', name: 'Motivação', iconName: 'bolt', colorHex: '#FF6B4A', sortOrder: 0),
    AudioCategory(id: 'recuperacao', name: 'Recuperação', iconName: 'healing', colorHex: '#2ECC71', sortOrder: 1),
    AudioCategory(id: 'energia', name: 'Energia', iconName: 'flash_on', colorHex: '#FFC93C', sortOrder: 2),
    AudioCategory(id: 'comemoracao', name: 'Comemoração', iconName: 'celebration', colorHex: '#FF6B4A', sortOrder: 3),
    AudioCategory(id: 'concentracao', name: 'Concentração', iconName: 'center_focus_strong', colorHex: '#152642', sortOrder: 4),
    AudioCategory(id: 'humor', name: 'Humor', iconName: 'mood', colorHex: '#FFC93C', sortOrder: 5),
    AudioCategory(id: 'incentivo', name: 'Incentivo', iconName: 'thumb_up', colorHex: '#2ECC71', sortOrder: 6),
    AudioCategory(id: 'treinador', name: 'Treinador', iconName: 'sports', colorHex: '#152642', sortOrder: 7),
    AudioCategory(id: 'parceiro', name: 'Parceiro', iconName: 'handshake', colorHex: '#FF6B4A', sortOrder: 8),
    AudioCategory(id: 'personalizados', name: 'Personalizados', iconName: 'mic', colorHex: '#8E97A8', sortOrder: 9, isUserCreated: true),
  ];
}
