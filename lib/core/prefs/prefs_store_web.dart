import 'package:web/web.dart' as web;

/// Navigateur : préférences conservées dans le stockage local.
String? readPref(String key) {
  try {
    return web.window.localStorage.getItem('eventa.$key');
  } catch (_) {
    return null;
  }
}

void writePref(String key, String value) {
  try {
    web.window.localStorage.setItem('eventa.$key', value);
  } catch (_) {}
}
