import 'package:equatable/equatable.dart';

enum NotificationCategory { newAudio, promotion, newCategory, general }

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.receivedAt,
    this.isRead = false,
    this.deepLink,
  });

  final String id;
  final String title;
  final String body;
  final NotificationCategory category;
  final DateTime receivedAt;
  final bool isRead;
  final String? deepLink;

  @override
  List<Object?> get props => <Object?>[id, title, body, category, receivedAt, isRead, deepLink];
}
