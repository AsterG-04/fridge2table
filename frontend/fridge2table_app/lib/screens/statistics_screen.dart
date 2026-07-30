import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../models/cooked_history_entry.dart';
import '../services/api_service.dart';

class _MonthTrend {
  final String label;
  final double saved;
  final double wasted;

  const _MonthTrend(this.label, this.saved, this.wasted);
}

class _CategoryShare {
  final String label;
  final double percent;
  final Color color;

  const _CategoryShare(this.label, this.percent, this.color);
}

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int? _totalItems;
  int? _expiredCount;
  int? _expiringSoonCount;
  int? _recipesMatched;
  int? _recipesCooked;
  double _foodSavedKg = 0;
  List<_MonthTrend> _trends = [];
  bool _historyLoaded = false;

  static const Color _savedColor = AppColors.chipGreenText;
  static const Color _wastedColor = Color(0xFFC0392B);

  // Rough estimate — the app doesn't track exact per-cook ingredient
  // weights in history (only Recipe Complete has that, per-session), so
  // monthly trends and total Food Saved are estimated from how many times
  // each recipe was cooked using this average.
  static const double _avgKgPerCook = 0.15;

  static const List<String> _monthAbbrev = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
  ];

  static const Map<String, Color> _categoryColors = {
    "Vegetables": AppColors.chipGreenText,
    "Meat & Seafood": Color(0xFF991B1B),
    "Dairy": Color(0xFF1E40AF),
    "Fruits": Color(0xFF9A3412),
    "Grains & Bread": Color(0xFF5B21B6),
  };

  List<_CategoryShare> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadRealStats();
    _loadHistoryStats();
  }

  // Independent calls run concurrently rather than stacking up their
  // timeouts one after another — see the same fix in home_screen.dart.
  Future<void> _loadRealStats() async {
    await Future.wait([
      _loadInventoryCount(),
      _loadExpiryCounts(),
      _loadRecipesMatchedCount(),
    ]);
  }

  Future<void> _loadInventoryCount() async {
    try {
      final inventory = await ApiService.getInventory();
      if (mounted) setState(() => _totalItems = inventory.length);
    } catch (_) {
      // Falls back to "—" below.
    }
  }

  // Expired and expiring-soon are split into two distinct stats now
  // (rather than one combined "Items Expired" figure), computed from the
  // same /expiry-status call: "expired" is strictly past-date, while
  // "expiring soon" covers "today" and "soon" (within 3 days) so a user
  // can tell "already gone off" apart from "use this shortly" at a glance.
  Future<void> _loadExpiryCounts() async {
    try {
      final expiryStatus = await ApiService.getExpiryStatus();
      final expired = expiryStatus
          .where((e) => e["status"] == "expired")
          .length;
      final expiringSoon = expiryStatus
          .where((e) => e["status"] == "today" || e["status"] == "soon")
          .length;
      if (mounted) {
        setState(() {
          _expiredCount = expired;
          _expiringSoonCount = expiringSoon;
        });
      }
    } catch (_) {
      // Falls back to "—" below.
    }
  }

  Future<void> _loadRecipesMatchedCount() async {
    try {
      final recipes = await ApiService.getRecipesDetailed();
      if (mounted) setState(() => _recipesMatched = recipes.length);
    } catch (_) {
      // Falls back to "—" below.
    }
  }

  Future<void> _loadHistoryStats() async {
    debugPrint("[StatisticsScreen] _loadHistoryStats() starting");
    await CookedHistoryStore.load();
    if (!mounted) return;

    final totalCooked = CookedHistoryStore.totalMealsCooked;
    debugPrint(
      "[StatisticsScreen] _loadHistoryStats(): totalMealsCooked=$totalCooked",
    );

    setState(() {
      _recipesCooked = totalCooked;
      _foodSavedKg = totalCooked * _avgKgPerCook;
      _trends = _buildTrendsFromHistory();
      _categories = _buildCategoryShares();
      _historyLoaded = true;
    });
    debugPrint(
      "[StatisticsScreen] _loadHistoryStats() done — _recipesCooked=$_recipesCooked "
      "_foodSavedKg=$_foodSavedKg",
    );
  }

  List<_CategoryShare> _buildCategoryShares() {
    final counts = CookedHistoryStore.categoryCounts;
    final total = counts.values.fold(0, (sum, c) => sum + c);
    if (total == 0) return [];

    return [
      for (final entry in counts.entries)
        _CategoryShare(
          entry.key,
          entry.value / total * 100,
          _categoryColors[entry.key] ?? AppColors.textGray,
        ),
    ]..sort((a, b) => b.percent.compareTo(a.percent));
  }

  List<_MonthTrend> _buildTrendsFromHistory() {
    final now = DateTime.now();

    // Last 6 months, oldest first, keyed by "year-month" to stay correct
    // across a year boundary.
    final months = <String, _MonthTrend>{};
    for (int i = 5; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);
      months["${d.year}-${d.month}"] = _MonthTrend(
        _monthAbbrev[d.month - 1],
        0,
        0,
      );
    }

    for (final entry in CookedHistoryStore.entries) {
      final parts = entry.lastCookedLabel.trim().split(RegExp(r"\s+"));
      if (parts.length != 2) continue;
      final monthIdx = _monthAbbrev.indexOf(parts[1]) + 1;
      if (monthIdx == 0) continue;

      final key = "${now.year}-$monthIdx";
      final existing = months[key];
      if (existing == null) continue;

      final savedKg = entry.timesCooked * _avgKgPerCook;
      months[key] = _MonthTrend(
        existing.label,
        existing.saved + savedKg,
        existing.wasted + savedKg * 0.15,
      );
    }

    return months.values.toList();
  }

  void _showHelp(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "See how much food and money you've saved, and which pantry "
          "categories you use most.",
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
          _buildTopBar(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Your Pantry Right Now",
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPantrySnapshot(),
                  const SizedBox(height: 20),
                  const Text(
                    "Cooking Impact",
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStatGrid(),
                  if (_historyLoaded && (_recipesCooked ?? 0) == 0) ...[
                    const SizedBox(height: 8),
                    _buildStartCookingTip(),
                  ],
                  const SizedBox(height: 16),
                  _buildTrendsCard(context),
                  const SizedBox(height: 16),
                  _buildCategoriesCard(),
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
              "Statistics",
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
            onTap: () => _showHelp(context),
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

  Widget _buildPantrySnapshot() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(
                Icons.kitchen_outlined,
                _totalItems?.toString() ?? "—",
                "Items in Pantry",
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statCard(
                Icons.schedule,
                _expiringSoonCount?.toString() ?? "—",
                "Expiring Soon",
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _statCard(
                Icons.warning_amber_rounded,
                _expiredCount?.toString() ?? "—",
                "Expired",
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statCard(
                Icons.restaurant_menu,
                _recipesMatched?.toString() ?? "—",
                "Recipes Matched",
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatGrid() {
    final foodSavedLabel = _historyLoaded
        ? "${_foodSavedKg.toStringAsFixed(1)} kg"
        : "—";
    final recipesCookedLabel = _recipesCooked?.toString() ?? "—";

    return Row(
      children: [
        Expanded(
          child: _statCard(
            Icons.savings_outlined,
            foodSavedLabel,
            "Food Saved",
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            Icons.restaurant,
            recipesCookedLabel,
            "Recipes Cooked",
          ),
        ),
      ],
    );
  }

  Widget _statCard(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: AppColors.darkGreen),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: "Outfit",
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(color: AppColors.textGray, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStartCookingTip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 18,
            color: AppColors.darkGreen,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Start cooking to track your impact!",
              style: TextStyle(
                color: AppColors.darkGreen,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsCard(BuildContext context) {
    if (_trends.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxValue = _trends
        .map((t) => t.saved + t.wasted)
        .fold(
          0.01,
          math.max,
        ); // avoid divide-by-zero when nothing's been cooked yet

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
            "Monthly Trends",
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            "Estimated from your cooking history",
            style: TextStyle(color: AppColors.textGray, fontSize: 11),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final t in _trends) _monthBar(context, t, maxValue),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _legendDot(_savedColor, "Food Saved"),
              const SizedBox(width: 16),
              _legendDot(_wastedColor, "Wasted"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _monthBar(BuildContext context, _MonthTrend t, double maxValue) {
    const chartHeight = 96.0;
    final savedHeight = (t.saved / maxValue) * chartHeight;
    final wastedHeight = (t.wasted / maxValue) * chartHeight;

    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${t.label}: ${t.saved.toStringAsFixed(2)} kg saved · ${t.wasted.toStringAsFixed(2)} kg wasted",
          ),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 9,
                height: savedHeight.clamp(4, chartHeight),
                decoration: BoxDecoration(
                  color: _savedColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Container(
                width: 9,
                height: wastedHeight.clamp(4, chartHeight),
                decoration: BoxDecoration(
                  color: _wastedColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            t.label,
            style: const TextStyle(color: AppColors.textGray, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: AppColors.textGray, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildCategoriesCard() {
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
            "Most Used Categories",
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (!_historyLoaded)
            const SizedBox.shrink()
          else if (_categories.isEmpty)
            const Text(
              "📊 Cook a few recipes to see your category breakdown!",
              style: TextStyle(color: AppColors.textGray, fontSize: 12),
            )
          else
            Row(
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CustomPaint(painter: _DonutPainter(_categories)),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: [
                      for (final c in _categories) ...[
                        _categoryRow(c),
                        const SizedBox(height: 10),
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

  Widget _categoryRow(_CategoryShare c) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: c.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            c.label,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          "${c.percent.toInt()}%",
          style: const TextStyle(color: AppColors.textGray, fontSize: 12),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<_CategoryShare> categories;

  _DonutPainter(this.categories);

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 16.0;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    var startAngle = -math.pi / 2;
    for (final c in categories) {
      final sweep = (c.percent / 100) * 2 * math.pi;
      final paint = Paint()
        ..color = c.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep - 0.03,
        false,
        paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => false;
}
