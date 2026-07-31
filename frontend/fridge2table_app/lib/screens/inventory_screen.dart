import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../models/ingredient.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
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
  Set<int> _pendingIds = {};

  final _searchController = TextEditingController();
  bool _selectionMode = false;
  final Set<int> _selectedIngredientIds = {};
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
    unawaited(_loadPendingIds());
  }

  Future<void> _refresh() async {
    setState(() {
      inventory = ApiService.getInventory();
    });
    unawaited(_loadPendingIds());
    unawaited(NotificationService.checkAndNotify());
  }

  /// Kept as separate state rather than folded into the Ingredient list
  /// itself -- which items are still waiting to sync is a property of the
  /// local cache, not of the ingredient data, and re-deriving it doesn't
  /// require re-fetching the whole inventory. Note this only refreshes
  /// alongside [inventory] (initState/_refresh); a sync that completes in
  /// the background (see MainScreen's connectivity listener) while this
  /// screen is already open won't clear a card's indicator until the next
  /// pull-to-refresh or edit.
  Future<void> _loadPendingIds() async {
    final ids = await ApiService.getPendingIngredientIds();
    if (!mounted) return;
    setState(() => _pendingIds = ids);
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

  /// Urgency badge shown directly on the Pantry card, matching the same
  /// day-based classification the backend uses for /expiry-status --
  /// null for "fresh" or "unknown" (no date set / unparseable), since
  /// those aren't urgent and don't need a badge at all. Distinct colors
  /// for each of the three urgent states (not just red-vs-not) so a
  /// glance at the list tells expired apart from merely expiring soon.
  (Color, Color, String)? _expiryBadge(String? expiryDate) {
    if (expiryDate == null || expiryDate.isEmpty) return null;

    final expiry = DateTime.tryParse(expiryDate);
    if (expiry == null) return null;

    final today = DateTime.now();
    final daysLeft = DateTime(
      expiry.year,
      expiry.month,
      expiry.day,
    ).difference(DateTime(today.year, today.month, today.day)).inDays;

    if (daysLeft < 0) {
      return (const Color(0xFFFDF2F0), const Color(0xFFC0392B), "Expired");
    } else if (daysLeft == 0) {
      return (const Color(0xFFFDF0E6), const Color(0xFFE67E22), "Today");
    } else if (daysLeft <= 3) {
      return (const Color(0xFFFEF9E7), const Color(0xFFD68910), "Soon");
    }
    return null;
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

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) {
        _selectedIngredientIds.clear();
      }
    });
  }

  void _toggleIngredientSelection(int? id) {
    if (id == null || !_selectionMode) return;
    setState(() {
      if (_selectedIngredientIds.contains(id)) {
        _selectedIngredientIds.remove(id);
      } else {
        _selectedIngredientIds.add(id);
      }
    });
  }

  /// True only when every currently *visible* (search/filter-applied) item
  /// is selected -- used purely to decide whether the toggle button should
  /// read "Select All" or "Deselect All", not to drive selection itself.
  bool _allVisibleSelected(List<Ingredient> visibleItems) {
    return visibleItems.every(
      (item) => item.id != null && _selectedIngredientIds.contains(item.id),
    );
  }

  /// Selects every currently visible ingredient, or deselects them if
  /// they're all already selected -- deliberately scoped to [visibleItems]
  /// (whatever search/filter is active) rather than the whole pantry, so
  /// "Select All" while filtered to e.g. "Dairy" only ever touches dairy
  /// items. Items outside the current filter that were already selected
  /// from an earlier filter are left untouched either way.
  void _toggleSelectAll(List<Ingredient> visibleItems) {
    final visibleIds = visibleItems
        .map((item) => item.id)
        .whereType<int>()
        .toSet();
    setState(() {
      if (_allVisibleSelected(visibleItems)) {
        _selectedIngredientIds.removeAll(visibleIds);
      } else {
        _selectedIngredientIds.addAll(visibleIds);
      }
    });
  }

  Future<void> _deleteSelectedIngredients() async {
    if (_selectedIngredientIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete selected ingredients?"),
        content: const Text(
          "This permanently removes the selected items from your pantry.",
        ),
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
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final ids = _selectedIngredientIds.toList();
    final count = ids.length;

    // Each delete is a real await (local-first write, then a best-effort
    // network call -- see ApiService.deleteIngredient) so a larger
    // selection can take a visible moment; without this, the screen just
    // sat there looking frozen/unresponsive until the whole loop finished.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.darkGreen,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text("Deleting $count item${count == 1 ? '' : 's'}..."),
            ),
          ],
        ),
      ),
    );

    for (final id in ids) {
      await ApiService.deleteIngredient(id);
    }

    if (!mounted) return;
    Navigator.of(
      context,
      rootNavigator: true,
    ).pop(); // dismiss the dialog above

    setState(() {
      _selectedIngredientIds.clear();
      _selectionMode = false;
    });
    _refresh();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$count item${count == 1 ? '' : 's'} deleted")),
    );
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${items.length} ingredient${items.length == 1 ? '' : 's'} in pantry",
                                  style: const TextStyle(
                                    color: AppColors.textGray,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                if (_selectionMode && items.isNotEmpty)
                                  GestureDetector(
                                    onTap: () => _toggleSelectAll(items),
                                    child: Text(
                                      _allVisibleSelected(items)
                                          ? "Deselect All"
                                          : "Select All",
                                      style: const TextStyle(
                                        color: AppColors.darkGreen,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
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
                    fontWeight: FontWeight.w600,
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
                onTap: _selectionMode
                    ? _deleteSelectedIngredients
                    : _toggleSelectionMode,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _selectionMode
                        ? (_selectedIngredientIds.isEmpty
                              ? Icons.delete_outline
                              : Icons.delete_outline)
                        : Icons.checklist_outlined,
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
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// Small amber "Syncing…" pill shown on a card while its offline
  /// create/update hasn't reached the server yet -- so a user who just
  /// added or edited something while offline can see it's queued rather
  /// than wondering if it was lost. Disappears on its own the next time
  /// [_loadPendingIds] runs and the item is no longer in the pending set.
  Widget? _syncingPill(Ingredient item) {
    if (item.id == null || !_pendingIds.contains(item.id)) return null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        "Syncing…",
        style: TextStyle(
          color: Color(0xFFB45309),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildItemCard(Ingredient item) {
    final (chipBg, chipText) = _catColors(item.category);
    final badge = _expiryBadge(item.expiryDate);
    final syncingPill = _syncingPill(item);
    final quantityLabel = item.quantity == item.quantity.roundToDouble()
        ? item.quantity.toInt().toString()
        : item.quantity.toString();

    return GestureDetector(
      onTap: _selectionMode
          ? () => _toggleIngredientSelection(item.id)
          : () => _openEdit(item),
      onLongPress: () {
        if (!_selectionMode) {
          _toggleSelectionMode();
          _toggleIngredientSelection(item.id);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            if (_selectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          item.id != null &&
                              _selectedIngredientIds.contains(item.id)
                          ? AppColors.darkGreen
                          : AppColors.borderGreen,
                      width: 1.5,
                    ),
                    color:
                        item.id != null &&
                            _selectedIngredientIds.contains(item.id)
                        ? AppColors.darkGreen
                        : Colors.white,
                  ),
                  child:
                      item.id != null &&
                          _selectedIngredientIds.contains(item.id)
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
              ),
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
                  fontWeight: FontWeight.w500,
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
                      fontWeight: FontWeight.w500,
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
            if (!_selectionMode)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (syncingPill != null) ...[
                    syncingPill,
                    const SizedBox(height: 4),
                  ],
                  if (badge != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badge.$1,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badge.$3,
                        style: TextStyle(
                          color: badge.$2,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
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
              )
            else if (syncingPill != null || badge != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (syncingPill != null) ...[
                    syncingPill,
                    if (badge != null) const SizedBox(height: 4),
                  ],
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badge.$1,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badge.$3,
                        style: TextStyle(
                          color: badge.$2,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
