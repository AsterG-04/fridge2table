import 'package:flutter/material.dart';
import '../models/cooked_history_entry.dart';
import '../models/recipe_detail.dart';
import '../services/api_service.dart';
import '../services/saved_recipes_store.dart';
import '../widgets/async_state.dart';
import 'recipe_detail_screen.dart';

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key, this.initialIngredientFilter});

  /// When set, the search field is pre-filled with this ingredient name so
  /// the list opens pre-filtered to recipes that use it (e.g. tapped from
  /// an expiring pantry item), and a one-time message is shown confirming
  /// what's being shown.
  final String? initialIngredientFilter;

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  late Future<List<Map<String, dynamic>>> _recipes;
  String _selectedFilter = 'AI Picks';
  final TextEditingController _searchController = TextEditingController();
  String? _aiRecommendedName;

  final List<String> _filters = [
    'AI Picks',
    'Quick',
    'Healthy',
    'Saved',
    'Cooked',
  ];

  final List<List<Color>> _gradients = [
    [Color(0xFF7B341E), Color(0xFFC05621)],
    [Color(0xFF713F12), Color(0xFFC6862A)],
    [Color(0xFF3B0764), Color(0xFF7C3AED)],
    [Color(0xFF7B341E), Color(0xFFC05621)],
    [Color(0xFF1A4731), Color(0xFF2D6A4F)],
  ];

  @override
  void initState() {
    super.initState();
    _recipes = ApiService.getRecipesDetailed();
    _searchController.addListener(() => setState(() {}));
    _loadStores();
    _loadAiRecommendation();

    final ingredient = widget.initialIngredientFilter;
    if (ingredient != null) {
      _searchController.text = ingredient;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Recipes using $ingredient")),
        );
      });
    }
  }

  Future<void> _loadAiRecommendation() async {
    try {
      final name = await ApiService.getAiRecommendation();
      if (mounted) setState(() => _aiRecommendedName = name);
    } catch (_) {
      // AI recommendation is a nice-to-have — silently skip on failure.
    }
  }

  Future<void> _openAiRecommendation() async {
    final name = _aiRecommendedName;
    if (name == null) return;
    final items = await _recipes;
    final match = items.firstWhere(
      (r) => r['name']?.toString() == name,
      orElse: () => {},
    );
    if (match.isEmpty || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(recipe: RecipeDetail.fromJson(match)),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStores() async {
    await SavedRecipesStore.load();
    await CookedHistoryStore.load();
    if (mounted) setState(() {});
  }

  void _refresh() {
    setState(() {
      _recipes = ApiService.getRecipesDetailed();
    });
  }

  int _minutesOf(dynamic prepTime) {
    final match = RegExp(r'\d+').firstMatch(prepTime?.toString() ?? '');
    return match != null ? int.parse(match.group(0)!) : 999;
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> recipes) {
    Iterable<Map<String, dynamic>> result = recipes;

    switch (_selectedFilter) {
      case 'AI Picks':
        result = List<Map<String, dynamic>>.of(result)
          ..sort((a, b) => ((b['match_score'] ?? 0) as num)
              .compareTo((a['match_score'] ?? 0) as num));
        break;
      case 'Quick':
        result = result.where((r) => _minutesOf(r['prep_time']) <= 20);
        break;
      case 'Healthy':
        result = result.where((r) {
          final tags = (r['diet_tags'] as List?) ?? [];
          return tags.any((t) => t.toString().toLowerCase() == 'healthy');
        });
        break;
      case 'Saved':
        result = result.where(
          (r) => SavedRecipesStore.isSaved(r['name']?.toString() ?? ''),
        );
        break;
      case 'Cooked':
        final cookedNames =
            CookedHistoryStore.entries.map((e) => e.name).toSet();
        result = result.where(
          (r) => cookedNames.contains(r['name']?.toString() ?? ''),
        );
        break;
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((r) {
        final name = (r['name'] ?? '').toString().toLowerCase();
        if (name.contains(query)) return true;
        final ingredients = (r['ingredients'] as List?) ?? [];
        return ingredients
            .any((i) => i.toString().toLowerCase().contains(query));
      });
    }

    return result.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F6),
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          _buildFilterChips(),
          _buildAiBanner(),
          Expanded(child: _buildRecipeList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: const Color(0xFF1B4332),
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 12),
      child: Row(
        children: [
          const Text(
            'Recipes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                SizedBox(width: 4),
                Text(
                  'AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _refresh,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.refresh, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: const Color(0xFF1B4332),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              color: Colors.white.withValues(alpha: 0.5),
              size: 16,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search recipes...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      color: const Color(0xFFF5F8F6),
      padding: const EdgeInsets.fromLTRB(20, 16, 0, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = filter),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF1B4332) : Colors.white,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF1B4332)
                          : const Color(0xFFE4EDE7),
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    filter,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF6B7280),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAiBanner() {
    final name = _aiRecommendedName;
    if (name == null) return const SizedBox.shrink();

    return Container(
      color: const Color(0xFFF5F8F6),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: GestureDetector(
        onTap: _openAiRecommendation,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Pick for You',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white70, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _recipes,
      builder: (context, snapshot) {
        return AsyncStateBuilder<List<Map<String, dynamic>>>(
          snapshot: snapshot,
          onRetry: _refresh,
          isEmpty: (items) => _applyFilters(items).isEmpty,
          emptyIcon: Icons.restaurant,
          emptyTitle: 'No recipes found',
          emptySubtitle: 'Try a different search or filter',
          builder: (context, items) {
            final filtered = _applyFilters(items);
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final recipe = filtered[index];
                final gradient = _gradients[index % _gradients.length];
                return _buildRecipeCard(recipe, gradient);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe, List<Color> gradient) {
    final name = recipe['name'] ?? '';
    final isSaved = SavedRecipesStore.isSaved(name.toString());
    final isAiPick = _aiRecommendedName != null && name.toString() == _aiRecommendedName;
    final score = recipe['match_score'] ?? 0;
    final prepTime = recipe['prep_time'] ?? '20 min';
    final difficulty = recipe['difficulty'] ?? 'Easy';
    final dietTags = recipe['diet_tags'] as List?;
    final dietTag = dietTags != null && dietTags.isNotEmpty ? dietTags.first.toString() : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecipeDetailScreen(
              recipe: RecipeDetail.fromJson(recipe),
            ),
          ),
        ),
        child: Container(
          height: 112,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            border: isAiPick
                ? Border.all(color: const Color(0xFFFFD700), width: 2)
                : null,
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Colors.white54,
                          size: 10,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          prepTime,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildTag(difficulty),
                        if (dietTag != null) ...[
                          const SizedBox(width: 6),
                          _buildTag(dietTag),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$score%',
                    style: const TextStyle(
                      color: Color(0xFF1B4332),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: GestureDetector(
                  onTap: () async {
                    await SavedRecipesStore.toggle(name.toString());
                    if (mounted) setState(() {});
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      size: 14,
                      color: const Color(0xFF1B4332),
                    ),
                  ),
                ),
              ),
              if (isAiPick)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 10, color: Color(0xFF1B4332)),
                        SizedBox(width: 3),
                        Text(
                          'AI Recommended',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B4332),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 9),
      ),
    );
  }
}
