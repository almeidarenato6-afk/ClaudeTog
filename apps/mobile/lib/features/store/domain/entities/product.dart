import 'package:equatable/equatable.dart';

/// Modelado para uma futura `EcommerceApiStoreRepository`
/// (ARCHITECTURE.md §9) — não utilizado pela atual
/// [ExternalLinkStoreRepository], que apenas abre um link web. Mantido
/// aqui para que a futura substituição não toque em nenhum código de UI.
class Product extends Equatable {
  const Product({
    required this.id,
    required this.name,
    required this.priceCents,
    required this.imageUrl,
    this.description,
    this.inStock = true,
  });

  final String id;
  final String name;
  final int priceCents;
  final String imageUrl;
  final String? description;
  final bool inStock;

  @override
  List<Object?> get props => <Object?>[id, name, priceCents, imageUrl, description, inStock];
}
