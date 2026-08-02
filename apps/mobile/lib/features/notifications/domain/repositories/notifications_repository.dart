import 'package:vai_marcia/core/error/result.dart';
import 'package:vai_marcia/features/notifications/domain/entities/app_notification.dart';

abstract interface class NotificationsRepository {
  Future<Result<void>> initialize();

  Future<Result<String?>> getFcmToken();

  Stream<List<AppNotification>> watchNotifications();

  Future<Result<void>> markAsRead(String id);
}
