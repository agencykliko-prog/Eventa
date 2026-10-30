import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// La question peut-elle encore être posée ? (Faux si le navigateur ne gère
/// pas les notifications, par exemple Safari sur iPhone hors écran d'accueil.)
Future<bool> canAskNotifications() async {
  try {
    return web.Notification.permission == 'default';
  } catch (_) {
    return false;
  }
}

Future<bool> requestNotifications() async {
  try {
    final answer = await web.Notification.requestPermission().toDart;
    return answer.toDart == 'granted';
  } catch (_) {
    return false;
  }
}
