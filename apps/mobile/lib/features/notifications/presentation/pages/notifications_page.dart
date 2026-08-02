import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vai_marcia/core/constants/app_strings.dart';
import 'package:vai_marcia/features/notifications/domain/entities/app_notification.dart';
import 'package:vai_marcia/features/notifications/presentation/providers/notifications_providers.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<AppNotification>> notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.notificationsTitle)),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stackTrace) => const Center(child: Text(AppStrings.genericError)),
        data: (List<AppNotification> notifications) {
          if (notifications.isEmpty) {
            return const Center(child: Text(AppStrings.noNotifications));
          }
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (BuildContext context, int index) {
              final AppNotification notification = notifications[index];
              return ListTile(
                leading: Icon(
                  notification.isRead ? Icons.notifications_none : Icons.notifications_active,
                ),
                title: Text(notification.title),
                subtitle: Text(notification.body),
                onTap: () => ref.read(notificationsRepositoryProvider).markAsRead(notification.id),
              );
            },
          );
        },
      ),
    );
  }
}
