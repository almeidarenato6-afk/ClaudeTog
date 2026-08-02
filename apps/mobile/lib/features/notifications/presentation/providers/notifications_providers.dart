import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vai_marcia/core/di/injection.dart';
import 'package:vai_marcia/features/notifications/domain/entities/app_notification.dart';
import 'package:vai_marcia/features/notifications/domain/repositories/notifications_repository.dart';

final Provider<NotificationsRepository> notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (Ref ref) => getIt<NotificationsRepository>(),
);

final StreamProvider<List<AppNotification>> notificationsProvider = StreamProvider<List<AppNotification>>(
  (Ref ref) => ref.watch(notificationsRepositoryProvider).watchNotifications(),
);
