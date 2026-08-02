import 'package:equatable/equatable.dart';

class Favorite extends Equatable {
  const Favorite({required this.clipId, required this.addedAt});

  final String clipId;
  final DateTime addedAt;

  @override
  List<Object?> get props => <Object?>[clipId, addedAt];
}
