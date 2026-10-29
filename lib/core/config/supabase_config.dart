/// Connexion au projet Supabase « eventa-prod ».
///
/// La clé publishable est conçue pour être embarquée côté client : la sécurité
/// repose sur les règles RLS de la base, pas sur le secret de cette clé.
/// Les deux valeurs peuvent être remplacées au build :
/// `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...`
abstract final class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://wszjcjmwenpzqvyixqds.supabase.co',
  );

  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_fRfVPiiBvhsYHc4e-d1rTw_lAWP1D5F',
  );
}
