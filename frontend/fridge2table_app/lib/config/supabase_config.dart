/// Fill these in once the Supabase project is created
/// (Project Settings → API → Project URL / anon public key).
class SupabaseConfig {
  static const String url = "https://your-project.supabase.co";
  static const String anonKey = "your-anon-key";

  static const String ingredientsTable = "ingredients";

  static bool get isConfigured =>
      url != "https://your-project.supabase.co" && anonKey != "your-anon-key";
}
