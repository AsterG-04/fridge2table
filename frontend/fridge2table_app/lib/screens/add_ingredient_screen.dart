import 'dart:io';
import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../models/ingredient.dart';
import '../services/api_service.dart';
import 'waste_control_screen.dart';

class AddIngredientScreen extends StatefulWidget {
  final String? capturedImagePath;
  final String? prefilledName;
  final Ingredient? existingIngredient;

  const AddIngredientScreen({
    super.key,
    this.capturedImagePath,
    this.prefilledName,
    this.existingIngredient,
  });

  bool get isEditing => existingIngredient != null;

  @override
  State<AddIngredientScreen> createState() => _AddIngredientScreenState();
}

class _AddIngredientScreenState extends State<AddIngredientScreen> {
  static const List<Map<String, String>> _unitOptions = [
    {"value": "pcs", "label": "Each / pcs"},
    {"value": "g", "label": "Grams (g)"},
    {"value": "kg", "label": "Kilograms (kg)"},
    {"value": "ml", "label": "Milliliters (ml)"},
    {"value": "L", "label": "Liters (L)"},
    {"value": "cups", "label": "Cups"},
    {"value": "tbsp", "label": "Tbsp"},
    {"value": "tsp", "label": "Tsp"},
  ];

  static const List<String> _categoryOptions = [
    "Fruits",
    "Vegetables",
    "Dairy",
    "Meat & Seafood",
    "Grains & Bread",
    "Spices & Condiments",
    "Beverages",
    "Snacks",
    "Other",
  ];

  static const List<String> _locationOptions = [
    "Fridge",
    "Freezer",
    "Pantry",
    "Counter",
  ];

  late final _nameController = TextEditingController(
    text: widget.existingIngredient?.name ?? widget.prefilledName ?? "",
  );
  late final _quantityController = TextEditingController(
    text: widget.existingIngredient?.quantity.toString() ?? "",
  );
  late final _expiryController = TextEditingController(
    text: widget.existingIngredient?.expiryDate ?? "",
  );

  late String? _selectedUnit = widget.existingIngredient?.unit;
  late String? _selectedCategory = widget.existingIngredient?.category;
  late String? _selectedLocation = widget.existingIngredient?.location;

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
        return (AppColors.lightGreen, AppColors.darkGreen);
    }
  }

  String get _previewInitials {
    final name = _nameController.text.trim();
    if (name.isEmpty) return "?";
    final words = name.split(RegExp(r"\s+"));
    if (words.length == 1) {
      return words[0].substring(0, words[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  bool _saving = false;

  Future<void> saveIngredient() async {
    if (_saving) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter an ingredient name")),
      );
      return;
    }

    setState(() => _saving = true);

    final ingredient = Ingredient(
      id: widget.existingIngredient?.id,
      name: name,
      quantity: double.tryParse(_quantityController.text) ?? 0,
      unit: _selectedUnit ?? "",
      category: _selectedCategory,
      location: _selectedLocation,
      expiryDate: _expiryController.text.trim().isEmpty
          ? null
          : _expiryController.text.trim(),
    );

    try {
      if (widget.isEditing) {
        await ApiService.updateIngredient(
          widget.existingIngredient!.id!,
          ingredient,
        );
      } else {
        await ApiService.addIngredient(ingredient);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Couldn't save: ${e.toString().replaceFirst('Exception: ', '')}",
          ),
        ),
      );
      setState(() => _saving = false);
      return;
    }

    if (!mounted) return;

    final isProduce =
        _selectedCategory == "Vegetables" || _selectedCategory == "Fruits";
    final seeTips = isProduce ? await _showScrapTip() : false;

    if (!mounted) return;
    final navigator = Navigator.of(context);
    navigator.pop(true);
    if (seeTips) {
      navigator.push(
        MaterialPageRoute(builder: (_) => const WasteControlScreen()),
      );
    }
  }

  Future<bool> _showScrapTip() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("🌱", style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Don't throw away the scraps!",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Check Waste Control for tips on regrowing, scrap "
                    "recipes and composting.",
                    style: TextStyle(
                      color: AppColors.textGray,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Not Now"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.darkGreen,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("See Tips"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return result ?? false;
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
    );

    if (date != null) {
      _expiryController.text = date.toIso8601String().split('T')[0];

      setState(() {});
    }
  }

  void _showHelp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Fill in the ingredient's name, quantity, unit, category and "
          "expiry date. The avatar preview updates with the category color.",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (chipBg, chipText) = _catColors(_selectedCategory);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (widget.capturedImagePath != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(widget.capturedImagePath!),
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  _buildCategoryPreview(chipBg, chipText),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.prefilledName != null) ...[
                          _buildAiDetectedBadge(),
                          const SizedBox(height: 8),
                        ],

                        TextField(
                          controller: _nameController,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: "Ingredient Name",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Quantity",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildDropdown(
                                label: "Unit",
                                value: _selectedUnit,
                                items: _unitOptions
                                    .map(
                                      (u) => DropdownMenuItem(
                                        value: u["value"],
                                        child: Text(u["label"]!),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedUnit = v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDropdown(
                                label: "Category",
                                value: _selectedCategory,
                                items: _categoryOptions
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(c),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedCategory = v),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        _buildDropdown(
                          label: "Storage Location",
                          value: _selectedLocation,
                          items: _locationOptions
                              .map(
                                (l) =>
                                    DropdownMenuItem(value: l, child: Text(l)),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedLocation = v),
                        ),

                        const SizedBox(height: 16),

                        TextField(
                          controller: _expiryController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: "Expiry Date",
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_month),
                              onPressed: pickDate,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(
                              color: AppColors.darkGreen.withValues(
                                alpha: 0.11,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(
                              color: AppColors.textGray,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saving ? null : saveIngredient,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.darkGreen,
                            disabledBackgroundColor: AppColors.darkGreen
                                .withValues(alpha: 0.5),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  widget.isEditing
                                      ? "Save Changes"
                                      : "Save Ingredient",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
            onTap: () => Navigator.pop(context),
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
          Expanded(
            child: Text(
              widget.isEditing ? "Edit Ingredient" : "Add Ingredient",
              textAlign: TextAlign.center,
              style: const TextStyle(
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
    );
  }

  Widget _buildCategoryPreview(Color chipBg, Color chipText) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.lightGreen,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: chipBg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              _previewInitials,
              style: TextStyle(
                color: chipText,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _selectedCategory ?? "Category",
          style: const TextStyle(
            color: AppColors.textGray,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAiDetectedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 12, color: AppColors.darkGreen),
          SizedBox(width: 4),
          Text(
            "AI detected",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.darkGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}
