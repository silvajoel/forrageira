import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_service.dart';
import 'admin_sidebar.dart';
import 'admin_topbar.dart';

/// Carrega o perfil uma vez por [uid] (evita novo `get`/`snapshots` a cada rebuild do pai).
class _AdminProfileGate extends StatefulWidget {
  final String uid;
  final String selectedMenu;
  final Widget child;

  const _AdminProfileGate({
    super.key,
    required this.uid,
    required this.selectedMenu,
    required this.child,
  });

  @override
  State<_AdminProfileGate> createState() => _AdminProfileGateState();
}

class _AdminProfileGateState extends State<_AdminProfileGate> {
  final _userService = UserService();
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _profileStream;

  @override
  void initState() {
    super.initState();
    _profileStream = _userService.streamProfile(widget.uid);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _profileStream,
      builder: (context, profileSnapshot) {
        if (profileSnapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFFF2F4F6),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Color(0xFFC62828)),
                    const SizedBox(height: 12),
                    const Text(
                      'Não foi possível carregar o perfil.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      profileSnapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Confira a conexão e as regras do Firestore para users/{uid}.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (profileSnapshot.connectionState == ConnectionState.waiting &&
            !profileSnapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFFF2F4F6),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final doc = profileSnapshot.data;
        if (doc == null || !doc.exists) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await FirebaseAuth.instance.signOut();
            if (context.mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/admin-login',
                (route) => false,
              );
            }
          });

          return const Scaffold(
            backgroundColor: Color(0xFFF2F4F6),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final profile = doc.data();
        if (profile == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await FirebaseAuth.instance.signOut();
            if (context.mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/admin-login',
                (route) => false,
              );
            }
          });

          return const Scaffold(
            backgroundColor: Color(0xFFF2F4F6),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isAdmin = UserService.isAdminRole(profile);
        final isActive = UserService.isProfileActive(profile);

        if (!isAdmin || !isActive) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await FirebaseAuth.instance.signOut();
            if (context.mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/admin-login',
                (route) => false,
              );
            }
          });

          return const Scaffold(
            backgroundColor: Color(0xFFF2F4F6),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isDesktop = MediaQuery.of(context).size.width >= 980;

        return Scaffold(
          backgroundColor: const Color(0xFFF2F4F6),
          appBar: const AdminTopBar(),
          drawer: isDesktop
              ? null
              : Drawer(child: AdminSidebar(selected: widget.selectedMenu)),
          body: Row(
            children: [
              if (isDesktop) AdminSidebar(selected: widget.selectedMenu),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: widget.child,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AdminShell extends StatelessWidget {
  final Widget child;
  final String selectedMenu;

  const AdminShell({
    super.key,
    required this.child,
    required this.selectedMenu,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF2F4F6),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnapshot.data;

        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/admin-login',
                (route) => false,
              );
            }
          });

          return const Scaffold(
            backgroundColor: Color(0xFFF2F4F6),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return _AdminProfileGate(
          key: ValueKey<String>(user.uid),
          uid: user.uid,
          selectedMenu: selectedMenu,
          child: child,
        );
      },
    );
  }
}
