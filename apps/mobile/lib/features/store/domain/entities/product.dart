import 'package:equatable/equatable.dart';

/// Modeled for a future `EcommerceApiStoreRepository` (ARCHITECTURE.md §9)
/// — unused by today's [ExternalLinkStoreRepository], which only opens a
/// web link. Kept here so the swap-in later touches zero UI code.
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
