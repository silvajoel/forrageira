// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void showWebForegroundNotification(String title, String? body) {
  if (!html.Notification.supported) return;

  final permission = html.Notification.permission;

  if (permission == 'granted') {
    _show(title, body);
  } else if (permission != 'denied') {
    html.Notification.requestPermission().then((perm) {
      if (perm == 'granted') _show(title, body);
    });
  }
}

void _show(String title, String? body) {
  html.Notification(
    title,
    body: body ?? '',
    icon: '/icons/Icon-192.png',
  );
}