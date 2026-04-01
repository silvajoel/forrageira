import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:forrageira/data/models.dart';
import 'package:forrageira/screens/main_screen.dart';
import 'package:forrageira/services/i_forage_service.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'navigation_service.dart';

class CustomNotification {
  final int id;
  final String? title;
  final String? body;
  final String? payload;

  CustomNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
  });
}

class NotificationService {
  late FlutterLocalNotificationsPlugin localNotificationsPlugin;
  late AndroidNotificationDetails androidNotificationDetails;

  NotificationService() {
    localNotificationsPlugin = FlutterLocalNotificationsPlugin();
    _setupNotifications();
  }

  _setupNotifications() async {
    await _setupTimeZone();
    await _initializeNotifications();
  }

  Future<void> _setupTimeZone() async {
    tz.initializeTimeZones();
    final String? timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName!));
  }

  _initializeNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    await localNotificationsPlugin.initialize(
      settings: const InitializationSettings(android: android),
      onDidReceiveNotificationResponse: _onSelectNotification,
    );
  }

  void _onSelectNotification(NotificationResponse response) async {
    final id = response.payload;

    if (id != null && id.isNotEmpty) {
      print('Notificação clicada! ID: $id');

      final context = navigatorKey.currentContext!;

      final forageService = context.read<IForageService>();

      final analysis = await forageService.getById(id);

      final mainScreen =
      context.findAncestorStateOfType<MainScreenState>();

      if (mainScreen != null) {
        mainScreen.openAnalysisDetail(analysis);
      } else {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/home',
              (route) => false,
        );

        await Future.delayed(const Duration(milliseconds: 300));

        final newContext = navigatorKey.currentContext;
        final newMainScreen =
        newContext?.findAncestorStateOfType<MainScreenState>();

        newMainScreen?.openAnalysisDetail(analysis);
      }
    }
  }
}