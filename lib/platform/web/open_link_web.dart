import 'package:web/web.dart' as web;

/// Ouvre un lien (WhatsApp, e-mail, site) dans un nouvel onglet.
Future<bool> openLink(String url) async {
  web.window.open(url, url.startsWith('mailto:') ? '_self' : '_blank');
  return true;
}
