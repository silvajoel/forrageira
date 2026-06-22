import 'dart:async';

import 'package:flutter/material.dart';
import 'package:forrageira/models/app_notification.dart';
import 'package:forrageira/services/app_notification_service.dart';
import 'package:forrageira/services/user_service.dart';
import 'package:forrageira/widgets/notifications_modal.dart';

class NotificationBellButton extends StatefulWidget {
  final String userId;

  const NotificationBellButton({
    super.key,
    required this.userId,
  });

  @override
  State<NotificationBellButton> createState() => _NotificationBellButtonState();
}

class _NotificationBellButtonState extends State<NotificationBellButton> {
  final _service = AppNotificationService();
  final _userService = UserService();
  StreamSubscription<Map<String, dynamic>?>? _profileSub;
  final List<StreamSubscription<List<AppNotification>>> _notifSubs = [];

  int _unread = 0;
  int? _prevUnread;
  late final DateTime _allowToastAfter;

  @override
  void initState() {
    super.initState();
    _allowToastAfter = DateTime.now().add(const Duration(seconds: 3));
    _profileSub =
        _userService.streamProfile(widget.userId).listen(_onProfile);
  }

  void _onProfile(Map<String, dynamic>? profile) {
    for (final subscription in _notifSubs) {
      unawaited(subscription.cancel());
    }
    _notifSubs.clear();

    final isAdmin = UserService.isAdminRole(profile);

    var userItems = <AppNotification>[];
    var adminItems = <AppNotification>[];

    void emit() {
      final merged = isAdmin ? [...userItems, ...adminItems] : userItems;
      final unread = merged.where((notification) => !notification.read).length;
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
                onPressed: () => showNotificationsModal(context),
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
    unawaited(_profileSub?.cancel());
    for (final subscription in _notifSubs) {
      unawaited(subscription.cancel());
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
