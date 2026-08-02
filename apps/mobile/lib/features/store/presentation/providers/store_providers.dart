import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vai_marcia/core/di/injection.dart';
import 'package:vai_marcia/features/store/domain/repositories/store_repository.dart';

final Provider<StoreRepository> storeRepositoryProvider = Provider<StoreRepository>(
  (Ref ref) => getIt<StoreRepository>(),
);
