import 'package:vai_marcia/core/error/result.dart';
import 'package:vai_marcia/features/store/domain/entities/promotion.dart';

/// Only [openStore] is exercised today, by [ExternalLinkStoreRepository].
/// [watchActivePromotions] is modeled so a future implementation can drive
/// the store banner's copy without changing the widget.
abstract interface class StoreRepository {
  Future<Result<void>> openStore();

  Stream<List<Promotion>> watchActivePromotions();
}
