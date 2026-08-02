import 'package:equatable/equatable.dart';

class PairedSpeaker extends Equatable {
  const PairedSpeaker({
    required this.id,
    required this.name,
    required this.isA2dpActive,
    this.brand,
  });

  final String id;
  final String name;
  final bool isA2dpActive;
  final String? brand;

  @override
  List<Object?> get props => <Object?>[id, name, isA2dpActive, brand];
}
