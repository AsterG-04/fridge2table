import 'package:flutter/material.dart';

import '../constants/colors.dart';

class WasteControlScreen extends StatefulWidget {
  const WasteControlScreen({super.key});

  @override
  State<WasteControlScreen> createState() => _WasteControlScreenState();
}

class _WasteControlScreenState extends State<WasteControlScreen> {
  int _tab = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _query => _searchController.text.trim().toLowerCase();

  bool _matchesQuery(String text) => text.toLowerCase().contains(_query);

  static const List<Map<String, Object>> _regrowItems = [
    {
      "icon": Icons.eco_outlined,
      "name": "Coriander (Cilantro) Roots",
      "scrap": "Scrap: Roots from coriander bunch",
      "method": "Water bottle / jar",
      "time": "7–10 days",
      "difficulty": "Very Easy",
      "steps": [
        "Save the roots when you trim a coriander bunch",
        "Place the roots in a jar with a little water, keeping leaves above the waterline",
        "Change the water every 2–3 days and place in indirect light until new growth appears",
      ],
    },
    {
      "icon": Icons.eco_outlined,
      "name": "Spring Onion (Scallion) Roots",
      "scrap": "Scrap: White root ends (2–3 cm)",
      "method": "Glass of water → Pot",
      "time": "5–7 days",
      "difficulty": "Very Easy",
      "steps": [
        "Save the white root ends after slicing off the green tops",
        "Stand them upright in a glass with a little water",
        "Once new green shoots are a few cm tall, transplant into soil for continued growth",
      ],
    },
    {
      "icon": Icons.spa_outlined,
      "name": "Ginger Root Piece",
      "scrap": "Scrap: Any knob of ginger with a bud",
      "method": "Pot with soil",
      "time": "2–3 weeks to sprout",
      "difficulty": "Easy",
      "steps": [
        "Choose a ginger piece with at least one visible bud or 'eye'",
        "Plant it bud-up, just under the surface of moist potting soil",
        "Keep warm and lightly watered until a shoot emerges",
      ],
    },
    {
      "icon": Icons.grass_outlined,
      "name": "Celery Base",
      "scrap": "Scrap: 2 cm bottom base of celery",
      "method": "Water dish → Pot",
      "time": "3–5 days for sprouts",
      "difficulty": "Easy",
      "steps": [
        "Cut off the base of the celery bunch, keeping about 2 cm",
        "Stand it in a shallow dish with water, cut-side up",
        "Once new leaves sprout from the centre, transplant into soil",
      ],
    },
    {
      "icon": Icons.eco_outlined,
      "name": "Lettuce Base",
      "scrap": "Scrap: Root end left over after using the leaves",
      "method": "Regrow in water",
      "time": "10–14 days",
      "difficulty": "Very Easy",
      "steps": [
        "Save the root end left after removing the outer leaves",
        "Place it in a shallow dish with about 1 cm of water",
        "Keep in indirect light, changing the water every few days, until new leaves form",
      ],
    },
    {
      "icon": Icons.park_outlined,
      "name": "Pineapple Top",
      "scrap": "Scrap: Leafy crown twisted off the top",
      "method": "Plant in soil",
      "time": "4–6 weeks to root",
      "difficulty": "Medium",
      "steps": [
        "Twist or cut the leafy crown off the top of the pineapple",
        "Remove the bottom few rows of leaves to expose the stem, then let it dry for a day",
        "Plant in well-draining soil and keep lightly watered until roots establish",
      ],
    },
    {
      "icon": Icons.forest_outlined,
      "name": "Avocado Seed",
      "scrap": "Scrap: The pit left after eating the avocado",
      "method": "Toothpicks in water → Pot",
      "time": "2–8 weeks to sprout",
      "difficulty": "Medium",
      "steps": [
        "Wash the pit and insert 3–4 toothpicks around its middle",
        "Suspend it over a glass of water, wide end down, so the base stays submerged",
        "Once roots and a stem sprout, transplant into a pot with soil",
      ],
    },
    {
      "icon": Icons.grass_outlined,
      "name": "Green Onion Roots",
      "scrap": "Scrap: White root ends left after slicing",
      "method": "Regrow in a water glass",
      "time": "4–6 days",
      "difficulty": "Very Easy",
      "steps": [
        "Save the white root ends after slicing the green parts for cooking",
        "Place them upright in a glass with a little water",
        "Snip off new green growth as needed and keep the water topped up",
      ],
    },
    {
      "icon": Icons.spa_outlined,
      "name": "Basil Stems",
      "scrap": "Scrap: Leftover stems with a node or two",
      "method": "Root in water → Plant in soil",
      "time": "1–2 weeks to root",
      "difficulty": "Easy",
      "steps": [
        "Cut stems with at least one leaf node, then remove the lowest leaves",
        "Place in a glass of water so the node stays submerged",
        "Once roots are a few cm long, transplant into a pot with soil",
      ],
    },
  ];

