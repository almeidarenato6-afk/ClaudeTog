import 'package:injectable/injectable.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vai_marcia/core/constants/app_strings.dart';
import 'package:vai_marcia/core/error/failure.dart';
import 'package:vai_marcia/core/error/result.dart';
import 'package:vai_marcia/features/store/domain/entities/promotion.dart';
import 'package:vai_marcia/features/store/domain/repositories/store_repository.dart';

/// A única implementação hoje (ARCHITECTURE.md §9): abre
/// https://www.lojatogplay.com.br em um navegador/webview externo via
/// `url_launcher`. Uma futura `EcommerceApiStoreRepository` implementaria
/// a mesma interface [StoreRepository] apoiada em uma API de produtos
/// real.
@LazySingleton(as: StoreRepository)
class ExternalLinkStoreRepository implements StoreRepository {
  @override
  Future<Result<void>> openStore() async {
    try {
      final Uri uri = Uri.parse(AppStrings.storeUrl);
      final bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        return const Result<void>.err(NetworkFailure(AppStrings.storeOpenError));
      }
      return const Result<void>.ok(null);
    } on Object catch (e) {
      return Result<void>.err(NetworkFailure(AppStrings.storeOpenError, cause: e));
    }
  }

  @override
  Stream<List<Promotion>> watchActivePromotions() {
    // Nenhum backend de promoções conectado à implementação de link
    // externo — uma futura EcommerceApiStoreRepository faria o stream a
    // partir do Firestore aqui.
    return const Stream<List<Promotion>>.empty();
  }
}
