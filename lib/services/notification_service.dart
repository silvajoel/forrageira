import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:forrageira/services/i_forage_service.dart';

import 'navigation_service.dart';

class CustomNotification {
  final int id;
  final String? title;
  final String? body;
  final String? payload;

  CustomNotification({required this.id, this.title, this.body, this.payload});
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await _setupTimeZone();
    await _initializeNotifications();
  }

  Future<void> _setupTimeZone() async {
    tz_data.initializeTimeZones();
    try {
      final String timeZoneName =
          (await FlutterTimezone.getLocalTimezone()) as String;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  Future<void> _initializeNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await localNotificationsPlugin.initialize(
      settings: const InitializationSettings(android: android),
      onDidReceiveNotificationResponse: _onSelectNotification,
    );
  }

  void _onSelectNotification(NotificationResponse response) async {
    final payloadId = response.payload;
    if (payloadId == null || payloadId.isEmpty) return;
    await _openAnalysisFromPayload(payloadId);
  }

  Future<void> showNotification(CustomNotification notification) async {
    const androidDetails = AndroidNotificationDetails(
      'lembretes_notifications_x',
      'Lembretes',
      channelDescription: 'Este canal e para lembretes',
      importance: Importance.max,
      priority: Priority.high,
    );

    await localNotificationsPlugin.show(
      id: notification.id,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(android: androidDetails),
      payload: notification.payload,
    );
  }

  void onSelectNotificationFromFCM(String payloadId) async {
    await _openAnalysisFromPayload(payloadId);
  }

  Future<void> openAnalysisFromNotification(String payloadId) async {
    await _openAnalysisFromPayload(payloadId);
  }

  Future<void> _openAnalysisFromPayload(
    String payloadId, {
    int attempt = 0,
  }) async {
    if (payloadId.isEmpty) return;

    final context = navigatorKey.currentContext;
    if (context == null) {
      _retryOpenAnalysis(payloadId, attempt);
      return;
    }

    try {
      final forageService = Provider.of<IForageService>(context, listen: false);
      final analysis = await forageService
          .getById(payloadId)
          .timeout(const Duration(seconds: 8));

      if (mainScreenKey.currentState != null) {
        mainScreenKey.currentState!.openAnalysisDetail(analysis);
        return;
      }

      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/home',
        (route) => false,
      );

      await Future.delayed(const Duration(milliseconds: 800));
      final mainScreenState = mainScreenKey.currentState;
      if (mainScreenState == null) {
        _retryOpenAnalysis(payloadId, attempt);
        return;
      }

      mainScreenState.openAnalysisDetail(analysis);
    } catch (e) {
      if (attempt < 5) {
        _retryOpenAnalysis(payloadId, attempt);
        return;
      }

      debugPrint('Erro ao abrir analise pela notificacao: $e');
    }
  }

  void _retryOpenAnalysis(String payloadId, int attempt) {
    if (attempt >= 5) return;

    unawaited(
      Future.delayed(
        const Duration(milliseconds: 700),
        () => _openAnalysisFromPayload(payloadId, attempt: attempt + 1),
      ),
    );
  }
}
