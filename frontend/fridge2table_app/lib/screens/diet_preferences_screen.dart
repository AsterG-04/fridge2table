import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../main.dart';
import '../services/auth_service.dart';

class DietPreferencesScreen extends StatefulWidget {
  const DietPreferencesScreen({super.key});

  @override
  State<DietPreferencesScreen> createState() => _DietPreferencesScreenState();
}

class _DietPreferencesScreenState extends State<DietPreferencesScreen> {
  int _step = 0; // 0 = diet preferences, 1 = allergy setup

  final Set<String> _selectedDiets = {};
  final Set<String> _selectedAllergies = {};

  bool _otherDietSelected = false;
  bool _otherAllergySelected = false;
  final _otherDietController = TextEditingController();
  final _otherAllergyController = TextEditingController();

  static const List<Map<String, String>> _dietOptions = [
    {"emoji": "✅", "name": "No Restrictions", "desc": "I eat everything"},
    {"emoji": "🥦", "name": "Vegetarian", "desc": "No meat or seafood"},
    {"emoji": "🌱", "name": "Vegan", "desc": "No animal products"},
    {"emoji": "🐟", "name": "Pescatarian", "desc": "No meat, seafood allowed"},
    {"emoji": "☪️", "name": "Halal", "desc": "Halal certified only"},
    {"emoji": "✡️", "name": "Kosher", "desc": "Kosher certified only"},
    {"emoji": "🌾", "name": "Gluten-Free", "desc": "No wheat, barley, rye"},
    {"emoji": "🥛", "name": "Dairy-Free", "desc": "No milk or dairy products"},
    {"emoji": "🥑", "name": "Keto", "desc": "High fat, very low carb"},
    {"emoji": "🍬", "name": "Low Sugar", "desc": "Minimal added sugar"},
    {"emoji": "✏️", "name": "Other", "desc": "Type your own"},
  ];

  // Matches Figma node 6:1369 (Allergy Setup) exactly, including severity levels
  static const List<Map<String, String>> _allergyOptions = [
    {"emoji": "✅", "name": "No Allergies", "severity": ""},
    {"emoji": "🥛", "name": "Milk", "severity": "Common allergen"},
    {"emoji": "🥚", "name": "Eggs", "severity": "Common allergen"},
    {"emoji": "🫘", "name": "Soy", "severity": "Common allergen"},
    {"emoji": "🌾", "name": "Wheat", "severity": "Common allergen"},
    {"emoji": "🐟", "name": "Fish", "severity": "Moderate allergen"},
    {"emoji": "🌿", "name": "Sesame", "severity": "Moderate allergen"},
    {"emoji": "🌻", "name": "Mustard", "severity": "Moderate allergen"},
    {"emoji": "🥜", "name": "Peanuts", "severity": "Severe allergen"},
    {"emoji": "🌰", "name": "Tree Nuts", "severity": "Severe allergen"},
    {"emoji": "🦐", "name": "Shellfish", "severity": "Severe allergen"},
    {"emoji": "✏️", "name": "Other", "severity": ""},
  ];

  static const Map<String, Color> _severityColors = {
    "Common allergen": Color(0xFFD68910),
    "Severe allergen": Color(0xFFC0392B),
    "Moderate allergen": Color(0xFFE9A820),
  };

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  /// Pre-fills whatever was saved last time -- this screen is reused both
  /// for first-time onboarding (always starts blank, nothing saved yet)
  /// and for editing later from Profile, which previously always opened
  /// blank too regardless of what was already saved. That made saved
  /// preferences look like they'd been wiped on every re-visit (e.g.
  /// after logging back in), when they were actually sitting in
  /// SharedPreferences the whole time -- this screen just never read
  /// them back.
  Future<void> _loadExisting() async {
    final diets = await AuthService.getDietPreferences();
    final allergies = await AuthService.getAllergies();
    if (!mounted) return;

    setState(() {
      for (final diet in diets) {
        if (_dietOptions.any((o) => o["name"] == diet)) {
          _selectedDiets.add(diet);
        } else {
          _otherDietSelected = true;
          _otherDietController.text = diet;
        }
      }
      for (final allergy in allergies) {
        if (_allergyOptions.any((o) => o["name"] == allergy)) {
          _selectedAllergies.add(allergy);
        } else {
          _otherAllergySelected = true;
          _otherAllergyController.text = allergy;
        }
      }
    });
  }

  @override
  void dispose() {
    _otherDietController.dispose();
    _otherAllergyController.dispose();
    super.dispose();
  }

  void _continue() {
    if (_step == 0) {
      setState(() => _step = 1);
    } else {
      _finish();
    }
  }

  void _toggleDiet(String name) {
    setState(() {
      if (name == "No Restrictions") {
        _selectedDiets
          ..clear()
          ..add(name);
        _otherDietSelected = false;
        _otherDietController.clear();
      } else {
        _selectedDiets.remove("No Restrictions");
        if (_selectedDiets.contains(name)) {
          _selectedDiets.remove(name);
        } else {
          _selectedDiets.add(name);
        }
      }
    });
  }

  void _toggleOtherDiet() {
    setState(() {
      if (_otherDietSelected) {
        _otherDietSelected = false;
        _otherDietController.clear();
      } else {
        _otherDietSelected = true;
        _selectedDiets.remove("No Restrictions");
      }
    });
  }

