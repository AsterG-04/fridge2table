import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../models/ingredient.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'ai_camera_screen.dart';
import 'add_ingredient_screen.dart';
import 'expiry_monitor_screen.dart';
import 'inventory_screen.dart';
import 'recipe_screen.dart';
import 'waste_control_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _itemCount;
  int? _expiringSoonCount;
  int? _recipeMatchCount;
  String _userName = "there";
  List<Ingredient>? _recentIngredients;
  List<Map<String, dynamic>>? _topRecipes;

  static const List<List<Color>> _recipeGradients = [
    [Color(0xFF7B341E), Color(0xFFC05621)],
    [Color(0xFF713F12), Color(0xFFC6862A)],
    [Color(0xFF3B0764), Color(0xFF7C3AED)],
  ];

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final name = await AuthService.getName();
    if (mounted && name != null && name.isNotEmpty) {
      setState(() => _userName = name);
    }
  }

  String get _userInitials {
    final trimmed = _userName.trim();
    if (trimmed.isEmpty || trimmed == "there") return "?";
    final words = trimmed.split(RegExp(r"\s+"));
    if (words.length == 1) {
      return words[0].substring(0, words[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  Future<void> _loadStats() async {
    try {
      final inventory = await ApiService.getInventory();
      final sorted = [...inventory]
        ..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
      if (mounted) {
        setState(() {
          _itemCount = inventory.length;
          _recentIngredients = sorted.take(5).toList();
        });
      }
    } catch (_) {
      // Stat card and recent list fall back below.
    }

    try {
      final expiryStatus = await ApiService.getExpiryStatus();
      final count = expiryStatus
          .where((e) => e["status"] == "today" || e["status"] == "soon")
          .length;
      if (mounted) setState(() => _expiringSoonCount = count);
    } catch (_) {
      // Stat card falls back to "—" below.
    }

    try {
      final recipes = await ApiService.getRecipesDetailed();
      if (mounted) {
        setState(() {
          _recipeMatchCount = recipes.length;
          _topRecipes = recipes.take(3).toList();
        });
      }
    } catch (_) {
      // Stat card and recipe picks fall back below.
    }
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAiInsightBanner(context),
                  const SizedBox(height: 16),
                  _buildQuickActions(context),
                  const SizedBox(height: 16),
                  _buildExpiryAlert(context),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    "Recent Ingredients",
                    onSeeAll: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const InventoryScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRecentIngredients(),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    "Top Recipe Picks",
                    onSeeAll: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RecipeScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTopRecipes(),
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
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Good morning,",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  Text(
                    _userName,
                    style: const TextStyle(
                      fontFamily: "Outfit",
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications_outlined,
                            color: Colors.white, size: 18),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE9A820),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _userInitials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Icon(Icons.settings_outlined,
                        color: Colors.white, size: 16),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _statCard(_itemCount?.toString() ?? "—", "Pantry Items")),
              const SizedBox(width: 8),
              Expanded(child: _statCard(_expiringSoonCount?.toString() ?? "—", "Expiring Soon")),
              const SizedBox(width: 8),
              Expanded(child: _statCard(_recipeMatchCount?.toString() ?? "—", "Recipe Matches")),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: "Outfit",
              fontWeight: FontWeight.w800,
              fontSize: 24,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiInsightBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9A820).withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFE9A820),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "AI INSIGHT",
                  style: TextStyle(
                    color: Color(0xFF966200),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Spinach expires tomorrow — 3 rescue recipes ready now.",
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RecipeScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF966200),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                "Rescue",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _quickAction(
            icon: Icons.camera_alt_outlined,
            label: "AI Scan",
            bgColor: AppColors.darkGreen,
            textColor: Colors.white,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AiCameraScreen()),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _quickAction(
            icon: Icons.add,
            label: "Add Item",
            bgColor: AppColors.lightGreen,
            textColor: AppColors.darkGreen,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddIngredientScreen()),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _quickAction(
            icon: Icons.eco_outlined,
            label: "Waste Control",
            bgColor: const Color(0xFFFEF9C3),
            textColor: const Color(0xFF966200),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WasteControlScreen()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiryAlert(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ExpiryMonitorScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: const Color(0xFFFDF2F0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFC0392B).withValues(alpha: 0.13)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFC0392B).withValues(alpha: 0.13),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFC0392B), size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${_expiringSoonCount ?? '—'} items expiring soon",
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Act now to prevent waste",
                    style: const TextStyle(
                      color: AppColors.textGray,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textGray, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {required VoidCallback onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        GestureDetector(
          onTap: onSeeAll,
          child: const Text(
            "See all",
            style: TextStyle(
              color: AppColors.darkGreen,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentIngredients() {
    final items = _recentIngredients;

    if (items == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator(color: AppColors.darkGreen)),
      );
    }

    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: const Center(
          child: Text("No ingredients yet — add your first item!", style: TextStyle(color: AppColors.textGray)),
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          _recentIngredientRow(items[i]),
          if (i != items.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _recentIngredientRow(Ingredient item) {
    final (chipBg, chipText) = _catColorsFor(item.category);
    final (tagBg, tagText, tagLabel) = _expiryTagFor(item.expiryDate);
    final quantityLabel = item.quantity == item.quantity.roundToDouble()
        ? item.quantity.toInt().toString()
        : item.quantity.toString();

    return _ingredientRow(
      _initialsFor(item.name),
      chipBg,
      chipText,
      item.name,
      "$quantityLabel ${item.unit} · ${item.category ?? 'Uncategorized'}",
      tagLabel,
      tagBg,
      tagText,
    );
  }

  String _initialsFor(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return "?";
    final words = trimmed.split(RegExp(r"\s+"));
    if (words.length == 1) {
      return words[0].substring(0, words[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  (Color, Color) _catColorsFor(String? category) {
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

  (Color, Color, String) _expiryTagFor(String? expiryDate) {
    if (expiryDate == null || expiryDate.isEmpty) {
      return (const Color(0xFFF3F4F6), const Color(0xFF6B7280), "No date");
    }

    final expiry = DateTime.tryParse(expiryDate);
    if (expiry == null) {
      return (const Color(0xFFF3F4F6), const Color(0xFF6B7280), "No date");
    }

    final daysLeft = expiry.difference(DateTime.now()).inDays;
    final label = daysLeft == 0 ? "Today" : "${daysLeft.abs()} d";

    if (daysLeft < 0) {
      return (const Color(0xFFFDF2F0), const Color(0xFFC0392B), "Expired");
    } else if (daysLeft <= 1) {
      return (const Color(0xFFFDF2F0), const Color(0xFFC0392B), label);
    } else if (daysLeft <= 3) {
      return (const Color(0xFFFEF9E7), const Color(0xFFD68910), label);
    }
    return (const Color(0xFFEAFAF1), const Color(0xFF1D6A3A), label);
  }

  Widget _ingredientRow(
    String initials,
    Color chipBg,
    Color chipText,
    String name,
    String subtitle,
    String expiryLabel,
    Color tagBg,
    Color tagText,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              initials,
              style: TextStyle(color: chipText, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: const TextStyle(color: AppColors.textGray, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: tagBg, borderRadius: BorderRadius.circular(999)),
            child: Text(
              expiryLabel,
              style: TextStyle(color: tagText, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopRecipes() {
    final recipes = _topRecipes;

    if (recipes == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator(color: AppColors.darkGreen)),
      );
    }

    if (recipes.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: const Center(
          child: Text("Add ingredients to see recipe matches", style: TextStyle(color: AppColors.textGray)),
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < recipes.length; i++) ...[
          _recipeCard(
            recipes[i]["name"] ?? "",
            "${recipes[i]["match_score"] ?? 0}%",
            _recipeGradients[i % _recipeGradients.length],
          ),
          if (i != recipes.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _recipeCard(String name, String matchPct, List<Color> gradient) {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                matchPct,
                style: const TextStyle(
                  color: AppColors.darkGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
