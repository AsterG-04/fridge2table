import 'package:flutter/material.dart';

import '../constants/colors.dart';

class WasteControlScreen extends StatefulWidget {
  /// Which tab to land on (0 = Regrow, 1 = Scrap Recipes, 2 = Compost) --
  /// lets Expiry Monitor deep-link an expired item straight to the
  /// relevant section instead of always opening on Regrow.
  final int initialTab;

  /// Pre-fills the search box so the deep link also filters down to a
  /// specific ingredient where a direct match exists (e.g. "milk").
  final String initialSearch;

  const WasteControlScreen({
    super.key,
    this.initialTab = 0,
    this.initialSearch = "",
  });

  @override
  State<WasteControlScreen> createState() => _WasteControlScreenState();
}

class _WasteControlScreenState extends State<WasteControlScreen> {
  late int _tab;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    _searchController = TextEditingController(text: widget.initialSearch);
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
    {
      "icon": Icons.eco_outlined,
      "name": "Garlic Sprouts",
      "scrap": "Scrap: A clove that's already started sprouting",
      "method": "Pot with soil",
      "time": "1–2 weeks to sprout",
      "difficulty": "Very Easy",
      "steps": [
        "Plant the sprouting clove root-down, just under the soil surface",
        "Keep in a sunny spot and water lightly",
        "Snip the green shoots as garlic chives, or let it grow a full new bulb over a season",
      ],
    },
    {
      "icon": Icons.grass_outlined,
      "name": "Bok Choy Base",
      "scrap": "Scrap: Root end left over after using the leaves",
      "method": "Water dish → Pot",
      "time": "7–10 days for new growth",
      "difficulty": "Very Easy",
      "steps": [
        "Save the root end after trimming off the leaves",
        "Stand it in a shallow dish with a little water, cut-side up",
        "Once new leaves sprout from the centre, transplant into soil for a full second head",
      ],
    },
    {
      "icon": Icons.spa_outlined,
      "name": "Potato Eyes",
      "scrap": "Scrap: Potato peels or pieces with an eye/bud attached",
      "method": "Pot with soil",
      "time": "2–4 weeks to sprout",
      "difficulty": "Easy",
      "steps": [
        "Let the piece with an eye dry out for a day so it doesn't rot",
        "Plant it eye-up, a few cm deep in loose soil",
        "Keep watered and mound soil around the stem as it grows",
      ],
    },
    {
      "icon": Icons.spa_outlined,
      "name": "Turmeric Root Piece",
      "scrap": "Scrap: Any knob of turmeric with a visible bud",
      "method": "Pot with soil",
      "time": "2–3 weeks to sprout",
      "difficulty": "Easy",
      "steps": [
        "Choose a turmeric piece with at least one bud or 'eye'",
        "Plant it bud-up, just under the surface of moist potting soil",
        "Keep warm and humid until a shoot emerges, similar to ginger",
      ],
    },
    {
      "icon": Icons.eco_outlined,
      "name": "Onion Root End",
      "scrap": "Scrap: The root base left after chopping an onion",
      "method": "Pot with soil",
      "time": "1–2 weeks to sprout",
      "difficulty": "Easy",
      "steps": [
        "Save about 1-2 cm of the root end when you chop an onion",
        "Let it dry for a few hours, then plant root-down in soil",
        "Keep lightly watered — green shoots can be snipped and used like chives while a new bulb forms",
      ],
    },
    {
      "icon": Icons.grass_outlined,
      "name": "Fennel Base",
      "scrap": "Scrap: The root base left after slicing a fennel bulb",
      "method": "Water dish → Pot",
      "time": "1–2 weeks for new fronds",
      "difficulty": "Easy",
      "steps": [
        "Cut off the base of the bulb, keeping about 2 cm",
        "Stand it in a shallow dish with a little water, cut-side up",
        "Once new feathery fronds appear, transplant into soil to keep growing",
      ],
    },
    {
      "icon": Icons.spa_outlined,
      "name": "Sweet Potato Slip",
      "scrap": "Scrap: A whole sweet potato, or a larger end piece",
      "method": "Toothpicks in water → Pot",
      "time": "3–4 weeks to sprout slips",
      "difficulty": "Medium",
      "steps": [
        "Insert toothpicks around the middle and suspend half-submerged in a glass of water",
        "Wait for small purple-green shoots (\"slips\") to grow from the submerged half",
        "Twist off slips once they have a few leaves and root them in water before planting in soil",
      ],
    },
    {
      "icon": Icons.grass_outlined,
      "name": "Root Vegetable Tops (Beet, Turnip, Carrot)",
      "scrap": "Scrap: The crown/top sliced off a beet, turnip or carrot",
      "method": "Shallow water dish",
      "time": "5–7 days for new leaves",
      "difficulty": "Very Easy",
      "steps": [
        "Slice off the top 1-2 cm of the root, keeping the crown intact",
        "Set it cut-side down in a shallow dish with a little water",
        "New leafy greens will sprout from the top within about a week — snip and use like any leafy green (note: this regrows greens only, not another full root)",
      ],
    },
    {
      "icon": Icons.eco_outlined,
      "name": "Napa Cabbage Base",
      "scrap": "Scrap: Root end left over after using the leaves",
      "method": "Water dish → Pot",
      "time": "7–10 days for new growth",
      "difficulty": "Very Easy",
      "steps": [
        "Save the root end after trimming off the leaves",
        "Stand it in a shallow dish with a little water, cut-side up",
        "Once new leaves sprout from the centre, transplant into soil for a full second head",
      ],
    },
    {
      "icon": Icons.grass_outlined,
      "name": "Leek Base",
      "scrap": "Scrap: The white root base left after slicing a leek",
      "method": "Glass of water → Pot",
      "time": "1–2 weeks to regrow",
      "difficulty": "Easy",
      "steps": [
        "Save about 2-3 cm of the white root end",
        "Stand it upright in a glass with a little water",
        "Once new green growth appears, transplant into soil for continued growth",
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
    {
      "icon": Icons.restaurant_menu,
      "name": "Broccoli Stem Slaw",
      "scrap": "Scrap: Broccoli stems usually cut off and binned",
      "steps": [
        "Peel the tough outer layer off the stems",
        "Grate or julienne the peeled stems",
        "Toss with a squeeze of lemon, olive oil and a pinch of salt",
        "Serve as a crunchy slaw alongside anything",
      ],
      "time": "10 min",
      "difficulty": "Very Easy",
    },
    {
      "icon": Icons.local_fire_department_outlined,
      "name": "Banana Peel \"Bacon\"",
      "scrap": "Scrap: Banana peels",
      "steps": [
        "Wash the peels and slice into thin strips",
        "Toss with soy sauce, smoked paprika and a little oil",
        "Bake at 190°C for 15-20 min, flipping halfway, until crisp at the edges",
        "Use as a smoky, chewy topping or snack",
      ],
      "time": "20 min",
      "difficulty": "Easy",
    },
    {
      "icon": Icons.grass_outlined,
      "name": "Herb Stem Pesto",
      "scrap": "Scrap: Leftover parsley, cilantro or basil stems",
      "steps": [
        "Wash the stems well",
        "Blend with garlic, nuts or seeds, parmesan and olive oil",
        "Season with salt and a squeeze of lemon",
        "Use like a regular pesto on pasta, toast or roasted vegetables",
      ],
      "time": "10 min",
      "difficulty": "Very Easy",
    },
    {
      "icon": Icons.local_drink_outlined,
      "name": "Homemade Yogurt or Paneer",
      "scrap": "Scrap: Milk that's about to turn or just past its date",
      "steps": [
        "Heat the milk to a gentle simmer, stirring so it doesn't catch on the pan",
        "For yogurt: cool until warm, stir in a spoonful of live yogurt as a starter, then leave covered somewhere warm for 6-8 hours",
        "For paneer instead: add a splash of lemon juice or vinegar until it visibly curdles, then strain through a clean cloth",
        "Chill and use within a few days",
      ],
      "time": "6+ hrs (yogurt) / 30 min (paneer)",
      "difficulty": "Easy",
    },
    {
      "icon": Icons.soup_kitchen_outlined,
      "name": "Cheese Rind Broth",
      "scrap": "Scrap: Parmesan or hard cheese rinds",
      "steps": [
        "Save rinds in a bag in the freezer until you have a few",
        "Add them to a pot of simmering soup, stock or tomato sauce",
        "Let them simmer for at least 20 minutes to release flavour",
        "Fish out the softened rind before serving",
      ],
      "time": "25 min",
      "difficulty": "Very Easy",
    },
    {
      "icon": Icons.water_drop_outlined,
      "name": "Rice Water (Fertilizer or Hair Rinse)",
      "scrap": "Scrap: The cloudy water left from rinsing or cooking rice",
      "steps": [
        "Save the cloudy water after rinsing raw rice, or let cooked rice water cool",
        "For plants: dilute with equal parts water and use to water houseplants",
        "For hair: use fresh as a final rinse after shampooing, then rinse out if desired",
        "Don't store it more than a day or two — it sours quickly at room temperature",
      ],
      "time": "5 min",
      "difficulty": "Very Easy",
    },
    {
      "icon": Icons.soup_kitchen_outlined,
      "name": "Mixed Vegetable Scrap Stock",
      "scrap":
          "Scrap: Carrot peels, celery ends, onion skins and other veg trimmings",
      "steps": [
        "Collect vegetable trimmings in a bag in the freezer as you cook",
        "Once you have a full bag, simmer them in water for 45 minutes",
        "Strain out the solids",
        "Use the stock as a base for soups, stews and risottos",
      ],
      "time": "50 min",
      "difficulty": "Very Easy",
    },
    {
      "icon": Icons.local_cafe_outlined,
      "name": "Citrus Peel Powder",
      "scrap": "Scrap: Orange, lemon or lime peels",
      "steps": [
        "Wash the peels to remove any wax or residue",
        "Dry them in a low oven or air-dry for a day or two until brittle",
        "Blitz in a blender or spice grinder until powdered",
        "Use as a zesty seasoning or baking flavouring",
      ],
      "time": "15 min active",
      "difficulty": "Easy",
    },
    {
      "icon": Icons.grass_outlined,
      "name": "Herb Stem Oil",
      "scrap": "Scrap: Leftover parsley, basil or cilantro stems",
      "steps": [
        "Wash the stems well",
        "Blitz with a neutral oil in a blender until smooth",
        "Strain through a fine sieve or cloth",
        "Use as a finishing drizzle over soups, roasted vegetables or grilled meat",
      ],
      "time": "10 min",
      "difficulty": "Very Easy",
    },
    {
      "icon": Icons.icecream_outlined,
      "name": "Overripe Fruit Smoothie Packs",
      "scrap": "Scrap: Bananas, berries or mango that have gone very soft",
      "steps": [
        "Peel and chop the fruit as needed",
        "Portion into freezer bags, one smoothie's worth per bag",
        "Freeze flat so they stack easily",
        "Blend straight from frozen with milk or yogurt for a quick smoothie",
      ],
      "time": "10 min",
      "difficulty": "Very Easy",
    },
  ];

  static const List<Map<String, Object>> _compostYes = [
    {
      "name": "Fruit peels and cores",
      "description":
          "Banana peels, apple cores, citrus rinds and more break "
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
      "description":
          "Carrot tops, potato peels, onion ends and other "
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
      "description":
          "Eggshells add calcium to compost but break down slowly "
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
      "description":
          "Used coffee grounds and tea leaves are nitrogen-rich "
          "additions that help speed up composting.",
      "steps": [
        "Let grounds or leaves cool completely before adding",
        "Mix into the compost pile so they don't clump together",
        "Balance with dry material like leaves or shredded paper",
      ],
      "time": "2–4 weeks to break down",
      "difficulty": "Very Easy",
    },
    {
      "name": "Nut and seed shells (crushed)",
      "description":
          "Shells add texture and slow-release nutrients, but "
          "break down very slowly whole — crush them first.",
      "steps": [
        "Crush or grind shells into smaller pieces",
        "Mix thoroughly into the compost pile rather than leaving them in a clump",
        "Be patient — even crushed, these take longer than soft scraps",
      ],
      "time": "6–12 months (crushed)",
      "difficulty": "Easy",
    },
    {
      "name": "Stale bread and grains (in moderation)",
      "description":
          "Small amounts of bread, rice or pasta break down fine, "
          "but too much at once can mould and attract pests.",
      "steps": [
        "Tear or break bread into small pieces first",
        "Mix in a thin layer, not a dense clump",
        "Balance with plenty of dry material like leaves or shredded paper",
      ],
      "time": "2–4 weeks to break down",
      "difficulty": "Easy",
    },
  ];

  static const List<Map<String, Object>> _compostNo = [
    {
      "name": "Meat and bones",
      "description":
          "Meat and bones attract pests and rot rather than "
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
      "description":
          "Dairy can attract pests and create odor problems in "
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
      "description":
          "Oils and grease coat other materials and slow down "
          "the composting process, and can attract pests.",
      "steps": [
        "Avoid pouring oil or grease directly into compost",
        "Wipe greasy containers clean before recycling or disposing of them",
        "Dispose of excess oil in regular waste, not the drain or compost",
      ],
      "time": "Not compostable at home",
      "difficulty": "Avoid",
    },
    {
      "name": "Processed or salty snack foods",
      "description":
          "Chips, ready meals and heavily salted leftovers can "
          "throw off the compost pile's microbial balance and attract pests.",
      "steps": [
        "Avoid adding processed or heavily salted foods to your compost pile",
        "Scrape plates into regular waste instead for anything highly seasoned or processed",
        "Stick to plain fruit, vegetable and grain scraps for the pile",
      ],
      "time": "Not compostable at home",
      "difficulty": "Avoid",
    },
  ];

  // Comparison of home composting setups, since "compost" implicitly assumes
  // a backyard bin -- many users won't have outdoor space at all, which is
  // exactly what the apartment/indoor-friendly options here cover.
  static const List<Map<String, String>> _compostMethods = [
    {
      "name": "Backyard Bin",
      "bestFor": "Best for: Homes with outdoor space",
      "description":
          "A traditional open or enclosed bin outdoors. Needs occasional "
          "turning and a mix of wet and dry scraps, but handles the most volume.",
    },
    {
      "name": "Bokashi Bin",
      "bestFor": "Best for: Apartments and small kitchens",
      "description":
          "A sealed bucket that ferments scraps with a bran inoculant instead "
          "of decomposing them in open air — compact and low-odor, and can even "
          "handle small amounts of meat and dairy that regular composting can't.",
    },
    {
      "name": "Vermicomposting (Worm Bin)",
      "bestFor": "Best for: Small spaces, indoors or a balcony",
      "description":
          "Red wiggler worms break down scraps into nutrient-rich castings "
          "inside a small bin. Needs a steady but light feeding schedule, and "
          "avoids citrus, onion and meat.",
    },
    {
      "name": "Community Compost Drop-Off",
      "bestFor": "Best for: No outdoor space or equipment at all",
      "description":
          "Many cities, farmers markets or community gardens collect food "
          "scraps for composting elsewhere — just save scraps in a container "
          "and drop them off on a schedule.",
    },
  ];

  static const List<String> _compostSteps = [
    "Layer scraps with dry material like dried leaves or shredded paper",
    "Turn the pile every week or two to add air and speed up decomposition",
    "Keep it moist (like a wrung-out sponge) and wait 2–3 months for finished compost",
    "Chop larger scraps into smaller pieces first — smaller pieces break down faster",
    "Keep a roughly even mix of \"greens\" (wet scraps) and \"browns\" (dry material) so the pile doesn't turn slimy or smelly",
  ];

  // Storage tips prevent waste before it happens, rather than salvaging
  // scraps after the fact like the other three tabs -- "time" here means
  // the freshness/shelf-life benefit rather than a cook or growth time, to
  // keep reusing the same pill/card layout as Regrow and Scrap Recipes.
  static const List<Map<String, Object>> _storageTips = [
    {
      "icon": Icons.eco_outlined,
      "name": "Leafy Greens (Paper Towel Trick)",
      "scrap": "Wrap washed greens in a dry paper towel before storing",
      "steps": [
        "Wash and thoroughly dry the greens",
        "Wrap them loosely in a dry paper towel",
        "Store in a bag or container in the crisper drawer",
        "Swap the towel for a dry one if it gets damp",
      ],
      "time": "+5-7 days freshness",
      "difficulty": "Very Easy",
    },
    {
      "icon": Icons.thermostat_outlined,
      "name": "Tomatoes (Keep Off the Fridge)",
      "scrap": "Cold temperatures break down texture and mute flavor",
      "steps": [
        "Store tomatoes at room temperature, out of direct sun",
        "Keep them stem-side down to reduce moisture loss",
        "Only refrigerate if already very ripe and you need to slow them down for a day or two",
        "Bring back to room temperature before eating for the best flavor",
      ],
      "time": "Better flavor & texture",
      "difficulty": "Very Easy",
    },
    {
      "icon": Icons.bakery_dining_outlined,
      "name": "Bread Storage: Freezer vs Counter vs Fridge",
      "scrap": "The fridge speeds up staling more than either alternative",
      "steps": [
        "Counter: keep in a paper or bread bag for 2-3 days",
        "Freezer: slice first, then freeze in an airtight bag for up to 3 months",
        "Avoid the fridge — it makes bread stale faster than room temperature or freezing",
        "Toast slices straight from frozen instead of thawing first",
      ],
      "time": "Up to 3 months (frozen)",
      "difficulty": "Very Easy",
    },
    {
      "icon": Icons.local_florist_outlined,
      "name": "Herb Storage (Stems in Water)",
      "scrap": "Treat soft herbs like a bouquet of cut flowers",
      "steps": [
        "Trim the stem ends",
        "Stand the herbs upright in a jar with a little water, like flowers",
        "Loosely cover the leaves with a plastic bag",
        "Change the water every few days — keep at room temp for basil, in the fridge for parsley/cilantro",
      ],
      "time": "+1-2 weeks freshness",
      "difficulty": "Very Easy",
    },
    {
      "icon": Icons.compare_arrows,
      "name": "Onion & Potato Separation",
      "scrap": "Stored together, onions make potatoes sprout faster",
      "steps": [
        "Store onions and potatoes in separate, well-ventilated spots",
        "Keep both away from direct light",
        "Use a paper bag or basket rather than a sealed plastic bag",
        "Check both regularly and remove any that start to soften",
      ],
      "time": "Slower sprouting",
      "difficulty": "Very Easy",
    },
    {
      "icon": Icons.timelapse_outlined,
      "name": "Banana Ripening Control",
      "scrap": "Bananas release ethylene gas that speeds up ripening nearby",
      "steps": [
        "To ripen faster: bunch bananas together with other fruit like apples",
        "To slow ripening: separate them from other fruit and wrap the stems in plastic wrap",
        "Once very ripe, peel and freeze for smoothies or baking instead of composting",
        "Store out of direct sunlight either way",
      ],
      "time": "Control by days",
      "difficulty": "Very Easy",
    },
    {
      "icon": Icons.forest_outlined,
      "name": "Avocado Ripening Control",
      "scrap": "Avocados only ripen off the tree — storage controls the speed",
      "steps": [
        "To ripen faster: store in a paper bag, optionally with a banana or apple",
        "To slow ripening: move a ripe avocado to the fridge, where it'll keep for several more days",
        "Check ripeness by gently pressing near the stem end",
        "Once cut, store with the pit in and lemon juice on the surface to slow browning",
      ],
      "time": "Control by days",
      "difficulty": "Very Easy",
    },
    {
      "icon": Icons.clean_hands_outlined,
      "name": "Berries (Vinegar Rinse Trick)",
      "scrap":
          "A quick vinegar bath kills the mold spores that spoil berries fast",
      "steps": [
        "Soak berries in a mix of 1 part vinegar to 3 parts water for a few minutes",
        "Rinse thoroughly and dry completely before storing",
        "Store in a container lined with a paper towel, uncovered or loosely covered",
        "Only wash the batch you're about to eat if storing long-term",
      ],
      "time": "+1 week freshness",
      "difficulty": "Easy",
    },
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
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                description,
                style: const TextStyle(
                  color: AppColors.textGray,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _infoPill(
                    time,
                    const Color(0xFFFEF9C3),
                    const Color(0xFF966200),
                  ),
                  _infoPill(
                    difficulty,
                    const Color(0xFFEAFAF1),
                    const Color(0xFF1D6A3A),
                  ),
                ],
              ),
              if (steps.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  "Steps",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                for (int i = 0; i < steps.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i == steps.length - 1 ? 0 : 10,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.only(top: 1),
                          decoration: const BoxDecoration(
                            color: AppColors.darkGreen,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "${i + 1}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            steps[i],
                            style: const TextStyle(
                              color: AppColors.textGray,
                              fontSize: 13,
                              height: 1.4,
                            ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "Got it!",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
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
          "Regrow kitchen scraps, find scrap-friendly recipes, learn how "
          "to compost what's left, or check Storage Tips to stop waste "
          "before it starts.",
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
          _buildHeader(),
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

  // Nav row and the tabs/search section below it are merged into a single
  // rounded-bottom Container rather than two stacked same-color Containers —
  // stacking two separately would leave a visible notch where the header's
  // own rounded corners reveal whatever sits directly behind/below it.
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.darkGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Padding(
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
                    "Waste Control",
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
                  onTap: _showHelp,
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
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Turn food scraps into something useful",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
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
                    const SizedBox(width: 8),
                    Expanded(child: _tabButton(3, "Storage Tips")),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSearchBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
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
              child: Icon(
                Icons.close,
                color: Colors.white.withValues(alpha: 0.5),
                size: 16,
              ),
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
          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(999),
          border: isActive
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? AppColors.darkGreen : Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
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
      case 2:
        return _buildCompostTab();
      default:
        return _buildStorageTipsTab();
    }
  }

  Widget _buildRegrowTab() {
    final items = _regrowItems.where(
      (item) =>
          _matchesQuery(item["name"] as String) ||
          _matchesQuery(item["scrap"] as String),
    );

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
                    fontWeight: FontWeight.w400,
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
              child: Icon(
                item["icon"] as IconData,
                color: AppColors.darkGreen,
                size: 22,
              ),
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
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item["scrap"] as String,
                    style: const TextStyle(
                      color: AppColors.textGray,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _infoPill(
                        item["method"] as String,
                        AppColors.lightGreen,
                        AppColors.darkGreen,
                      ),
                      _infoPill(
                        item["time"] as String,
                        const Color(0xFFFEF9C3),
                        const Color(0xFF966200),
                      ),
                      _infoPill(
                        item["difficulty"] as String,
                        const Color(0xFFEAFAF1),
                        const Color(0xFF1D6A3A),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textGray,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoPill(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildScrapRecipesTab() {
    final items = _scrapRecipes.where(
      (item) =>
          _matchesQuery(item["name"] as String) ||
          _matchesQuery(item["scrap"] as String),
    );

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
              const Icon(
                Icons.restaurant_menu,
                size: 16,
                color: AppColors.darkGreen,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Turn scraps you'd normally throw away into something "
                  "you can actually eat or drink.",
                  style: TextStyle(
                    color: AppColors.textGray,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
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
                  child: Icon(
                    item["icon"] as IconData,
                    color: AppColors.darkGreen,
                    size: 22,
                  ),
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
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item["scrap"] as String,
                        style: const TextStyle(
                          color: AppColors.textGray,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _infoPill(
                            item["time"] as String,
                            const Color(0xFFFEF9C3),
                            const Color(0xFF966200),
                          ),
                          _infoPill(
                            item["difficulty"] as String,
                            const Color(0xFFEAFAF1),
                            const Color(0xFF1D6A3A),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textGray,
                  size: 16,
                ),
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
                      decoration: const BoxDecoration(
                        color: AppColors.lightGreen,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "${i + 1}",
                        style: const TextStyle(
                          color: AppColors.darkGreen,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        steps[i],
                        style: const TextStyle(
                          color: AppColors.textGray,
                          fontSize: 12,
                          height: 1.4,
                        ),
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

  Widget _buildStorageTipsTab() {
    final items = _storageTips.where(
      (item) =>
          _matchesQuery(item["name"] as String) ||
          _matchesQuery(item["scrap"] as String),
    );

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
              const Icon(
                Icons.shield_outlined,
                size: 16,
                color: AppColors.darkGreen,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Store ingredients the right way and stop waste before "
                  "it starts.",
                  style: TextStyle(
                    color: AppColors.textGray,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
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
            _storageTipCard(item),
            const SizedBox(height: 12),
          ],
      ],
    );
  }

  Widget _storageTipCard(Map<String, Object> item) {
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
                  child: Icon(
                    item["icon"] as IconData,
                    color: AppColors.darkGreen,
                    size: 22,
                  ),
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
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item["scrap"] as String,
                        style: const TextStyle(
                          color: AppColors.textGray,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _infoPill(
                            item["time"] as String,
                            const Color(0xFFFEF9C3),
                            const Color(0xFF966200),
                          ),
                          _infoPill(
                            item["difficulty"] as String,
                            const Color(0xFFEAFAF1),
                            const Color(0xFF1D6A3A),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textGray,
                  size: 16,
                ),
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
                      decoration: const BoxDecoration(
                        color: AppColors.lightGreen,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "${i + 1}",
                        style: const TextStyle(
                          color: AppColors.darkGreen,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        steps[i],
                        style: const TextStyle(
                          color: AppColors.textGray,
                          fontSize: 12,
                          height: 1.4,
                        ),
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
              const Icon(
                Icons.compost_outlined,
                size: 16,
                color: AppColors.darkGreen,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Composting turns scraps you can't eat into nutrient-rich "
                  "soil instead of landfill waste.",
                  style: TextStyle(
                    color: AppColors.textGray,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Builder(
          builder: (context) {
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
          },
        ),
        _compostMethodsCard(),
        const SizedBox(height: 12),
        _compostStepsCard(),
        const SizedBox(height: 12),
        _compostFunFactCard(),
      ],
    );
  }

  Widget _compostMethodsCard() {
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
            "Composting Methods",
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "No outdoor space? There's still an option that fits.",
            style: TextStyle(color: AppColors.textGray, fontSize: 11),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < _compostMethods.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == _compostMethods.length - 1 ? 0 : 14,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _compostMethods[i]["name"]!,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _compostMethods[i]["bestFor"]!,
                    style: const TextStyle(
                      color: AppColors.darkGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _compostMethods[i]["description"]!,
                    style: const TextStyle(
                      color: AppColors.textGray,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
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
                        style: const TextStyle(
                          color: AppColors.textGray,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textGray,
                      size: 16,
                    ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "How to Compost",
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < _compostSteps.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == _compostSteps.length - 1 ? 0 : 10,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: AppColors.darkGreen,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "${i + 1}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _compostSteps[i],
                      style: const TextStyle(
                        color: AppColors.textGray,
                        fontSize: 12,
                        height: 1.4,
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

  Widget _compostFunFactCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline,
            size: 18,
            color: AppColors.darkGreen,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Fun fact",
                  style: TextStyle(
                    color: AppColors.darkGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Composting 1 kg of food waste saves about 0.5 kg of CO₂ "
                  "compared to sending it to landfill.",
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 12,
                    height: 1.4,
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
