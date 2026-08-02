import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vai_marcia/core/di/injection.dart';
import 'package:vai_marcia/features/analytics/domain/analytics_service.dart';

/// [AnalyticsService] has no dedicated UI — this provider only exists so
/// other features' Riverpod providers/controllers can `ref.watch` it
/// consistently instead of reaching into [getIt] directly.
final Provider<AnalyticsService> analyticsServiceProvider = Provider<AnalyticsService>(
  (Ref ref) => getIt<AnalyticsService>(),
);
