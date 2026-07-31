import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../services/api_service.dart';
import '../services/app_settings_service.dart';
import 'cloud_sync_screen.dart';
import 'privacy_screen.dart';
import 'terms_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _expiryAlerts = true;
  bool _recipeSuggestions = true;
  final bool _darkMode = false;
  bool _clearing = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationsToggle();
  }

  Future<void> _loadNotificationsToggle() async {
    final notificationsEnabled =
        await AppSettingsService.getNotificationsEnabled();
    final recipeSuggestionsEnabled =
        await AppSettingsService.getRecipeSuggestionsEnabled();
    if (mounted) {
      setState(() {
        _pushNotifications = notificationsEnabled;
        _recipeSuggestions = recipeSuggestionsEnabled;
      });
    }
  }

  void _showHelp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Manage notifications, appearance, and your data."),
      ),
    );
  }

  void _openCloudSync() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CloudSyncScreen()),
    );
  }

  void _openTerms() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TermsScreen()),
    );
  }

  void _openPrivacy() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PrivacyScreen()),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmClearData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Clear all pantry data?"),
        content: const Text(
          "This permanently deletes every ingredient in your pantry. This cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              "Clear Data",
              style: TextStyle(color: Color(0xFFC0392B)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _clearing = true);
    try {
      final items = await ApiService.getInventory();
      for (final item in items) {
        if (item.id != null) {
          await ApiService.deleteIngredient(item.id!);
        }
      }
      if (mounted) _showSnack("Pantry data cleared");
    } catch (_) {
      if (mounted) {
        _showSnack("Couldn't clear all data — check your connection");
      }
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                children: [
                  _sectionCard(
                    title: "Notifications",
                    children: [
                      _toggleRow(
                        "Push Notifications",
                        "All app alerts",
                        _pushNotifications,
                        (v) {
                          setState(() => _pushNotifications = v);
                          AppSettingsService.setNotificationsEnabled(v);
                        },
                      ),
                      _toggleRow(
                        "Expiry Alerts",
                        "Before items expire",
                        _expiryAlerts,
                        (v) => setState(() => _expiryAlerts = v),
                      ),
                      _toggleRow(
                        "Recipe Suggestions",
                        "Daily recommendations",
                        _recipeSuggestions,
                        (v) {
                          setState(() => _recipeSuggestions = v);
                          AppSettingsService.setRecipeSuggestionsEnabled(v);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _sectionCard(
                    title: "Appearance",
                    children: [
                      _toggleRow("Dark Mode", null, _darkMode, (v) {
                        _showSnack(
                          "Dark mode is coming in a future update. Stay tuned!",
                        );
                      }),
                      _navRow(
                        "Language",
                        "English",
                        () => _showSnack("More languages coming soon"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _sectionCard(
                    title: "Data & Privacy",
                    children: [
                      _navRow("Backup & Restore", "Auto", _openCloudSync),
                      _navRow("Terms of Service", null, _openTerms),
                      _navRow("Privacy Policy", null, _openPrivacy),
                      _navRow(
                        "Clear Data",
                        null,
                        _clearing ? null : _confirmClearData,
                        destructive: true,
                        trailing: _clearing
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Fridge2Table v1.0.0",
                    style: TextStyle(color: AppColors.textGray, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "FYP Project · 2026",
                    style: TextStyle(color: AppColors.textGray, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
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
              "Settings",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "Outfit",
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
          GestureDetector(
            onTap: _showHelp,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.help_outline,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textGray,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (int i = 0; i < children.length; i++)
            Container(
              decoration: i == children.length - 1
                  ? null
                  : const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.borderGreen),
                      ),
                    ),
              child: children[i],
            ),
        ],
      ),
    );
  }

  Widget _toggleRow(
    String title,
    String? subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textGray,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.darkGreen,
          ),
        ],
      ),
    );
  }

  Widget _navRow(
    String title,
    String? value,
    VoidCallback? onTap, {
    bool destructive = false,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: destructive
                      ? const Color(0xFFC0392B)
                      : AppColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (trailing != null)
              trailing
            else ...[
              if (value != null) ...[
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Icon(
                Icons.chevron_right,
                size: 15,
                color: destructive
                    ? const Color(0xFFC0392B)
                    : AppColors.textGray,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
