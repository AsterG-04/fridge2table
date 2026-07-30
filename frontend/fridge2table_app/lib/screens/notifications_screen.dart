import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../services/api_service.dart';
import '../widgets/async_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<Map<String, dynamic>>> _expiryStatus;

  static const List<String> _groupOrder = ["expired", "today", "soon"];

  static const Map<String, String> _groupLabels = {
    "expired": "Expired",
    "today": "Expiring Today",
    "soon": "Expiring Soon",
  };

  static const Map<String, Color> _badgeColors = {
    "expired": Color(0xFFC0392B),
    "today": Color(0xFFD68910),
    "soon": Color(0xFF966200),
  };

  static const Map<String, Color> _badgeBackgrounds = {
    "expired": Color(0xFFFDF2F0),
    "today": Color(0xFFFEF3E2),
    "soon": Color(0xFFFEF9E7),
  };

  @override
  void initState() {
    super.initState();
    _expiryStatus = ApiService.getExpiryStatus();
  }

  void _refresh() {
    setState(() {
      _expiryStatus = ApiService.getExpiryStatus();
    });
  }

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return "?";
    final words = trimmed.split(RegExp(r"\s+"));
    if (words.length == 1) {
      return words[0].substring(0, words[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  String _badgeLabel(String status, String? expiryDate) {
    switch (status) {
      case "expired":
        return "Remove from pantry";
      case "today":
        return "Use today!";
      case "soon":
        final expiry = expiryDate == null
            ? null
            : DateTime.tryParse(expiryDate);
        if (expiry == null) return "Expiring soon";
        final daysLeft = DateTime(expiry.year, expiry.month, expiry.day)
            .difference(
              DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
              ),
            )
            .inDays;
        return "Expiring in $daysLeft day${daysLeft == 1 ? '' : 's'}";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(child: _buildBody()),
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
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
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
                  "Notifications",
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
        ),
      ),
    );
  }

  Widget _buildBody() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _expiryStatus,
      builder: (context, snapshot) {
        return AsyncStateBuilder<List<Map<String, dynamic>>>(
          snapshot: snapshot,
          onRetry: _refresh,
          isEmpty: (items) =>
              !items.any((item) => _groupOrder.contains(item["status"])),
          emptyIcon: Icons.notifications_none_outlined,
          emptyTitle: "No notifications — your pantry is all good! ✅",
          builder: (context, items) {
            final Map<String, List<Map<String, dynamic>>> grouped = {
              for (final status in _groupOrder) status: [],
            };

            for (final item in items) {
              final status = item["status"];
              grouped[status]?.add(item);
            }

            return RefreshIndicator(
              onRefresh: () async => _refresh(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  for (final status in _groupOrder)
                    if (grouped[status]!.isNotEmpty)
                      _buildGroup(status, grouped[status]!),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGroup(String status, List<Map<String, dynamic>> items) {
    final badgeColor = _badgeColors[status]!;
    final label = _groupLabels[status]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "$label (${items.length})",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: badgeColor,
                ),
              ),
            ],
          ),
        ),
        for (final item in items) ...[
          _buildNotificationCard(item, status),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> item, String status) {
    final name = item["name"] ?? "";
    final badgeColor = _badgeColors[status]!;
    final badgeBg = _badgeBackgrounds[status]!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(name),
              style: TextStyle(
                color: badgeColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _badgeLabel(status, item["expiry_date"]),
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
