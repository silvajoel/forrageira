import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'admin/admin_home_page.dart';
import 'admin/admin_login_page.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import '../services/navigation_service.dart';

class AppBootstrapPage extends StatefulWidget {
  const AppBootstrapPage({super.key});

  @override
  State<AppBootstrapPage> createState() => _AppBootstrapPageState();
}

class _AppBootstrapPageState extends State<AppBootstrapPage> {
  late final Future<bool> _lastKnownSessionFuture;

  @override
  void initState() {
    super.initState();
    _lastKnownSessionFuture = AuthService.getLastKnownAuthenticatedUser();
  }

  Future<Map<String, dynamic>?> _loadProfile(String uid) async {
    try {
      return await UserService().getProfileWithRetry(uid).timeout(
            const Duration(seconds: 6),
          );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cachedUser = FirebaseAuth.instance.currentUser;

    return FutureBuilder<bool>(
      future: _lastKnownSessionFuture,
      builder: (context, sessionSnapshot) {
        final hadKnownSession = sessionSnapshot.data ?? false;

        return StreamBuilder<User?>(
          initialData: cachedUser,
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, authSnapshot) {
            final user = authSnapshot.data ?? cachedUser;
            final canOpenOffline = !kIsWeb && (user != null || hadKnownSession);

            if (authSnapshot.connectionState == ConnectionState.waiting &&
                !canOpenOffline) {
              return const _BootstrapScaffold();
            }

            if (user == null && hadKnownSession && !kIsWeb) {
              return MainScreen(key: mainScreenKey);
            }

            if (user == null) {
              return kIsWeb ? const AdminLoginPage() : const LoginScreen();
            }

            if (!kIsWeb &&
                authSnapshot.connectionState == ConnectionState.waiting) {
              return MainScreen(key: mainScreenKey);
            }

            return FutureBuilder<Map<String, dynamic>?>(
              future: _loadProfile(user.uid),
              builder: (context, profileSnapshot) {
                if (profileSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  if (!kIsWeb) {
                    return MainScreen(key: mainScreenKey);
                  }
                  return const _BootstrapScaffold();
                }

                final profile = profileSnapshot.data;

                if (!kIsWeb && profile == null) {
                  return MainScreen(key: mainScreenKey);
                }

                if (profile == null) {
                  return _AccessDeniedPage(
                    title: 'Perfil n\u00e3o encontrado',
                    message:
                        'Sua conta foi autenticada, mas o cadastro correspondente n\u00e3o foi localizado no banco.',
                    actionLabel: 'Sair',
                    onAction: () => FirebaseAuth.instance.signOut(),
                  );
                }

                final role = UserService.roleValue(profile) ?? '';
                final isActive = UserService.isProfileActive(profile);

                if (!isActive) {
                  return _AccessDeniedPage(
                    title: 'Conta inativa',
                    message:
                        'Seu acesso est\u00e1 desativado no momento. Procure o administrador do sistema.',
                    actionLabel: 'Sair',
                    onAction: () => FirebaseAuth.instance.signOut(),
                  );
                }

                if (kIsWeb) {
                  if (role == 'admin') {
                    return const AdminHomePage();
                  }

                  return _AccessDeniedPage(
                    title: 'Acesso restrito',
                    message:
                        'O painel web \u00e9 destinado apenas a administradores. Entre com uma conta admin ou use o app do usu\u00e1rio.',
                    actionLabel: 'Sair',
                    onAction: () => FirebaseAuth.instance.signOut(),
                  );
                }

                if (role == 'admin') {
                  return _AccessDeniedPage(
                    title: 'Conta administrativa',
                    message:
                        'Essa conta \u00e9 administrativa e deve acessar o painel web, n\u00e3o o aplicativo mobile.',
                    actionLabel: 'Sair',
                    onAction: () => FirebaseAuth.instance.signOut(),
                  );
                }

                return MainScreen(key: mainScreenKey);
              },
            );
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
