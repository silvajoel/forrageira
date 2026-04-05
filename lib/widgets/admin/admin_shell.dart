import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/user_service.dart';
import 'admin_sidebar.dart';
import 'admin_topbar.dart';

class AdminShell extends StatefulWidget {
  final Widget child;
  final String selectedMenu;
  final ValueChanged<String> onMenuSelected;
  final VoidCallback? onOpenSettings;

  const AdminShell({
    super.key,
    required this.child,
    required this.selectedMenu,
    required this.onMenuSelected,
    this.onOpenSettings,
  });

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final _auth = FirebaseAuth.instance;
  final _userService = UserService();

  User? _user;
  Future<Map<String, dynamic>?>? _profileFuture;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;

    if (_user != null) {
      _profileFuture = _userService.getProfile(_user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 980;

    if (_user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/admin-login',
              (route) => false,
        );
      });

      return const _AdminLoadingScaffold();
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: _profileFuture,
      builder: (context, profileSnapshot) {
        if (profileSnapshot.connectionState == ConnectionState.waiting) {
          return const _AdminLoadingScaffold();
        }

        final profile = profileSnapshot.data;
        final isAdmin = profile?['role'] == 'admin';
        final isActive = profile?['active'] == true;

        if (!isAdmin || !isActive) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await _auth.signOut();
            if (!mounted) return;
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/admin-login',
                  (route) => false,
            );
          });

          return const _AdminLoadingScaffold();
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF2F4F6),
          appBar: AdminTopBar(
            onOpenSettings: widget.onOpenSettings,
          ),
          drawer: isDesktop
              ? null
              : Drawer(
            child: AdminSidebar(
              selected: widget.selectedMenu,
              onSelect: (menu) {
                Navigator.of(context).pop();
                widget.onMenuSelected(menu);
              },
            ),
          ),
          body: Row(
            children: [
              if (isDesktop)
                AdminSidebar(
                  selected: widget.selectedMenu,
                  onSelect: widget.onMenuSelected,
                ),
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

class _AdminLoadingScaffold extends StatelessWidget {
  const _AdminLoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF2F4F6),
      body: Center(child: CircularProgressIndicator()),
    );
  }
}