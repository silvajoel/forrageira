import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

import 'fcm_web_notifications_stub.dart'
    if (dart.library.html) 'fcm_web_notifications.dart' as fcm_web;

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static const String _webVapidKey = String.fromEnvironment('FCM_WEB_VAPID_KEY');

  Future<void> init() async {
    await _requestPermission();
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) return;
      await _saveToken();
    });
    await _saveToken();
    _listenTokenRefresh();
    _listenForeground();
    _listenBackground();
    await handleInitialMessage();
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission();
  }

  Future<void> _saveToken() async {
    final token = await _getToken();
    final user = FirebaseAuth.instance.currentUser;

    if (token != null && user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    }
  }

  Future<String?> _getToken() {
    if (!kIsWeb) return _messaging.getToken();
    if (_webVapidKey.isEmpty) {
      debugPrint('FCM web sem VAPID: use --dart-define=FCM_WEB_VAPID_KEY');
      return Future.value(null);
    }
    return _messaging.getToken(vapidKey: _webVapidKey);
  }

  void _listenTokenRefresh() {
    _messaging.onTokenRefresh.listen((token) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    });
  }

  void _listenForeground() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title =
          message.notification?.title ?? message.data['title'] ?? 'Nova notificação';
      final body = message.notification?.body ?? message.data['body'];
      if (kIsWeb) {
        fcm_web.showWebForegroundNotification(title, body);
        return;
      }
      NotificationService().showNotification(
        CustomNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: title,
          body: body,
          payload: message.data['analysisId'],
        ),
      );
    });
  }

  void _listenBackground() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNavigation(message);
    });
  }

  Future<void> handleInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message != null) {
      _handleNavigation(message);
    }
  }

  void _handleNavigation(RemoteMessage message) {
    final analysisId = message.data['analysisId'];

    if (analysisId != null) {
      NotificationService().onSelectNotificationFromFCM(analysisId);
    }
  }
}