  static const List<Map<String, Object>> _scrapRecipes = [
    {
      "icon": Icons.local_fire_department_outlined,
      "name": "Vegetable Peel Chips",
      "scrap": "Scrap: Potato or carrot peels",
      "steps": [
        "Wash the peels thoroughly",
        "Toss with olive oil and a pinch of salt",
        "Spread in a single layer on a baking tray",
        "Bake at 180°C for 12–15 min until crispy",
      ],
      "time": "15 min",
      "difficulty": "Very Easy",
    },
    {
      "icon": Icons.local_cafe_outlined,
      "name": "Citrus Peel Tea",
      "scrap": "Scrap: Orange or lemon peel",
      "steps": [
        "Wash the peel to remove wax or residue",
        "Add the peel to a cup of hot water",
        "Steep for 5–10 minutes",
        "Add honey to taste and serve",
      ],
      "time": "10 min",
      "difficulty": "Very Easy",
    },
    {
      "icon": Icons.bakery_dining_outlined,
      "name": "Stale Bread Croutons",
      "scrap": "Scrap: Bread that's gone stale",
      "steps": [
        "Cube the stale bread",
        "Toss with olive oil, garlic powder and salt",
        "Spread on a baking tray",
        "Bake at 180°C for 10 min until golden and crisp",
      ],
      "time": "15 min",
      "difficulty": "Easy",
    },
    {
      "icon": Icons.soup_kitchen_outlined,
      "name": "Bone Broth",
      "scrap": "Scrap: Leftover meat or chicken bones",
      "steps": [
        "Place the bones in a large pot with water",
        "Add onion, carrot and celery scraps",
        "Simmer on low for 4–6 hours (or 45 min in a pressure cooker)",
        "Strain and store in the fridge or freezer",
      ],
      "time": "4+ hrs",
      "difficulty": "Easy",
    },
    {
      "icon": Icons.cake_outlined,
      "name": "Apple Core Jelly",
      "scrap": "Scrap: Apple cores and peels",
      "steps": [
        "Simmer apple cores and peels in water for 30 minutes",
        "Strain the liquid, pressing to extract as much as possible",
        "Return the liquid to the pot with sugar and lemon juice",
        "Boil until it thickens, then pour into a clean jar to set",
      ],
      "time": "45 min",
      "difficulty": "Medium",
    },
    {
      "icon": Icons.icecream_outlined,
      "name": "Watermelon Rind Pickles",
      "scrap": "Scrap: The white rind left after eating watermelon",
      "steps": [
        "Peel off the tough green skin and cube the white rind",
        "Boil the rind in water until just tender, then drain",
        "Simmer with vinegar, sugar and pickling spices",
        "Pack into a jar with the brine and chill before eating",
      ],
      "time": "30 min",
      "difficulty": "Easy",
    },
    {
      "icon": Icons.grass_outlined,
      "name": "Carrot Top Pesto",
      "scrap": "Scrap: Leafy carrot tops",
      "steps": [
        "Wash the carrot tops thoroughly to remove grit",
        "Blend with garlic, nuts, parmesan and olive oil",
        "Season with salt and a squeeze of lemon",
        "Toss through pasta or spread on toast",
      ],
      "time": "10 min",
      "difficulty": "Very Easy",
    },
    {
      "icon": Icons.soup_kitchen_outlined,
      "name": "Onion Skin Broth",
      "scrap": "Scrap: Onion skins and ends",
      "steps": [
        "Save onion skins and ends in a bag in the freezer until you have enough",
        "Simmer the skins in water with other vegetable scraps for 45 minutes",
        "Strain out the solids",
        "Use the golden broth as a base for soups and stews",
      ],
      "time": "50 min",
      "difficulty": "Very Easy",
    },
  ];