  void _toggleAllergy(String name) {
    setState(() {
      if (name == "No Allergies") {
        _selectedAllergies
          ..clear()
          ..add(name);
        _otherAllergySelected = false;
        _otherAllergyController.clear();
      } else {
        _selectedAllergies.remove("No Allergies");
        if (_selectedAllergies.contains(name)) {
          _selectedAllergies.remove(name);
        } else {
          _selectedAllergies.add(name);
        }
      }
    });
  }

  void _toggleOtherAllergy() {
    setState(() {
      if (_otherAllergySelected) {
        _otherAllergySelected = false;
        _otherAllergyController.clear();
      } else {
        _otherAllergySelected = true;
        _selectedAllergies.remove("No Allergies");
      }
    });
  }

  Future<void> _finish() async {
    final diets = _selectedDiets.toList();
    if (_otherDietSelected) {
      final custom = _otherDietController.text.trim();
      diets.add(custom.isNotEmpty ? custom : "Other");
    }

    final allergies = _selectedAllergies.toList();
    if (_otherAllergySelected) {
      final custom = _otherAllergyController.text.trim();
      allergies.add(custom.isNotEmpty ? custom : "Other");
    }

    await AuthService.saveDietPreferences(diets);
    await AuthService.saveAllergies(allergies);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDietStep = _step == 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(isDietStep),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: isDietStep ? _buildDietGrid() : _buildAllergyList(),
            ),
          ),
          _buildFooter(isDietStep),
        ],
      ),
    );
  }

  Widget _buildDietGrid() {
    return Column(
      children: [
        for (int i = 0; i < _dietOptions.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _dietCard(_dietOptions[i])),
                const SizedBox(width: 12),
                Expanded(
                  child: i + 1 < _dietOptions.length
                      ? _dietCard(_dietOptions[i + 1])
                      : const SizedBox(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAllergyList() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFFFDF2F0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFC0392B).withValues(alpha: 0.14),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: Color(0xFFC0392B),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 12, color: Color(0xFFC0392B)),
                    children: [
                      TextSpan(
                        text: "Important: ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text:
                            "This app provides warnings but is not a substitute for reading ingredient labels. Always check packaging carefully.",
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (int i = 0; i < _allergyOptions.length; i++)
          Padding(
            padding: EdgeInsets.only(
              bottom: i == _allergyOptions.length - 1 ? 0 : 8,
            ),
            child: _allergyCard(_allergyOptions[i]),
          ),
      ],
    );
  }

  Widget _buildHeader(bool isDietStep) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.darkGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 52, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _progressBar(filled: true)),
              const SizedBox(width: 8),
              Expanded(child: _progressBar(filled: !isDietStep)),
            ],
          ),
          if (!isDietStep) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => setState(() => _step = 0),
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
          ],
          const SizedBox(height: 16),
          Text(
            "Step ${_step + 1} of 2 · Personalisation",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isDietStep ? "Your diet preferences" : "Any food allergies?",
            style: const TextStyle(
              fontFamily: "Outfit",
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isDietStep
                ? "We use this to filter recipes and flag unsuitable ingredients."
                : "We'll always warn you before a recipe includes these ingredients.",
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressBar({required bool filled}) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: filled ? Colors.white : Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  Widget _dietCard(Map<String, String> option) {
    final name = option["name"]!;
    final isOther = name == "Other";
    final isSelected = isOther
        ? _otherDietSelected
        : _selectedDiets.contains(name);

    return GestureDetector(
      onTap: () => isOther ? _toggleOtherDiet() : _toggleDiet(name),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.darkGreen
                : AppColors.darkGreen.withValues(alpha: 0.11),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(option["emoji"]!, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        option["desc"]!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isOther && isSelected) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _otherDietController,
                autofocus: true,
                style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: "e.g. Low FODMAP",
                  hintStyle: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGray,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: AppColors.darkGreen.withValues(alpha: 0.15),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _allergyCard(Map<String, String> option) {
    final name = option["name"]!;
    final isOther = name == "Other";
    final severity = option["severity"]!;
    final severityColor = severity.isEmpty
        ? AppColors.chipGreenText
        : _severityColors[severity]!;
    final isSelected = isOther
        ? _otherAllergySelected
        : _selectedAllergies.contains(name);

    return GestureDetector(
      onTap: () => isOther ? _toggleOtherAllergy() : _toggleAllergy(name),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.darkGreen
                : AppColors.darkGreen.withValues(alpha: 0.11),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(option["emoji"]!, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textDark,
                        ),
                      ),
                      if (severity.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: severityColor.withValues(alpha: 0.09),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            severity,
                            style: TextStyle(
                              color: severityColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.darkGreen
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.darkGreen
                          : AppColors.darkGreen.withValues(alpha: 0.11),
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ],
            ),
            if (isOther && isSelected) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _otherAllergyController,
                autofocus: true,
                style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: "e.g. Kiwi",
                  hintStyle: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGray,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: AppColors.darkGreen.withValues(alpha: 0.15),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(bool isDietStep) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.borderGreen)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _continue,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isDietStep
                  ? const Text(
                      "Continue",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "All done — Let's go!",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
            ),
          ),
          TextButton(
            onPressed: _finish,
            child: const Text(
              "Skip for now",
              style: TextStyle(
                color: AppColors.textGray,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
