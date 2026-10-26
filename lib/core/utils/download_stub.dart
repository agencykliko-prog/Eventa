import 'package:flutter/services.dart';

/// Hors navigateur (démo) : le contenu est copié dans le presse-papiers.
Future<bool> saveTextFile(String filename, String content) async {
  await Clipboard.setData(ClipboardData(text: content));
  return false;
}
