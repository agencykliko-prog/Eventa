import 'package:permission_handler/permission_handler.dart';

/// La question peut-elle encore être posée ? (Faux hors téléphone.)
Future<bool> canAskNotifications() async {
  try {
    return (await Permission.notification.status).isDenied;
  } catch (_) {
    return false;
  }
}

Future<bool> requestNotifications() async {
  try {
    return (await Permission.notification.request()).isGranted;
  } catch (_) {
    return false;
  }
}
