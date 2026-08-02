import 'package:equatable/equatable.dart';

class Promotion extends Equatable {
  const Promotion({
    required this.id,
    required this.title,
    required this.description,
    this.discountPercent,
    this.bannerImageUrl,
  });

  final String id;
  final String title;
  final String description;
  final int? discountPercent;
  final String? bannerImageUrl;

  @override
  List<Object?> get props => <Object?>[id, title, description, discountPercent, bannerImageUrl];
}
