import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../constants/colors.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';
import 'diet_preferences_screen.dart';
import 'privacy_screen.dart';
import 'terms_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  bool _submitting = false;

  Future<void> _continue() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty) {
      _showError("Please fill in your name and email");
      return;
    }
    if (password.length < 8) {
      _showError("Password must be at least 8 characters");
      return;
    }
    if (password != confirmPassword) {
      _showError("Passwords don't match");
      return;
    }
    if (!SupabaseConfig.isConfigured) {
      _showError("Cloud account creation isn't configured yet");
      return;
    }

    setState(() => _submitting = true);
    SupabaseService.suppressRootAuthListener = true;

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {"name": name},
        emailRedirectTo: SupabaseConfig.oauthRedirect,
      );

      if (response.user == null) {
        _showError("Could not create account. Please try again.");
        return;
      }

      await AuthService.cacheIdentity(name: name, email: email);

      if (response.session == null) {
        // Email confirmation is required before the user can sign in —
        // there's no active session yet, so send them to Sign In instead
        // of straight into the app. A SnackBar is too easy to miss here,
        // so this is a blocking dialog the user has to acknowledge.
        if (!mounted) return;
        await _showCheckEmailDialog(email);
        if (!mounted) return;
        Navigator.pop(context);
        return;
      }

      // Signed up with an active session — pull down any existing cloud
      // data for this account before landing on preferences setup.
      unawaited(SupabaseService.resolveConflicts());

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DietPreferencesScreen()),
      );
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError("Something went wrong: $e");
    } finally {
      SupabaseService.suppressRootAuthListener = false;
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showCheckEmailDialog(String email) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.mark_email_unread_outlined,
          color: AppColors.darkGreen,
          size: 32,
        ),
        title: const Text("Check your email"),
        content: Text(
          "We've sent a confirmation link to $email. Open it, then come back "
          "and sign in.",
          textAlign: TextAlign.center,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Got it",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _continueWithGoogle() async {
    debugPrint(
      "[GoogleAuth] Sign up with Google tapped (CreateAccountScreen). "
      "isConfigured=${SupabaseConfig.isConfigured}",
    );
    if (!SupabaseConfig.isConfigured) {
      _showError("Cloud sign-in isn't configured yet");
      return;
    }
    debugPrint(
      "[GoogleAuth] Launching signInWithOAuth, redirectTo=${SupabaseConfig.oauthRedirect}",
    );
    try {
      final launched = await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: SupabaseConfig.oauthRedirect,
        authScreenLaunchMode: LaunchMode.inAppWebView,
      );
      debugPrint("[GoogleAuth] signInWithOAuth returned: $launched");
      if (!launched) {
        _showError("Couldn't open Google sign-in. Please try again.");
      }
      // On success the OAuth flow finishes in the browser/app-link
      // callback; the app-root listener in main.dart takes over from there.
    } on AuthException catch (e) {
      debugPrint("[GoogleAuth] AuthException: ${e.message} (code: ${e.code})");
      _showError(e.message);
    } catch (e) {
      debugPrint("[GoogleAuth] Unexpected error: $e");
      _showError("Google sign-in failed: $e");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                children: [
                  _buildFieldCard(
                    label: "FULL NAME",
                    icon: Icons.person_outline,
                    controller: _nameController,
                    hint: "Sarah Chen",
                    obscure: false,
                  ),

                  const SizedBox(height: 12),

                  _buildFieldCard(
                    label: "EMAIL ADDRESS",
                    icon: Icons.mail_outline,
                    controller: _emailController,
                    hint: "you@email.com",
                    obscure: false,
                  ),

                  const SizedBox(height: 12),

                  _buildFieldCard(
                    label: "PASSWORD",
                    icon: Icons.lock_outline,
                    controller: _passwordController,
                    hint: "Min. 8 characters",
                    obscure: _obscurePassword,
                    trailing: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18,
                        color: AppColors.textGray,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),

                  const SizedBox(height: 12),

                  _buildFieldCard(
                    label: "CONFIRM PASSWORD",
                    icon: Icons.lock_outline,
                    controller: _confirmPasswordController,
                    hint: "Repeat password",
                    obscure: _obscureConfirmPassword,
                    trailing: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18,
                        color: AppColors.textGray,
                      ),
                      onPressed: () => setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () =>
                            setState(() => _agreedToTerms = !_agreedToTerms),
                        child: Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: _agreedToTerms
                                ? AppColors.darkGreen
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.darkGreen.withValues(
                                alpha: 0.11,
                              ),
                            ),
                          ),
                          child: _agreedToTerms
                              ? const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textGray,
                              fontWeight: FontWeight.w600,
                            ),
                            children: [
                              const TextSpan(text: "I agree to the "),
                              TextSpan(
                                text: "Terms of Service",
                                style: const TextStyle(
                                  color: AppColors.darkGreen,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const TermsScreen(),
                                    ),
                                  ),
                              ),
                              const TextSpan(text: " and "),
                              TextSpan(
                                text: "Privacy Policy",
                                style: const TextStyle(
                                  color: AppColors.darkGreen,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const PrivacyScreen(),
                                    ),
                                  ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_agreedToTerms && !_submitting)
                          ? _continue
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkGreen,
                        disabledBackgroundColor: AppColors.darkGreen.withValues(
                          alpha: 0.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Create Account",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      const Expanded(
                        child: Divider(color: AppColors.borderGreen),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          "or",
                          style: TextStyle(
                            color: AppColors.textGray,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Divider(color: AppColors.borderGreen),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _continueWithGoogle,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        side: BorderSide(
                          color: AppColors.darkGreen.withValues(alpha: 0.11),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFEA4335), Color(0xFFFBBC04)],
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              "G",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Sign up with Google",
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Center(
                    child: GestureDetector(
                      // See the matching fix in signin_screen.dart — a bare
                      // TapGestureRecognizer only covers the exact glyph
                      // pixels of "Sign In", easy to miss with a real
                      // fingertip. This gives the whole line a much larger
                      // tap area.
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.pop(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(fontSize: 14),
                            children: [
                              TextSpan(
                                text: "Already have an account? ",
                                style: TextStyle(color: AppColors.textGray),
                              ),
                              TextSpan(
                                text: "Sign In",
                                style: TextStyle(
                                  color: AppColors.darkGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.darkGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 52, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_left,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Create account",
            style: TextStyle(
              fontFamily: "Outfit",
              fontWeight: FontWeight.w600,
              fontSize: 24,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Start reducing food waste today — it's free.",
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldCard({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textGray,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(icon, size: 17, color: AppColors.textGray),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: AppColors.textDark.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ],
      ),
    );
  }
}
