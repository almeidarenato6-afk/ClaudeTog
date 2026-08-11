import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vai_marcia/core/di/injection.dart';
import 'package:vai_marcia/features/analytics/domain/analytics_service.dart';

/// [AnalyticsService] não tem UI dedicada — este provider existe apenas
/// para que providers/controllers Riverpod de outras features possam
/// usar `ref.watch` de forma consistente, em vez de acessar [getIt]
/// diretamente.
final Provider<AnalyticsService> analyticsServiceProvider = Provider<AnalyticsService>(
  (Ref ref) => getIt<AnalyticsService>(),
);
