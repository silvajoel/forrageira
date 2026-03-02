import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:forrageira/screens/analysis_screen.dart';
import 'package:forrageira/screens/forgot_password_screen.dart';
import 'package:forrageira/screens/profile_screen.dart';
import 'package:forrageira/screens/register_screen.dart';
import 'package:forrageira/screens/reset_password_screen.dart';
import 'package:forrageira/screens/submit_analysis_screen.dart';
import 'package:forrageira/screens/main_screen.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'screens/admin/admin_login_page.dart';
import 'screens/admin/admin_dashboard_page.dart';
import 'screens/admin/admin_requests_page.dart';
import 'screens/admin/admin_request_detail_page.dart';
import 'screens/admin/admin_clients_page.dart';
import 'screens/admin/admin_history_page.dart';
import 'screens/admin/admin_species_page.dart';
import 'screens/admin/admin_settings_page.dart';

/// It is necessary to use Firebase.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Forrageira',
      theme: appTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/home': (context) => const MainScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgotpassword': (context) => const ForgotPasswordScreen(),
        '/submitanalysis': (context) => const SubmitAnalysisScreen(),
        '/analysis': (context) => const AnalysisScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/resetpassword': (context) => const ResetPasswordScreen(),
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