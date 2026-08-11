import 'package:equatable/equatable.dart';
import 'package:vai_marcia/features/store/domain/entities/product.dart';

class CartItem extends Equatable {
  const CartItem({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  int get subtotalCents => product.priceCents * quantity;

  @override
  List<Object?> get props => <Object?>[product, quantity];
}

/// Modelado, mas não implementado — veja a documentação de [Product].
/// Nenhum fluxo de checkout existe hoje; `store` apenas faz deep-link
/// para o site externo da Loja TogPlay.
class Cart extends Equatable {
  const Cart({this.items = const <CartItem>[]});

  final List<CartItem> items;

  int get totalCents => items.fold<int>(0, (int sum, CartItem item) => sum + item.subtotalCents);

  @override
  List<Object?> get props => <Object?>[items];
}
