import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../data/allergy_severities.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'cloud_sync_screen.dart';
import 'diet_preferences_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';
import 'waste_control_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int? _itemCount;

  String _name = "Guest";
  String? _email;
  String? _memberSince;
  List<String> _dietTags = [];
  List<String> _allergyNames = [];

  static const List<String> _months = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December",
  ];

  @override
  void initState() {
    super.initState();
    _loadItemCount();
    _loadProfile();
  }

  Future<void> _loadItemCount() async {
    try {
      final items = await ApiService.getInventory();
      if (mounted) setState(() => _itemCount = items.length);
    } catch (_) {
      // Falls back to "—" below.
    }
  }

  Future<void> _loadProfile() async {
    final name = await AuthService.getName();
    final email = await AuthService.getEmail();
    final createdAt = await AuthService.getCreatedAt();
    final diet = await AuthService.getDietPreferences();
    final allergies = await AuthService.getAllergies();

    if (!mounted) return;
    setState(() {
      _name = (name != null && name.isNotEmpty) ? name : "Guest";
      _email = email;
      _memberSince = createdAt == null
          ? null
          : "Member since ${_months[createdAt.month - 1]} ${createdAt.year}";
      _dietTags = diet;
      _allergyNames = allergies;
    });
  }

  String get _initials {
    final trimmed = _name.trim();
    if (trimmed.isEmpty || trimmed == "Guest") return "?";
    final words = trimmed.split(RegExp(r"\s+"));
    if (words.length == 1) {
      return words[0].substring(0, words[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  void _editPreferences() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DietPreferencesScreen()),
    );
  }

  void _logOut() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Log out?"),
        content: const Text("You'll need to sign in again to access your pantry."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text("Log Out", style: TextStyle(color: Color(0xFFC0392B))),
          ),
        ],
      ),
    );
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                children: [
                  _statsRow(),
                  const SizedBox(height: 16),
                  _dietPreferencesCard(),
                  const SizedBox(height: 16),
                  _allergiesCard(),
                  const SizedBox(height: 16),
                  _accountCard(),
                  const SizedBox(height: 16),
                  _logOutButton(),
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
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "My Profile",
                style: TextStyle(fontFamily: "Outfit", fontWeight: FontWeight.w800, fontSize: 22, color: Colors.white),
              ),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
                  child: const Icon(Icons.settings_outlined, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(_initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 26)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_name, style: const TextStyle(fontFamily: "Outfit", fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(_email ?? "No email set", style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
                    if (_memberSince != null) ...[
                      const SizedBox(height: 2),
                      Text(_memberSince!, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statsRow() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Expanded(child: _statItem(_itemCount?.toString() ?? "—", "Items")),
          Expanded(child: _statItem("78", "Eco Score")),
          Expanded(child: _statItem("3", "Badges")),
          Expanded(child: _statItem("11", "Rescued")),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontFamily: "Outfit", fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.textDark)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppColors.textGray, fontSize: 11)),
      ],
    );
  }

  Widget _dietPreferencesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text("Diet Preferences", style: TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.bold))),
              GestureDetector(
                onTap: _editPreferences,
                child: const Text("Edit", style: TextStyle(color: AppColors.darkGreen, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_dietTags.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text("No diet preferences set yet", style: TextStyle(color: AppColors.textGray, fontSize: 12)),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in _dietTags) _pill(tag, AppColors.chipGreenBg, AppColors.chipGreenText),
              GestureDetector(
                onTap: _editPreferences,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.darkGreen.withValues(alpha: 0.2)),
                  ),
                  child: const Text("+ Add", style: TextStyle(color: AppColors.darkGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _allergiesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text("Food Allergies", style: TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.bold))),
              GestureDetector(
                onTap: _editPreferences,
                child: const Text("Edit", style: TextStyle(color: AppColors.darkGreen, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_allergyNames.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text("No allergies set yet", style: TextStyle(color: AppColors.textGray, fontSize: 12)),
            )
          else
            for (final name in _allergyNames) ...[
              _allergyRow(name, allergySeverities[name] ?? "Common"),
              const SizedBox(height: 10),
            ],
          const Divider(color: AppColors.borderGreen, height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.textGray),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Recipes containing these will show a warning before you cook.",
                  style: const TextStyle(color: AppColors.textGray, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _allergyRow(String name, String severity) {
    final color = severity == "Severe" ? const Color(0xFFC0392B) : const Color(0xFFD68910);
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Expanded(child: Text(name, style: const TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.w600))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(999)),
          child: Text(severity, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _accountCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Account", style: TextStyle(color: AppColors.textGray, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
          _accountRow(
            icon: Icons.bar_chart,
            title: "Statistics",
            subtitle: "Food saved, trends",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatisticsScreen())),
          ),
          _accountRow(
            icon: Icons.eco_outlined,
            title: "Waste Control",
            subtitle: "Regrow & scrap guides",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WasteControlScreen())),
          ),
          _accountRow(
            icon: Icons.cloud_outlined,
            title: "Cloud Sync",
            subtitle: "Backup & multi-device",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CloudSyncScreen())),
          ),
          _accountRow(
            icon: Icons.settings_outlined,
            title: "Settings",
            subtitle: "Notifications, appearance",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          _accountRow(
            icon: Icons.help_outline,
            title: "Help & Support",
            subtitle: "FAQs and contact",
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Help & Support coming soon")),
            ),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _accountRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: isLast
            ? null
            : const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderGreen))),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 17, color: AppColors.darkGreen),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(subtitle, style: const TextStyle(color: AppColors.textGray, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 15, color: AppColors.textGray),
          ],
        ),
      ),
    );
  }

  Widget _logOutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _logOut,
        icon: const Icon(Icons.logout, size: 17, color: Color(0xFFC0392B)),
        label: const Text("Log Out", style: TextStyle(color: Color(0xFFC0392B), fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Color(0xFFC0392B)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
