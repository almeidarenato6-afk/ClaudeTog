import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';

/// Envolve o [flutter_local_notifications] para exibição de mensagens
/// FCM em primeiro plano — notificações em segundo plano/com app
/// encerrado são tratadas diretamente pelo SO a partir do payload FCM.
@lazySingleton
class NotificationsLocalService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'vai_marcia_default',
    'Vai Márcia',
    description: 'Notificações do Vai Márcia',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  Future<void> showForegroundNotification({required String title, required String body}) {
    return _plugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(_channel.id, _channel.name, channelDescription: _channel.description),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}
