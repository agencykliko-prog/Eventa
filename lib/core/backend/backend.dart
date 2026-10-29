import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Accès au projet Supabase. [ready] passe à vrai une fois le client
/// initialisé (main) ; les tests et le mode démo s'en passent.
abstract final class Backend {
  static bool ready = false;

  static SupabaseClient get client => Supabase.instance.client;

  /// Adresse de retour des e-mails (confirmation, mot de passe) : la page
  /// de l'app, sans le fragment de route.
  static String? get redirectUrl =>
      kIsWeb ? Uri.base.toString().split('#').first : null;
}

/// Identifiant UUID v4, généré côté app pour pouvoir créer un événement et
/// ses tâches en une fois, sans attendre les identifiants du serveur.
String newUuid() {
  final r = math.Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  String hex(int from, int to) =>
      [for (final x in b.sublist(from, to)) x.toRadixString(16).padLeft(2, '0')]
          .join();
  return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
}