  static const List<Map<String, Object>> _compostYes = [
    {
      "name": "Fruit peels and cores",
      "description": "Banana peels, apple cores, citrus rinds and more break "
          "down easily and add valuable nutrients to compost.",
      "steps": [
        "Chop larger peels and cores into smaller pieces",
        "Add to your compost pile or bin",
        "Turn occasionally to mix with other layers",
      ],
      "time": "2–4 weeks to break down",
      "difficulty": "Very Easy",
    },
    {
      "name": "Vegetable scraps and trimmings",
      "description": "Carrot tops, potato peels, onion ends and other "
          "vegetable trimmings compost quickly and boost soil nutrients.",
      "steps": [
        "Collect trimmings in a container as you cook",
        "Add to your compost pile, chopping larger pieces first",
        "Mix with dry material like leaves or paper as you go",
      ],
      "time": "2–4 weeks to break down",
      "difficulty": "Very Easy",
    },
    {
      "name": "Eggshells (crushed)",
      "description": "Eggshells add calcium to compost but break down slowly "
          "unless crushed first.",
      "steps": [
        "Rinse shells to remove any egg residue",
        "Crush into small pieces or grind into a powder",
        "Mix thoroughly into the compost pile",
      ],
      "time": "6–12 months (crushed)",
      "difficulty": "Easy",
    },
    {
      "name": "Coffee grounds and tea leaves",
      "description": "Used coffee grounds and tea leaves are nitrogen-rich "
          "additions that help speed up composting.",
      "steps": [
        "Let grounds or leaves cool completely before adding",
        "Mix into the compost pile so they don't clump together",
        "Balance with dry material like leaves or shredded paper",
      ],
      "time": "2–4 weeks to break down",
      "difficulty": "Very Easy",
    },
  ];

  static const List<Map<String, Object>> _compostNo = [
    {
      "name": "Meat and bones",
      "description": "Meat and bones attract pests and rot rather than "
          "compost in a typical home bin.",
      "steps": [
        "Avoid adding meat or bones to your compost pile",
        "Use bones for a homemade stock or broth instead if possible",
        "Dispose of remaining scraps in regular waste",
      ],
      "time": "Not compostable at home",
      "difficulty": "Avoid",
    },
    {
      "name": "Dairy products",
      "description": "Dairy can attract pests and create odor problems in "
          "home compost systems.",
      "steps": [
        "Avoid adding dairy to your compost pile",
        "Look into industrial/municipal composting services if available",
        "Dispose of leftover dairy in regular waste otherwise",
      ],
      "time": "Not compostable at home",
      "difficulty": "Avoid",
    },
    {
      "name": "Oily or greasy food",
      "description": "Oils and grease coat other materials and slow down "
          "the composting process, and can attract pests.",
      "steps": [
        "Avoid pouring oil or grease directly into compost",
        "Wipe greasy containers clean before recycling or disposing of them",
        "Dispose of excess oil in regular waste, not the drain or compost",
      ],
      "time": "Not compostable at home",
      "difficulty": "Avoid",
    },
  ];

  static const List<String> _compostSteps = [
    "Layer scraps with dry material like dried leaves or shredded paper",
    "Turn the pile every week or two to add air and speed up decomposition",
    "Keep it moist (like a wrung-out sponge) and wait 2–3 months for finished compost",
  ];

