import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../services/api_service.dart';
import '../widgets/async_state.dart';
import 'recipe_screen.dart';

class ExpiryMonitorScreen extends StatefulWidget {
  const ExpiryMonitorScreen({super.key});

  @override
  State<ExpiryMonitorScreen> createState() =>
      _ExpiryMonitorScreenState();
}


class _ExpiryMonitorScreenState
    extends State<ExpiryMonitorScreen> {

  late Future<List<Map<String, dynamic>>> expiryStatus;

  static const List<String> _groupOrder = [
    "expired", "today", "soon", "fresh", "unknown"
  ];

  static const Map<String, String> _groupLabels = {
    "expired": "Expired",
    "today": "Expiring Today",
    "soon": "Expiring This Week",
    "fresh": "Fresh",
    "unknown": "No Date Set",
  };

  static const Map<String, Color> _groupColors = {
    "expired": Color(0xFFC0392B),
    "today": Color(0xFFC0392B),
    "soon": Color(0xFFD68910),
    "fresh": Color(0xFF1D6A3A),
    "unknown": AppColors.textGray,
  };

  @override
  void initState() {
    super.initState();

    expiryStatus = ApiService.getExpiryStatus();
  }

  void _refresh() {
    setState(() {
      expiryStatus = ApiService.getExpiryStatus();
    });
  }

  Future<void> _deleteItem(int? id) async {
    if (id == null) return;
    await ApiService.deleteIngredient(id);
    _refresh();
  }

  void _viewRecipes() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RecipeScreen()),
    );
  }

  void _showHelp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Ingredients are grouped by how soon they expire. Tap the "
          "recipe icon to find ways to use them up, or the trash icon "
          "to remove an item.",
        ),
      ),
    );
  }

  (Color, Color) _catColors(String? category) {
    switch (category) {
      case "Vegetables":
        return (AppColors.chipGreenBg, AppColors.chipGreenText);
      case "Meat & Seafood":
        return (const Color(0xFFFEE2E2), const Color(0xFF991B1B));
      case "Dairy":
        return (const Color(0xFFDBEAFE), const Color(0xFF1E40AF));
      case "Fruits":
        return (const Color(0xFFFFEDD5), const Color(0xFF9A3412));
      case "Grains & Bread":
        return (const Color(0xFFEDE9FE), const Color(0xFF5B21B6));
      default:
        return (const Color(0xFFF3F4F6), const Color(0xFF4B5563));
    }
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

  String _subtitleFor(String status, String? expiryDate) {
    if (status == "today") return "Use today";
    if (status == "unknown" || expiryDate == null) return "No expiry set";

    final expiry = DateTime.tryParse(expiryDate);
    if (expiry == null) return "No expiry set";

    if (status == "expired") {
      final daysAgo = DateTime.now().difference(expiry).inDays;
      return daysAgo <= 1 ? "1 day ago" : "$daysAgo days ago";
    }

    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
    ];
    return "${months[expiry.month - 1]} ${expiry.day}";
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
              child: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
            ),
          ),
          const Expanded(
            child: Text(
              "Expiry Monitor",
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
              child: const Icon(Icons.help_outline, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return FutureBuilder<List<Map<String, dynamic>>>(

      future: expiryStatus,

      builder: (context, snapshot) {
        return AsyncStateBuilder<List<Map<String, dynamic>>>(
          snapshot: snapshot,
          onRetry: _refresh,
          isEmpty: (items) => items.isEmpty,
          emptyIcon: Icons.check_circle_outline,
          emptyTitle: "No ingredients tracked yet",
          emptySubtitle: "Add items to your pantry to monitor expiry dates",
          builder: (context, items) {
            final Map<String, List<Map<String, dynamic>>> grouped = {
              for (final status in _groupOrder) status: []
            };

            for (final item in items) {
              final status = item["status"] ?? "unknown";
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

    final color = _groupColors[status]!;
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
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "$label (${items.length})",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),

        for (final item in items) ...[
          _buildItemCard(item, status),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item, String status) {
    final (chipBg, chipText) = _catColors(item["category"]);
    final name = item["name"] ?? "";

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
            decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(20)),
            alignment: Alignment.center,
            child: Text(
              _initials(name),
              style: TextStyle(color: chipText, fontWeight: FontWeight.bold, fontSize: 12),
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
                Text(
                  _subtitleFor(status, item["expiry_date"]),
                  style: const TextStyle(color: AppColors.textGray, fontSize: 12),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _viewRecipes,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(Icons.restaurant_menu, size: 14, color: AppColors.darkGreen),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _deleteItem(item["id"]),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(Icons.delete_outline, size: 14, color: Color(0xFFC0392B)),
            ),
          ),
        ],
      ),
    );
  }
}
