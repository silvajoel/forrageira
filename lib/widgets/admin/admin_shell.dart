import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_service.dart';
import 'admin_sidebar.dart';
import 'admin_topbar.dart';

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
    final isDesktop = MediaQuery.of(context).size.width >= 980;
    final userService = UserService();

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

        return FutureBuilder<Map<String, dynamic>?>(
          future: userService.getProfile(user.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Color(0xFFF2F4F6),
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final profile = profileSnapshot.data;
            final isAdmin = profile?['role'] == 'admin';
            final isActive = profile?['active'] == true;

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

            return Scaffold(
              backgroundColor: const Color(0xFFF2F4F6),
              appBar: const AdminTopBar(),
              drawer: isDesktop
                  ? null
                  : Drawer(child: AdminSidebar(selected: selectedMenu)),
              body: Row(
                children: [
                  if (isDesktop) AdminSidebar(selected: selectedMenu),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: child,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
