/// Fill these in once the Supabase project is created
/// (Project Settings → API → Project URL / anon public key).
class SupabaseConfig {
  static const String url = "https://xdwlhmuhqsndkimejlvi.supabase.co";
  static const String anonKey =
      "sb_publishable_sEVXsY00uPPRJMdJ3_WXhQ_w_kqG1gj";

  static const String ingredientsTable = "ingredients";

  /// Deep link the Google OAuth flow redirects back to. Must match the
  /// scheme/host registered in AndroidManifest.xml and be added as a
  /// Redirect URL in Supabase Auth settings once Google sign-in is
  /// configured there.
  static const String oauthRedirect = "fridge2table://login-callback/";

  static bool get isConfigured =>
      url != "https://your-project.supabase.co" && anonKey != "your-anon-key";
}
