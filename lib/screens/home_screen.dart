import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:forrageira/models/analysis_request.dart';
import 'package:forrageira/models/app_notification.dart';
import 'package:forrageira/services/app_notification_service.dart';
import 'package:forrageira/screens/main_screen.dart';
import 'package:forrageira/services/auth_service.dart';
import 'package:forrageira/services/i_forage_service.dart';
import 'package:forrageira/services/user_service.dart';
import 'package:provider/provider.dart';
import '../widgets/analysis_item.dart';
import '../widgets/notifications_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _statusLabel(String status) {
    switch (status) {
      case 'pending':   return 'Em análise';
      case 'completed': return 'Finalizado';
      default:          return 'Desconhecido';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return "${date.hour}:${date.minute.toString().padLeft(2, '0')} "
        "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final theme         = Theme.of(context);
    final authService   = context.watch<AuthService>();
    final forageService = context.read<IForageService>();

    final user     = authService.currentUser;
    final username = user?.displayName ?? "Usuário";
    final userId   = user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.grass),
            SizedBox(width: 8),
            Text('Forrageiras'),
          ],
        ),
        actions: [
          if (userId.isNotEmpty)
            _NotificationBellButton(userId: userId),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.grass, size: 40),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Bem-vindo, $username!",
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Veja suas análises recentes abaixo.",
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Minhas Análises',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            final mainScreen =
                            context.findAncestorStateOfType<MainScreenState>();
                            mainScreen?.setIndex(1);
                          },
                          child: const Text("Ver todas"),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            StreamBuilder<List<AnalysisRequest>>(
              stream: forageService.watchUserForages(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text("Nenhuma análise enviada ainda."),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final item = items[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AnalysisItem(
                            title: item.name,
                            date: _formatDate(item.createdAt),
                            status: _statusLabel(item.status),
                            coverImageUrl: item.imageUrls.isNotEmpty
                                ? item.imageUrls.first
                                : null,
                            onTap: () {
                              final mainScreen =
                              context.findAncestorStateOfType<MainScreenState>();
                              mainScreen?.openAnalysisDetail(item);
                            },
                          ),
                        );
                      },
                      childCount: items.length,
                    ),
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }
}

/// Contador de não lidas (inclui notificações de papel admin) + SnackBar ao chegar nova.
class _NotificationBellButton extends StatefulWidget {
  final String userId;

  const _NotificationBellButton({required this.userId});

  @override
  State<_NotificationBellButton> createState() => _NotificationBellButtonState();
}

class _NotificationBellButtonState extends State<_NotificationBellButton> {
  final _service = AppNotificationService();
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;
  final List<StreamSubscription<List<AppNotification>>> _notifSubs = [];

  int _unread = 0;
  int? _prevUnread;
  late final DateTime _allowToastAfter;

  @override
  void initState() {
    super.initState();
    _allowToastAfter = DateTime.now().add(const Duration(seconds: 3));
    _profileSub = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .snapshots()
        .listen(_onProfile);
  }

  void _onProfile(DocumentSnapshot<Map<String, dynamic>> snap) {
    for (final s in _notifSubs) {
      s.cancel();
    }
    _notifSubs.clear();

    final profile = snap.data();
    final isAdmin = UserService.isAdminRole(profile);

    var userItems = <AppNotification>[];
    var adminItems = <AppNotification>[];

    void emit() {
      final merged = isAdmin ? [...userItems, ...adminItems] : userItems;
      final unread = merged.where((n) => !n.read).length;
      final prev = _prevUnread;
      final showToast = prev != null &&
          unread > prev &&
          DateTime.now().isAfter(_allowToastAfter);
      if (!mounted) return;
      setState(() {
        _prevUnread = unread;
        _unread = unread;
      });
      if (showToast && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Você tem novas notificações.'),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Abrir',
                onPressed: () {
                  showNotificationsModal(context);
                },
              ),
            ),
          );
        });
      }
    }

    _notifSubs.add(
      _service.watchUserNotifications(userId: widget.userId).listen((list) {
        userItems = list;
        emit();
      }),
    );
    if (isAdmin) {
      _notifSubs.add(
        _service.watchAdminRoleNotifications().listen((list) {
          adminItems = list;
          emit();
        }),
      );
    } else {
      adminItems = [];
    }
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    for (final s in _notifSubs) {
      s.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Notificações',
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_none),
          if (_unread > 0)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  _unread > 99 ? '99+' : '$_unread',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      onPressed: () => showNotificationsModal(context),
    );
  }
}