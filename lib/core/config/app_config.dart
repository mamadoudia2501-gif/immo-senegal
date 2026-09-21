/// Configuration compilée (pas de secrets dans le dépôt).
///
/// ```bash
/// flutter run \
///   --dart-define=SUPABASE_URL=https://zwjsnlcnyqhrtmhdjphb.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=<anon key from dashboard>
/// ```
///
/// La clé `service_role` ne doit **jamais** être passée à l’application.
/// Ne jamais coller la clé anon ici : uniquement `String.fromEnvironment`.
abstract final class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Force le mock local même si URL + anon key sont fournies.
  static const forceLocal = bool.fromEnvironment(
    'IMMO_FORCE_LOCAL',
    defaultValue: false,
  );

  static bool get isSupabaseConfigured =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;

  static bool get useSupabase => isSupabaseConfigured && !forceLocal;

  static BackendKind get kind =>
      useSupabase ? BackendKind.supabase : BackendKind.local;

  static String get backendLabel => switch (kind) {
    BackendKind.local => 'local (mock)',
    BackendKind.supabase => 'supabase (test)',
  };
}

enum BackendKind { local, supabase }
