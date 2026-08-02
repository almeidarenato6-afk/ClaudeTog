import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:injectable/injectable.dart';
import 'package:vai_marcia/core/constants/app_constants.dart';
import 'package:vai_marcia/core/error/failure.dart';
import 'package:vai_marcia/core/error/result.dart';
import 'package:vai_marcia/features/notifications/data/datasources/notifications_local_service.dart';
import 'package:vai_marcia/features/notifications/domain/entities/app_notification.dart';
import 'package:vai_marcia/features/notifications/domain/repositories/notifications_repository.dart';

@LazySingleton(as: NotificationsRepository)
class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl(
    this._messaging,
    this._localService,
    this._firestore,
    this._auth,
  );

  final FirebaseMessaging _messaging;
  final NotificationsLocalService _localService;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  @override
  Future<Result<void>> initialize() async {
    try {
      await _messaging.requestPermission();
      await _localService.initialize();
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final RemoteNotification? notification = message.notification;
        if (notification != null) {
          _localService.showForegroundNotification(
            title: notification.title ?? '',
            body: notification.body ?? '',
          );
        }
      });
      return const Result<void>.ok(null);
    } on Object catch (e) {
      return Result<void>.err(UnknownFailure('Falha ao inicializar notificações', cause: e));
    }
  }

  @override
  Future<Result<String?>> getFcmToken() async {
    try {
      return Result<String?>.ok(await _messaging.getToken());
    } on Object catch (e) {
      return Result<String?>.err(UnknownFailure('Falha ao obter token FCM', cause: e));
    }
  }

  @override
  Stream<List<AppNotification>> watchNotifications() {
    final String? uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const Stream<List<AppNotification>>.empty();
    }
    return _firestore
        .collection(AppConstants.firestoreCollectionUsers)
        .doc(uid)
        .collection(AppConstants.firestoreCollectionNotifications)
        .orderBy('receivedAt', descending: true)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs.map(_docToNotification).toList(growable: false),
        );
  }

  @override
  Future<Result<void>> markAsRead(String id) async {
    final String? uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const Result<void>.err(UnknownFailure('Usuário não autenticado'));
    }
    try {
      await _firestore
          .collection(AppConstants.firestoreCollectionUsers)
          .doc(uid)
          .collection(AppConstants.firestoreCollectionNotifications)
          .doc(id)
          .update(<String, dynamic>{'isRead': true});
      return const Result<void>.ok(null);
    } on Object catch (e) {
      return Result<void>.err(UnknownFailure('Falha ao marcar notificação como lida', cause: e));
    }
  }

  AppNotification _docToNotification(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data();
    return AppNotification(
      id: doc.id,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      category: NotificationCategory.values.firstWhere(
        (NotificationCategory c) => c.name == data['category'],
        orElse: () => NotificationCategory.general,
      ),
      receivedAt: (data['receivedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] as bool? ?? false,
      deepLink: data['deepLink'] as String?,
    );
  }
}
