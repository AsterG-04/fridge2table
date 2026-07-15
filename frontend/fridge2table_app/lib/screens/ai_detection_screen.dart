import 'dart:io';

import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../services/ingredient_classifier_service.dart';
import 'add_ingredient_screen.dart';

class AiDetectionScreen extends StatefulWidget {
  final String imagePath;

  const AiDetectionScreen({super.key, required this.imagePath});

  @override
  State<AiDetectionScreen> createState() => _AiDetectionScreenState();
}

class _AiDetectionScreenState extends State<AiDetectionScreen> {
  List<ClassificationResult>? _results;
  String? _error;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _runClassification();
  }

  Future<void> _runClassification() async {
    try {
      await IngredientClassifierService.initialize();
      final results = await IngredientClassifierService.classify(
        widget.imagePath,
        topK: 3,
      );
      if (!mounted) return;
      setState(() => _results = results);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = "Couldn't identify this photo: $e");
    }
  }

  void _rescan() => Navigator.pop(context);

  Future<void> _goToAddIngredient({String? prefilledName}) async {
    final saved = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddIngredientScreen(
          capturedImagePath: widget.imagePath,
          prefilledName: prefilledName,
        ),
      ),
    );
    if (!mounted) return;
    if (saved == true) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
          if (_results != null)
            SafeArea(top: false, child: _buildBottomBar()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.darkGreen,
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _rescan,
          ),
          const Text(
            "AI Detection",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }

    final results = _results;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              File(widget.imagePath),
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),

          if (results == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 16, color: AppColors.darkGreen),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "${results.length} possible match${results.length == 1 ? '' : 'es'} found — tap the right one",
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
            const SizedBox(height: 16),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (int i = 0; i < results.length; i++)
                  _buildCandidateChip(results[i], i),
              ],
            ),

            const SizedBox(height: 8),

            Center(
              child: TextButton(
                onPressed: () => _goToAddIngredient(),
                child: const Text("None of these — enter manually"),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCandidateChip(ClassificationResult result, int index) {
    final isSelected = index == _selectedIndex;
    final label = result.label;
    final displayName = label.isEmpty
        ? label
        : label[0].toUpperCase() + label.substring(1);
    final confidencePct = (result.confidence * 100).clamp(0, 100).toStringAsFixed(0);

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.darkGreen : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? AppColors.darkGreen
                : AppColors.darkGreen.withValues(alpha: 0.15),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check_circle, size: 14, color: Colors.white),
              const SizedBox(width: 6),
            ],
            Text(
              displayName,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textDark,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppColors.chipGreenBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                "$confidencePct%",
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.chipGreenText,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final results = _results;
    final selectedLabel =
        results != null && results.isNotEmpty ? results[_selectedIndex].label : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderGreen)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _rescan,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: AppColors.darkGreen.withValues(alpha: 0.11)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text("Rescan", style: TextStyle(color: AppColors.textGray)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: selectedLabel == null
                  ? null
                  : () => _goToAddIngredient(prefilledName: selectedLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "Add Ingredient",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
