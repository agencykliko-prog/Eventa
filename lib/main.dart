import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/backend/backend.dart';
import 'core/config/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  await initializeDateFormatting('en_US');
  // Sans réseau ou sans projet joignable, l'app reste utilisable en démo.
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
    Backend.ready = true;
  } catch (e) {
    debugPrint('Supabase indisponible : $e');
  }
  runApp(const ProviderScope(child: EventaApp()));
}
