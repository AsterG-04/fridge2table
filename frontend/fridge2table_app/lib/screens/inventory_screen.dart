import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../models/ingredient.dart';
import '../services/api_service.dart';
import 'add_ingredient_screen.dart';
import 'ai_camera_screen.dart';
import 'expiry_monitor_screen.dart';
import '../widgets/async_state.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late Future<List<Ingredient>> inventory;

  final _searchController = TextEditingController();
  String _query = "";
  String _activeFilter = "All";

  static const List<String> _filters = [
    "All",
    "Vegetables",
    "Protein",
    "Dairy",
    "Fruits",
    "Grains",
  ];

  static const Map<String, String> _filterToCategory = {
    "Vegetables": "Vegetables",
    "Protein": "Meat & Seafood",
    "Dairy": "Dairy",
    "Fruits": "Fruits",
    "Grains": "Grains & Bread",
  };

  @override
  void initState() {
    super.initState();
    inventory = ApiService.getInventory();
  }

  Future<void> _refresh() async {
    setState(() {
      inventory = ApiService.getInventory();
    });
  }

  List<Ingredient> _applyFilters(List<Ingredient> items) {
    return items.where((item) {
      final matchesQuery =
          _query.isEmpty || item.name.toLowerCase().contains(_query);
      final matchesFilter =
          _activeFilter == "All" ||
          item.category == _filterToCategory[_activeFilter];
      return matchesQuery && matchesFilter;
    }).toList();
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

  (Color, Color, String) _expiryTag(String? expiryDate) {
    if (expiryDate == null || expiryDate.isEmpty) {
      return (const Color(0xFFF3F4F6), const Color(0xFF6B7280), "No date");
    }

    final expiry = DateTime.tryParse(expiryDate);
    if (expiry == null) {
      return (const Color(0xFFF3F4F6), const Color(0xFF6B7280), "No date");
    }

    final daysLeft = expiry.difference(DateTime.now()).inDays;
    final label = "${expiry.month}/${expiry.day}";

    if (daysLeft < 0) {
      return (const Color(0xFFFDF2F0), const Color(0xFFC0392B), "Expired");
    } else if (daysLeft <= 1) {
      return (const Color(0xFFFDF2F0), const Color(0xFFC0392B), label);
    } else if (daysLeft <= 3) {
      return (const Color(0xFFFEF9E7), const Color(0xFFD68910), label);
    }
    return (const Color(0xFFEAFAF1), const Color(0xFF1D6A3A), label);
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

  Future<void> _openScanner() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AiCameraScreen()),
    );
    if (result == true) _refresh();
  }

  Future<void> _openAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddIngredientScreen()),
    );
    if (result == true) _refresh();
  }

  Future<void> _openEdit(Ingredient ingredient) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddIngredientScreen(existingIngredient: ingredient),
      ),
    );
    if (result == true) _refresh();
  }

  Future<bool> _confirmRemove(String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text("Remove $name from pantry?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFC0392B),
            ),
            child: const Text("Remove"),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _deleteIngredient(Ingredient ingredient) async {
    if (ingredient.id == null) return;
    final confirmed = await _confirmRemove(ingredient.name);
    if (!confirmed) return;
    if (!mounted) return;
    await ApiService.deleteIngredient(ingredient.id!);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: _openAdd,
        backgroundColor: AppColors.darkGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          _buildTopBar(),
          _buildSearchBar(),
          Expanded(
            child: FutureBuilder<List<Ingredient>>(
              future: inventory,
              builder: (context, snapshot) {
                return AsyncStateBuilder<List<Ingredient>>(
                  snapshot: snapshot,
                  onRetry: _refresh,
                  builder: (context, allItems) {
                    final items = _applyFilters(allItems);

                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        children: [
                          _buildFilterChips(),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              "${items.length} ingredient${items.length == 1 ? '' : 's'} in pantry",
                              style: const TextStyle(
                                color: AppColors.textGray,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (items.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 40),
                              child: Center(
                                child: Text(
                                  allItems.isEmpty
                                      ? "Your pantry is empty — tap + to add ingredients"
                                      : "No ingredients match your search",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.textGray,
                                  ),
                                ),
                              ),
                            )
                          else
                            for (final item in items) ...[
                              _buildItemCard(item),
                              const SizedBox(height: 8),
                            ],
                        ],
                      ),
                    );
                  },
                );
              },
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
                  "My Pantry",
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
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ExpiryMonitorScreen(),
                  ),
                ),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.event_busy_outlined,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _openScanner,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    // A light backdrop (not AppColors.darkGreen) here matters for more than
    // looks: _buildTopBar()'s bottom corners are rounded, which reveals
    // whatever sits directly behind/below it. A same-color dark green
    // backdrop made that rounding invisible against the header, but the very
    // next thing after the rounded corners was actually this section's
    // background — so on a light backdrop instead, the header's rounding
    // reads as a clean edge into the page rather than an odd notch.
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderGreen),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, size: 18, color: AppColors.textGray),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (v) =>
                    setState(() => _query = v.trim().toLowerCase()),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                  hintText: "Search ingredients...",
                  hintStyle: TextStyle(color: AppColors.textGray, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          for (int i = 0; i < _filters.length; i++) ...[
            _buildFilterChip(_filters[i]),
            if (i != _filters.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter) {
    final isActive = filter == _activeFilter;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.darkGreen : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: isActive
              ? null
              : Border.all(color: AppColors.darkGreen.withValues(alpha: 0.11)),
        ),
        alignment: Alignment.center,
        child: Text(
          filter,
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.textDark,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(Ingredient item) {
    final (chipBg, chipText) = _catColors(item.category);
    final (tagBg, tagText, tagLabel) = _expiryTag(item.expiryDate);
    final quantityLabel = item.quantity == item.quantity.roundToDouble()
        ? item.quantity.toInt().toString()
        : item.quantity.toString();

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
              color: chipBg,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(item.name),
              style: TextStyle(
                color: chipText,
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
                  item.name,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "$quantityLabel ${item.unit} · ${item.category ?? 'Uncategorized'}",
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: tagBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  tagLabel,
                  style: TextStyle(
                    color: tagText,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _openEdit(item),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        size: 13,
                        color: AppColors.textGray,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _deleteIngredient(item),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        size: 13,
                        color: Color(0xFFC0392B),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
