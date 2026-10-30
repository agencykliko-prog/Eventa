import 'package:flutter/services.dart';

/// Hors navigateur (démo) : le lien est copié dans le presse-papiers.
Future<bool> openLink(String url) async {
  await Clipboard.setData(ClipboardData(text: url));
  return false;
}
