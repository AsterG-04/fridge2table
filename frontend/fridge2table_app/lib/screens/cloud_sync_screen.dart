import 'package:flutter/material.dart';

import '../config/supabase_config.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';

class CloudSyncScreen extends StatefulWidget {
  const CloudSyncScreen({super.key});

  @override
  State<CloudSyncScreen> createState() => _CloudSyncScreenState();
}

class _CloudSyncScreenState extends State<CloudSyncScreen> {
  bool _syncOnWifi = true;
  bool _mobileData = false;
  bool _backgroundSync = true;
  bool _syncing = false;
  DateTime? _lastSyncAt;

  int? _itemCount;

  @override
  void initState() {
    super.initState();
    _loadItemCount();
  }

  Future<void> _loadItemCount() async {
    try {
      final items = await ApiService.getInventory();
      if (mounted) setState(() => _itemCount = items.length);
    } catch (_) {
      // Item count stays null — cards fall back to "—".
    }
  }

  String _formatLastSync(DateTime? time) {
    if (time == null) return "Never";
    final now = DateTime.now();
    final isToday = time.year == now.year && time.month == now.month && time.day == now.day;
    final hour12 = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? "AM" : "PM";
    final timeLabel = "$hour12:$minute $period";
    return isToday ? "Today, $timeLabel" : "${time.day}/${time.month}, $timeLabel";
  }

  Future<void> _syncNow() async {
    if (!SupabaseConfig.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cloud sync isn't configured yet")),
      );
      return;
    }

    setState(() => _syncing = true);
    final result = await SupabaseService.resolveConflicts();
    await _loadItemCount();
    if (!mounted) return;

    setState(() {
      _syncing = false;
      if (result.success) _lastSyncAt = DateTime.now();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
  }

  void _showHelp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Keep your pantry backed up and available across devices."),
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
                    icon: Icons.smartphone,
                    title: "Local Database",
                    subtitle: "$itemLabel items · 2.4 MB",
                    tag: "Up to date",
                    tagBg: AppColors.chipGreenBg,
                    tagText: AppColors.chipGreenText,
                  ),
                  const SizedBox(height: 12),
                  _dbCard(
                    icon: Icons.cloud_outlined,
                    title: "Cloud Database",
                    subtitle: "$itemLabel items · ${_formatLastSync(_lastSyncAt)}",
                    tag: "Synced",
                    tagBg: const Color(0xFFDBEAFE),
                    tagText: const Color(0xFF1E40AF),
                  ),
                  const SizedBox(height: 16),
                  _autoSyncCard(),
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
              "Cloud Sync",
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: "Outfit", fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white),
            ),
          ),
          GestureDetector(
            onTap: _showHelp,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
              child: const Icon(Icons.help_outline, color: Colors.white, size: 18),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: AppColors.lightGreen, borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.cloud_done_outlined, color: AppColors.darkGreen, size: 28),
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
                            color: SupabaseConfig.isConfigured ? AppColors.chipGreenText : const Color(0xFFD68910),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          SupabaseConfig.isConfigured ? "Connected" : "Not configured",
                          style: const TextStyle(color: AppColors.textDark, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text("Last sync: ${_formatLastSync(_lastSyncAt)}", style: const TextStyle(color: AppColors.textGray, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _syncing ? null : _syncNow,
              icon: _syncing
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.sync, size: 16, color: Colors.white),
              label: Text(_syncing ? "Syncing..." : "Sync Now", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, size: 20, color: AppColors.darkGreen),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(color: AppColors.textGray, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: tagBg, borderRadius: BorderRadius.circular(999)),
            child: Text(tag, style: TextStyle(color: tagText, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _autoSyncCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Auto Sync", style: TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _toggleRow("Sync on WiFi", _syncOnWifi, (v) => setState(() => _syncOnWifi = v)),
          _toggleRow("Mobile Data", _mobileData, (v) => setState(() => _mobileData = v)),
          _toggleRow("Background Sync", _backgroundSync, (v) => setState(() => _backgroundSync = v)),
        ],
      ),
    );
  }

  Widget _toggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.w600))),
          Switch(value: value, onChanged: onChanged, activeThumbColor: AppColors.darkGreen),
        ],
      ),
    );
  }
}