  void _showDetailSheet({
    required IconData icon,
    required String name,
    required String description,
    required List<String> steps,
    required String time,
    required String difficulty,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.lightGreen,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: AppColors.darkGreen, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                description,
                style: const TextStyle(color: AppColors.textGray, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _infoPill(time, const Color(0xFFFEF9C3), const Color(0xFF966200)),
                  _infoPill(difficulty, const Color(0xFFEAFAF1), const Color(0xFF1D6A3A)),
                ],
              ),
              if (steps.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  "Steps",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 12),
                for (int i = 0; i < steps.length; i++)
                  Padding(
                    padding: EdgeInsets.only(bottom: i == steps.length - 1 ? 0 : 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.only(top: 1),
                          decoration: const BoxDecoration(color: AppColors.darkGreen, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Text(
                            "${i + 1}",
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            steps[i],
                            style: const TextStyle(color: AppColors.textGray, fontSize: 13, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    "Got it!",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
          const SizedBox(height: 12),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.white.withValues(alpha: 0.5), size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search tips and recipes...',
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
          if (_query.isNotEmpty)
            GestureDetector(
              onTap: () => _searchController.clear(),
              child: Icon(Icons.close, color: Colors.white.withValues(alpha: 0.5), size: 16),
            ),
        ],
      ),
    );
  }

  Widget _noResults() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          "No results for \"${_searchController.text.trim()}\"",
          style: const TextStyle(color: AppColors.textGray, fontSize: 13),
        ),
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
        return _buildScrapRecipesTab();
      default:
        return _buildCompostTab();
    }
  }

  Widget _buildRegrowTab() {
    final items = _regrowItems.where((item) =>
        _matchesQuery(item["name"] as String) || _matchesQuery(item["scrap"] as String));

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
        if (items.isEmpty)
          _noResults()
        else
          for (final item in items) ...[
            _regrowCard(item),
            const SizedBox(height: 12),
          ],
      ],
    );
  }

  Widget _regrowCard(Map<String, Object> item) {
    return GestureDetector(
      onTap: () => _showDetailSheet(
        icon: item["icon"] as IconData,
        name: item["name"] as String,
        description: item["scrap"] as String,
        steps: (item["steps"] as List).cast<String>(),
        time: item["time"] as String,
        difficulty: item["difficulty"] as String,
      ),
      child: Container(
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

  Widget _buildScrapRecipesTab() {
    final items = _scrapRecipes.where((item) =>
        _matchesQuery(item["name"] as String) || _matchesQuery(item["scrap"] as String));

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
              const Icon(Icons.restaurant_menu, size: 16, color: AppColors.darkGreen),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Turn scraps you'd normally throw away into something "
                  "you can actually eat or drink.",
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
        if (items.isEmpty)
          _noResults()
        else
          for (final item in items) ...[
            _scrapRecipeCard(item),
            const SizedBox(height: 12),
          ],
      ],
    );
  }

  Widget _scrapRecipeCard(Map<String, Object> item) {
    final steps = item["steps"] as List<String>;

    return GestureDetector(
      onTap: () => _showDetailSheet(
        icon: item["icon"] as IconData,
        name: item["name"] as String,
        description: item["scrap"] as String,
        steps: steps,
        time: item["time"] as String,
        difficulty: item["difficulty"] as String,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
            const SizedBox(height: 12),
            const Divider(color: AppColors.borderGreen, height: 1),
            const SizedBox(height: 12),
            for (int i = 0; i < steps.length; i++)
              Padding(
                padding: EdgeInsets.only(bottom: i == steps.length - 1 ? 0 : 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: const BoxDecoration(color: AppColors.lightGreen, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(
                        "${i + 1}",
                        style: const TextStyle(color: AppColors.darkGreen, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        steps[i],
                        style: const TextStyle(color: AppColors.textGray, fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompostTab() {
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
              const Icon(Icons.compost_outlined, size: 16, color: AppColors.darkGreen),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Composting turns scraps you can't eat into nutrient-rich "
                  "soil instead of landfill waste.",
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
        Builder(builder: (context) {
          bool matches(Map<String, Object> item) =>
              _matchesQuery(item["name"] as String) ||
              _matchesQuery(item["description"] as String);
          final yes = _compostYes.where(matches).toList();
          final no = _compostNo.where(matches).toList();

          if (_query.isNotEmpty && yes.isEmpty && no.isEmpty) {
            return _noResults();
          }

          return Column(
            children: [
              if (yes.isNotEmpty) ...[
                _compostListCard(
                  title: "Can Compost",
                  icon: Icons.check_circle,
                  iconColor: AppColors.chipGreenText,
                  items: yes,
                ),
                const SizedBox(height: 12),
              ],
              if (no.isNotEmpty) ...[
                _compostListCard(
                  title: "Cannot Compost",
                  icon: Icons.cancel,
                  iconColor: const Color(0xFFC0392B),
                  items: no,
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        }),
        _compostStepsCard(),
        const SizedBox(height: 12),
        _compostFunFactCard(),
      ],
    );
  }

  Widget _compostListCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Map<String, Object>> items,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          for (final item in items) ...[
            GestureDetector(
              onTap: () => _showDetailSheet(
                icon: icon,
                name: item["name"] as String,
                description: item["description"] as String,
                steps: (item["steps"] as List).cast<String>(),
                time: item["time"] as String,
                difficulty: item["difficulty"] as String,
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(icon, size: 15, color: iconColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item["name"] as String,
                        style: const TextStyle(color: AppColors.textGray, fontSize: 13),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textGray, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _compostStepsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("How to Compost", style: TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          for (int i = 0; i < _compostSteps.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == _compostSteps.length - 1 ? 0 : 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(color: AppColors.darkGreen, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(
                      "${i + 1}",
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _compostSteps[i],
                      style: const TextStyle(color: AppColors.textGray, fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _compostFunFactCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.lightGreen, borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, size: 18, color: AppColors.darkGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Fun fact", style: TextStyle(color: AppColors.darkGreen, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text(
                  "Composting 1 kg of food waste saves about 0.5 kg of CO₂ "
                  "compared to sending it to landfill.",
                  style: TextStyle(color: AppColors.textDark, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
