import 'package:flutter/material.dart';

import '../constants/colors.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const List<(String, String)> _sections = [
    (
      "1. About this policy",
      "Fridge2Table is a Final Year Project (FYP) — a student-built app, "
          "not a commercial product. This policy explains what data the "
          "app collects and how it's used, written plainly rather than as "
          "formal legal text.",
    ),
    (
      "2. Information we collect",
      "When you create an account: your name and email address. When you "
          "use the app: the ingredients you add to your pantry, cooking "
          "history, and diet/allergy preferences you set. Photos you "
          "capture for AI ingredient detection.",
    ),
    (
      "3. How your data is stored",
      "Your pantry data lives in a local database on your own device by "
          "default. If you're signed in, it can optionally sync to a cloud "
          "database (Supabase) so it carries over between devices or a "
          "reinstall — this only happens for your account, kept separate "
          "from every other user's data.",
    ),
    (
      "4. Camera and AI detection",
      "Photos you take for ingredient scanning are processed entirely on "
          "your device using a local machine learning model. They are not "
          "uploaded to any server, stored after processing, or shared with "
          "anyone.",
    ),
    (
      "5. Data sharing",
      "We do not sell or share your personal data with third parties. "
          "Supabase is used only as our cloud database and sign-in "
          "provider to enable optional sync — it processes data on our "
          "behalf and doesn't use it for its own purposes.",
    ),
    (
      "6. Your control over your data",
      "You can clear your locally stored pantry data at any time from "
          "Settings. Signing out stops cloud sync; deleting your account "
          "removes your data from the cloud database.",
    ),
    (
      "7. Changes to this policy",
      "As a student project, this app and this policy may change as "
          "features are added during development.",
    ),
    (
      "8. Contact",
      "Questions about how your data is handled? Reach out at "
          "nerdbook52@gmail.com.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildTopBar(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Last updated: 2026",
                    style: TextStyle(color: AppColors.textGray, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  for (final section in _sections) ...[
                    _sectionCard(title: section.$1, body: section.$2),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.darkGreen,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 48, 12, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
              child: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
            ),
          ),
          const Expanded(
            child: Text(
              "Privacy Policy",
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: "Outfit", fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required String body}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(color: AppColors.textGray, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
