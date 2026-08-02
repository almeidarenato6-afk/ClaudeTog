import 'package:injectable/injectable.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vai_marcia/core/constants/app_strings.dart';
import 'package:vai_marcia/core/error/failure.dart';
import 'package:vai_marcia/core/error/result.dart';
import 'package:vai_marcia/features/store/domain/entities/promotion.dart';
import 'package:vai_marcia/features/store/domain/repositories/store_repository.dart';

/// The only implementation today (ARCHITECTURE.md §9): opens
/// https://www.lojatogplay.com.br in an external browser/webview via
/// `url_launcher`. A future `EcommerceApiStoreRepository` would implement
/// the same [StoreRepository] interface backed by a real product API.
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
    // No promotions backend wired to the external-link implementation —
    // future EcommerceApiStoreRepository would stream from Firestore here.
    return const Stream<List<Promotion>>.empty();
  }
}
