import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'package:forrageira/screens/forgot_password_screen.dart';
import 'package:forrageira/screens/main_screen.dart';
import 'package:forrageira/screens/profile_screen.dart';
import 'package:forrageira/screens/register_screen.dart';
import 'package:forrageira/screens/submit_analysis_screen.dart';
import 'package:forrageira/services/auth_service.dart';
import 'package:forrageira/services/fcm_service.dart';
import 'package:forrageira/services/forage_service.dart';
import 'package:forrageira/services/i_forage_service.dart';
import 'package:forrageira/services/location_service.dart';
import 'package:forrageira/services/notification_service.dart';
import 'package:forrageira/services/pending_analysis_queue_service.dart';
import 'package:forrageira/services/plesk_image_storage_service.dart';
import 'package:forrageira/screens/admin/reset_password_page.dart';

import 'firebase_options.dart';
import 'screens/admin/admin_home_page.dart';
import 'screens/admin/admin_login_page.dart';
import 'screens/app_bootstrap_page.dart';
import 'services/navigation_service.dart';
import 'theme/app_theme.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('Background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  final notificationService = NotificationService();
  if (!kIsWeb) {
    try {
      await notificationService.init();
    } catch (e, stackTrace) {
      debugPrint('Falha ao inicializar notificacoes locais: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  final fcmService = FCMService();
  unawaited(_initFcmInBackground(fcmService));

  runApp(
    MultiProvider(
      providers: [
        Provider<NotificationService>.value(value: notificationService),
        Provider<FCMService>.value(value: fcmService),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider<IForageService>(
          create: (_) => ForageService(),
        ),
        ChangeNotifierProvider(create: (_) => PendingAnalysisQueueService()),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> _initFcmInBackground(FCMService fcmService) async {
  try {
    await fcmService.init().timeout(const Duration(seconds: 8));
  } catch (e, stackTrace) {
    debugPrint('Falha ao inicializar FCM em segundo plano: $e');
    debugPrintStack(stackTrace: stackTrace);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Que capim é esse?',
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: appTheme,
      home: const AppBootstrapPage(),
      routes: {
        '/home': (context) => MainScreen(key: mainScreenKey),
        '/register': (context) => const RegisterScreen(),
        '/forgotpassword': (context) => const ForgotPasswordScreen(),
        '/submitanalysis': (context) => SubmitAnalysisScreen(
              locationService: LocationService(),
              imageStorageService: const PleskImageStorageService(),
            ),
        '/profile': (context) => const ProfileScreen(),
        '/admin-login': (context) => const AdminLoginPage(),
        '/reset-password': (context) => const ResetPasswordPage(),
        '/admin': (context) => const AdminHomePage(),
      },
    );
  }
}
