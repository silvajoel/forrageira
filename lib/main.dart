import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  try {
    await fcmService.init();
  } catch (e, stackTrace) {
    debugPrint('Falha ao inicializar FCM: $e');
    debugPrintStack(stackTrace: stackTrace);
  }

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Forrageira',
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
