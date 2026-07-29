import 'package:flutter/material.dart';

import '../config/supabase_config.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';
import '../services/app_settings_service.dart';
import '../services/supabase_service.dart';

class CloudSyncScreen extends StatefulWidget {
  const CloudSyncScreen({super.key});

  @override
  State<CloudSyncScreen> createState() => _CloudSyncScreenState();
}

class _CloudSyncScreenState extends State<CloudSyncScreen> {
  bool _autoBackupOnWifi = true;
  bool _autoBackupOnMobileData = false;
  bool _backgroundBackupEnabled = true;
  bool _backingUp = false;
  DateTime? _lastBackupAt;

  int? _itemCount;

  @override
  void initState() {
    super.initState();
    _loadItemCount();
    _loadToggles();
  }

  Future<void> _loadToggles() async {
    final wifi = await AppSettingsService.getAutoBackupOnWifi();
    final mobileData = await AppSettingsService.getAutoBackupOnMobileData();
    final background = await AppSettingsService.getBackgroundBackupEnabled();
    if (!mounted) return;
    setState(() {
      _autoBackupOnWifi = wifi;
      _autoBackupOnMobileData = mobileData;
      _backgroundBackupEnabled = background;
    });
  }

  Future<void> _loadItemCount() async {
    try {
      final items = await ApiService.getInventory();
      if (mounted) setState(() => _itemCount = items.length);
    } catch (_) {
      // Item count stays null — cards fall back to "—".
    }
  }

  String _formatLastBackup(DateTime? time) {
    if (time == null) return "Never";
    final now = DateTime.now();
    final isToday =
        time.year == now.year && time.month == now.month && time.day == now.day;
    final hour12 = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? "AM" : "PM";
    final timeLabel = "$hour12:$minute $period";
    return isToday
        ? "Today, $timeLabel"
        : "${time.day}/${time.month}, $timeLabel";
  }

  Future<void> _backUpNow() async {
    if (!SupabaseConfig.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Backup isn't configured yet")),
      );
      return;
    }

    setState(() => _backingUp = true);
    final result = await SupabaseService.resolveConflicts();
    await _loadItemCount();
    if (!mounted) return;

    setState(() {
      _backingUp = false;
      if (result.success) _lastBackupAt = DateTime.now();
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  void _showHelp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Back up your pantry data to the cloud so it's never lost.",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemLabel = _itemCount?.toString() ?? "—";

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
                  _connectionCard(),
                  const SizedBox(height: 16),
                  _dbCard(
                    icon: Icons.cloud_outlined,
                    title: "Pantry Backend",
                    subtitle:
                        "$itemLabel items · the data behind everything you see",
                    tag: "Live",
                    tagBg: AppColors.chipGreenBg,
                    tagText: AppColors.chipGreenText,
                  ),
                  const SizedBox(height: 12),
                  _dbCard(
                    icon: Icons.backup_outlined,
                    title: "Backup Copy",
                    subtitle:
                        "$itemLabel items · ${_formatLastBackup(_lastBackupAt)}",
                    tag: "Backed up",
                    tagBg: const Color(0xFFDBEAFE),
                    tagText: const Color(0xFF1E40AF),
                  ),
                  const SizedBox(height: 16),
                  _autoBackupCard(),
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
              "Backup & Restore",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "Outfit",
                fontWeight: FontWeight.w800,
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

  Widget _connectionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.cloud_done_outlined,
                  color: AppColors.darkGreen,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: SupabaseConfig.isConfigured
                                ? AppColors.chipGreenText
                                : const Color(0xFFD68910),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          SupabaseConfig.isConfigured
                              ? "Connected"
                              : "Not configured",
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Last backup: ${_formatLastBackup(_lastBackupAt)}",
                      style: const TextStyle(
                        color: AppColors.textGray,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Back up your pantry data to the cloud so you never lose it — even if you switch phones or reinstall the app.",
            style: const TextStyle(
              color: AppColors.textGray,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _backingUp ? null : _backUpNow,
              icon: _backingUp
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.backup_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
              label: Text(
                _backingUp ? "Backing up..." : "Back Up Now",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dbCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String tag,
    required Color tagBg,
    required Color tagText,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 20, color: AppColors.darkGreen),
          ),
          const SizedBox(width: 16),
          Expanded(
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: tagBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              tag,
              style: TextStyle(
                color: tagText,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _autoBackupCard() {
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
          const Text(
            "Auto Backup",
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _toggleRow("Auto Backup on WiFi", _autoBackupOnWifi, (v) {
            setState(() => _autoBackupOnWifi = v);
            AppSettingsService.setAutoBackupOnWifi(v);
          }),
          _toggleRow("Auto Backup on Mobile Data", _autoBackupOnMobileData, (
            v,
          ) {
            setState(() => _autoBackupOnMobileData = v);
            AppSettingsService.setAutoBackupOnMobileData(v);
          }),
          _toggleRow("Background Backup", _backgroundBackupEnabled, (v) {
            setState(() => _backgroundBackupEnabled = v);
            AppSettingsService.setBackgroundBackupEnabled(v);
          }),
        ],
      ),
    );
  }

  Widget _toggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
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
}
