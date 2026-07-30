import 'package:flutter/material.dart';

import '../constants/colors.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const List<(String, String)> _sections = [
    (
      "1. About this app",
      "Fridge2Table is a Final Year Project (FYP) built for academic "
          "purposes — a student-developed pantry tracker, AI ingredient "
          "scanner, and recipe recommender. It is not a commercial product, "
          "and these terms are written in that spirit rather than as a "
          "formal legal contract.",
    ),
    (
      "2. Creating an account",
      "You need an account to save your pantry data and sync it across "
          "devices. Please provide a real email address and keep your "
          "password to yourself — you're responsible for anything that "
          "happens under your account.",
    ),
    (
      "3. Using the app",
      "Use Fridge2Table to track ingredients, scan food with your camera, "
          "and get recipe suggestions. Please don't try to abuse, "
          "reverse-engineer for malicious purposes, or overload the service.",
    ),
    (
      "4. AI ingredient detection isn't perfect",
      "The AI scanner is a machine learning model trained on a limited set "
          "of ingredient classes. It will sometimes misidentify or fail to "
          "recognize an item. Always double-check what the app detected "
          "before relying on it — especially if you have food allergies.",
    ),
    (
      "5. Not food safety advice",
      "Expiry reminders and recipe suggestions are conveniences, not food "
          "safety guarantees. Use your own judgment (and senses) about "
          "whether food is still good to eat.",
    ),
    (
      "6. Your data",
      "See the Privacy Policy for details on what's collected and how it's "
          "stored. In short: your pantry data lives on your device, with "
          "optional cloud sync via Supabase if you're signed in.",
    ),
    (
      "7. Changes",
      "As a student project, this app and these terms may change as new "
          "features are added during development.",
    ),
    (
      "8. Contact",
      "Questions about this project? Reach out at nerdbook52@gmail.com.",
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
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 48, 12, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
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
                size: 20,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              "Terms of Service",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "Outfit",
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Colors.white,
              ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: AppColors.textGray,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
