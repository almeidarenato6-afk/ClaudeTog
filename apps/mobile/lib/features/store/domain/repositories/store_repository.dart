import 'package:vai_marcia/core/error/result.dart';
import 'package:vai_marcia/features/store/domain/entities/promotion.dart';

/// Apenas [openStore] é exercitado hoje, por [ExternalLinkStoreRepository].
/// [watchActivePromotions] é modelado para que uma implementação futura
/// possa alimentar o texto do banner da loja sem alterar o widget.
abstract interface class StoreRepository {
  Future<Result<void>> openStore();

  Stream<List<Promotion>> watchActivePromotions();
}
