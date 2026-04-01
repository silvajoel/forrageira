import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:provider/provider.dart';

// Ajuste estes imports para os caminhos reais do seu projeto
import 'package:forrageira/screens/main_screen.dart';
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
  // Singleton para garantir que só exista uma instância controlando o plugin
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // O segredo está em garantir que este método termine antes do runApp
  Future<void> init() async {
    await _setupTimeZone();
    await _initializeNotifications();
  }

  Future<void> _setupTimeZone() async {
    tz_data.initializeTimeZones();
    try {
      final String timeZoneName = (await FlutterTimezone.getLocalTimezone()) as String;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      // Fallback para evitar crash se o timezone do dispositivo for inválido
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

    // Aguarda o contexto estar disponível
    await Future.delayed(const Duration(milliseconds: 300));
    final context = navigatorKey.currentContext;
    if (context == null) return;

    try {
      final forageService = Provider.of<IForageService>(context, listen: false);
      final analysis = await forageService.getById(payloadId);

      final mainScreen = context.findAncestorStateOfType<MainScreenState>();

      if (mainScreen != null) {
        mainScreen.openAnalysisDetail(analysis);
      } else {
        navigatorKey.currentState?.pushNamedAndRemoveUntil('/home', (route) => false);

        await Future.delayed(const Duration(milliseconds: 800)); // Delay maior para garantir build

        final newContext = navigatorKey.currentContext;
        final newMainScreen = newContext?.findAncestorStateOfType<MainScreenState>();
        newMainScreen?.openAnalysisDetail(analysis);
      }
    } catch (e) {
      print("Erro ao processar clique: $e");
    }
  }

  Future<void> showNotification(CustomNotification notification) async {
    const androidDetails = AndroidNotificationDetails(
      'lembretes_notifications_x',
      'Lembretes',
      channelDescription: 'Este canal é para lembretes',
      importance: Importance.max,
      priority: Priority.high,
    );

    await localNotificationsPlugin.show(
      id: notification.id,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(android: androidDetails),
      payload: notification.payload,
    );
  }
}