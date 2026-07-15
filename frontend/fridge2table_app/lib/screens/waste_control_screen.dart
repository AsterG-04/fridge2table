import 'package:flutter/material.dart';

import '../constants/colors.dart';

class WasteControlScreen extends StatefulWidget {
  const WasteControlScreen({super.key});

  @override
  State<WasteControlScreen> createState() => _WasteControlScreenState();
}

class _WasteControlScreenState extends State<WasteControlScreen> {
  int _tab = 0;

  static const List<Map<String, Object>> _regrowItems = [
    {
      "icon": Icons.eco_outlined,
      "name": "Coriander (Cilantro) Roots",
      "scrap": "Scrap: Roots from coriander bunch",
      "method": "Water bottle / jar",
      "time": "7–10 days",
      "difficulty": "Very Easy",
    },
    {
      "icon": Icons.eco_outlined,
      "name": "Spring Onion (Scallion) Roots",
      "scrap": "Scrap: White root ends (2–3 cm)",
      "method": "Glass of water → Pot",
      "time": "5–7 days",
      "difficulty": "Very Easy",
    },
    {
      "icon": Icons.spa_outlined,
      "name": "Ginger Root Piece",
      "scrap": "Scrap: Any knob of ginger with a bud",
      "method": "Pot with soil",
      "time": "2–3 weeks to sprout",
      "difficulty": "Easy",
    },
    {
      "icon": Icons.grass_outlined,
      "name": "Celery Base",
      "scrap": "Scrap: 2 cm bottom base of celery",
      "method": "Water dish → Pot",
      "time": "3–5 days for sprouts",
      "difficulty": "Easy",
    },
  ];

  void _showHelp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Regrow kitchen scraps, find scrap-friendly recipes, or learn "
          "how to compost what's left.",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildTopBar(),
          _buildIntro(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: _buildTabContent(),
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
              child: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
            ),
          ),
          const Expanded(
            child: Text(
              "Waste Control",
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

  Widget _buildIntro() {
    return Container(
      color: AppColors.darkGreen,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Turn food scraps into something useful",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _tabButton(0, "Regrow")),
              const SizedBox(width: 8),
              Expanded(child: _tabButton(1, "Scrap Recipes")),
              const SizedBox(width: 8),
              Expanded(child: _tabButton(2, "Compost")),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tabButton(int index, String label) {
    final isActive = _tab == index;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? AppColors.darkGreen : Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_tab) {
      case 0:
        return _buildRegrowTab();
      case 1:
        return _buildPlaceholder(
          Icons.restaurant_menu,
          "Scrap Recipes",
          "Recipes that put your vegetable scraps to use are coming soon.",
        );
      default:
        return _buildPlaceholder(
          Icons.compost_outlined,
          "Compost",
          "A step-by-step composting guide is coming soon.",
        );
    }
  }

  Widget _buildRegrowTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.eco, size: 16, color: AppColors.darkGreen),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Regrow vegetables from kitchen scraps. Save money, "
                  "reduce waste, and grow your own herbs and vegetables "
                  "right on your counter.",
                  style: TextStyle(
                    color: AppColors.textGray,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final item in _regrowItems) ...[
          _regrowCard(item),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _regrowCard(Map<String, Object> item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item["icon"] as IconData, color: AppColors.darkGreen, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item["name"] as String,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item["scrap"] as String,
                  style: const TextStyle(color: AppColors.textGray, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _infoPill(item["method"] as String, AppColors.lightGreen, AppColors.darkGreen),
                    _infoPill(item["time"] as String, const Color(0xFFFEF9C3), const Color(0xFF966200)),
                    _infoPill(item["difficulty"] as String, const Color(0xFFEAFAF1), const Color(0xFF1D6A3A)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppColors.textGray, size: 16),
        ],
      ),
    );
  }

  Widget _infoPill(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: TextStyle(color: text, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPlaceholder(IconData icon, String title, String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.textGray),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textGray, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
