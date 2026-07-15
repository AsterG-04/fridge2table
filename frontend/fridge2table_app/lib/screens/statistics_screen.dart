import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/colors.dart';
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
  int? _recipesMatched;

  static const List<_MonthTrend> _trends = [
    _MonthTrend("Jan", 2.1, 0.4),
    _MonthTrend("Feb", 2.6, 0.3),
    _MonthTrend("Mar", 2.3, 0.6),
    _MonthTrend("Apr", 2.8, 0.2),
    _MonthTrend("May", 3.1, 0.3),
    _MonthTrend("Jun", 2.9, 0.2),
  ];

  static const Color _savedColor = AppColors.chipGreenText;
  static const Color _wastedColor = Color(0xFFC0392B);

  static const List<_CategoryShare> _categories = [
    _CategoryShare("Vegetables", 38, AppColors.chipGreenText),
    _CategoryShare("Protein", 28, Color(0xFF991B1B)),
    _CategoryShare("Dairy", 20, Color(0xFF1E40AF)),
    _CategoryShare("Fruits", 14, Color(0xFF9A3412)),
  ];

  @override
  void initState() {
    super.initState();
    _loadRealStats();
  }

  Future<void> _loadRealStats() async {
    try {
      final inventory = await ApiService.getInventory();
      if (mounted) setState(() => _totalItems = inventory.length);
    } catch (_) {
      // Falls back to "—" below.
    }

    try {
      final expiryStatus = await ApiService.getExpiryStatus();
      final count = expiryStatus.where((e) => e["status"] == "expired").length;
      if (mounted) setState(() => _expiredCount = count);
    } catch (_) {
      // Falls back to "—" below.
    }

    try {
      final recipes = await ApiService.getRecipesDetailed();
      if (mounted) setState(() => _recipesMatched = recipes.length);
    } catch (_) {
      // Falls back to "—" below.
    }
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
                    style: TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildPantrySnapshot(),
                  const SizedBox(height: 20),
                  const Text(
                    "Estimated Impact",
                    style: TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildStatGrid(),
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
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
              child: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
            ),
          ),
          const Expanded(
            child: Text(
              "Statistics",
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: "Outfit", fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white),
            ),
          ),
          GestureDetector(
            onTap: () => _showHelp(context),
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

  Widget _buildPantrySnapshot() {
    return Row(
      children: [
        Expanded(child: _statCard(Icons.kitchen_outlined, _totalItems?.toString() ?? "—", "Items in Pantry")),
        const SizedBox(width: 8),
        Expanded(child: _statCard(Icons.warning_amber_rounded, _expiredCount?.toString() ?? "—", "Expired")),
        const SizedBox(width: 8),
        Expanded(child: _statCard(Icons.restaurant_menu, _recipesMatched?.toString() ?? "—", "Recipes Matched")),
      ],
    );
  }

  Widget _buildStatGrid() {
    return Row(
      children: [
        Expanded(child: _statCard(Icons.savings_outlined, "14 kg", "Food Saved")),
        const SizedBox(width: 12),
        Expanded(child: _statCard(Icons.eco_outlined, "92%", "Waste Reduced")),
      ],
    );
  }

  Widget _statCard(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: AppColors.darkGreen),
              const SizedBox(height: 12),
              Text(value, style: const TextStyle(fontFamily: "Outfit", fontWeight: FontWeight.w800, fontSize: 22, color: AppColors.textDark)),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(color: AppColors.textGray, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendsCard(BuildContext context) {
    final maxValue = _trends.map((t) => t.saved + t.wasted).reduce(math.max);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Monthly Trends", style: TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.bold)),
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
        SnackBar(content: Text("${t.label}: ${t.saved} kg saved · ${t.wasted} kg wasted")),
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ),
              const SizedBox(width: 2),
              Container(
                width: 9,
                height: wastedHeight.clamp(4, chartHeight),
                decoration: BoxDecoration(
                  color: _wastedColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(t.label, style: const TextStyle(color: AppColors.textGray, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppColors.textGray, fontSize: 12)),
      ],
    );
  }

  Widget _buildCategoriesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Most Used Categories", style: TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
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
        Container(width: 10, height: 10, decoration: BoxDecoration(color: c.color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(c.label, style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w600))),
        Text("${c.percent.toInt()}%", style: const TextStyle(color: AppColors.textGray, fontSize: 12)),
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
