import 'dart:html' as html;

void showWebForegroundNotification(String title, String? body) {
  if (!html.Notification.supported) return;
  html.Notification.requestPermission().then((perm) {
    if (perm != 'granted') return;
    html.Notification(title, body: body ?? '');
  });
}
