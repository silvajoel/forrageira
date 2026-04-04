import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/user_service.dart';
import 'admin/admin_dashboard_page.dart';
import 'admin/admin_login_page.dart';
import 'login_screen.dart';
import 'main_screen.dart';

class AppBootstrapPage extends StatelessWidget {
  const AppBootstrapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _BootstrapScaffold();
        }

        final user = authSnapshot.data;

        if (user == null) {
          return kIsWeb ? const AdminLoginPage() : const LoginScreen();
        }

        return FutureBuilder<Map<String, dynamic>?>(
          future: UserService().getProfile(user.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _BootstrapScaffold();
            }

            final profile = profileSnapshot.data;

            if (profile == null) {
              return _AccessDeniedPage(
                title: 'Perfil não encontrado',
                message:
                'Sua conta foi autenticada, mas o cadastro correspondente não foi localizado no banco.',
                actionLabel: 'Sair',
                onAction: () => FirebaseAuth.instance.signOut(),
              );
            }

            final role = (profile['role'] ?? '').toString().toLowerCase();
            final isActive = profile['active'] == true;

            if (!isActive) {
              return _AccessDeniedPage(
                title: 'Conta inativa',
                message:
                'Seu acesso está desativado no momento. Procure o administrador do sistema.',
                actionLabel: 'Sair',
                onAction: () => FirebaseAuth.instance.signOut(),
              );
            }

            if (kIsWeb) {
              if (role == 'admin') {
                return const AdminDashboardPage();
              }

              return _AccessDeniedPage(
                title: 'Acesso restrito',
                message:
                'O painel web é destinado apenas a administradores. Entre com uma conta admin ou use o app do usuário.',
                actionLabel: 'Sair',
                onAction: () => FirebaseAuth.instance.signOut(),
              );
            }

            if (role == 'admin') {
              return _AccessDeniedPage(
                title: 'Conta administrativa',
                message:
                'Essa conta é administrativa e deve acessar o painel web, não o aplicativo mobile.',
                actionLabel: 'Sair',
                onAction: () => FirebaseAuth.instance.signOut(),
              );
            }

            return const MainScreen();
          },
        );
      },
    );
  }
}

class _BootstrapScaffold extends StatelessWidget {
  const _BootstrapScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF2F4F6),
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _AccessDeniedPage extends StatelessWidget {
  final String title;
  final String message;
  final String actionLabel;
  final Future<void> Function() onAction;

  const _AccessDeniedPage({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F6),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 44,
                    color: Color(0xFF1F5B3F),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black87,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () async {
                        await onAction();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F5B3F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(actionLabel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
