import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:forrageira/services/forage_service.dart';
import 'package:forrageira/services/i_forage_service.dart';
import 'package:forrageira/services/location_service.dart';
import 'package:forrageira/services/plesk_image_storage_service.dart';
import 'package:forrageira/widgets/auth_check.dart';
import 'package:provider/provider.dart';
import 'package:forrageira/screens/analysis_screen.dart';
import 'package:forrageira/screens/forgot_password_screen.dart';
import 'package:forrageira/screens/profile_screen.dart';
import 'package:forrageira/screens/register_screen.dart';
import 'package:forrageira/screens/submit_analysis_screen.dart';
import 'package:forrageira/screens/main_screen.dart';
import 'package:forrageira/services/auth_service.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'services/navigation_service.dart';

import 'screens/admin/admin_login_page.dart';
import 'screens/admin/admin_dashboard_page.dart';
import 'screens/admin/admin_requests_page.dart';
import 'screens/admin/admin_request_detail_page.dart';
import 'screens/admin/admin_clients_page.dart';
import 'screens/admin/admin_history_page.dart';
import 'screens/admin/admin_species_page.dart';
import 'screens/admin/admin_settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),

        // DIP: registrado pela abstração — screens dependem de IForageService
        ChangeNotifierProvider<IForageService>(
          create: (_) => ForageService(),
        ),
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
      home: AuthCheck(),
      routes: {
        '/home': (context) => const MainScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgotpassword': (context) => const ForgotPasswordScreen(),

        // SubmitAnalysisScreen exige injeção — não pode ser const
        '/submitanalysis': (context) => SubmitAnalysisScreen(
          locationService: LocationService(),
          imageStorageService: PleskImageStorageService(
          ),
        ),

        '/profile': (context) => const ProfileScreen(),

        '/admin-login': (context) => const AdminLoginPage(),
        '/admin': (context) => const AdminDashboardPage(),
        '/admin/requests': (context) => const AdminRequestsPage(),
        '/admin/request': (context) => const AdminRequestDetailPage(),
        '/admin/clients': (context) => const AdminClientsPage(),
        '/admin/history': (context) => const AdminHistoryPage(),
        '/admin/species': (context) => const AdminSpeciesPage(),
        '/admin/settings': (context) => const AdminSettingsPage(),
      },
    );
  }
}