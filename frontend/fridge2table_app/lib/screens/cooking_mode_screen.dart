import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/colors.dart';
import '../models/recipe_detail.dart';
import 'cooking_confirm_screen.dart';

class CookingModeScreen extends StatefulWidget {
  final RecipeDetail recipe;

  const CookingModeScreen({super.key, required this.recipe});

  @override
  State<CookingModeScreen> createState() => _CookingModeScreenState();
}

class _CookingModeScreenState extends State<CookingModeScreen> {
  int _stepIndex = 0;

  Timer? _timer;
  int _remainingSeconds = 0;
  bool _timerRunning = false;

  bool get _isLastStep => _stepIndex == widget.recipe.steps.length - 1;

  @override
  void initState() {
    super.initState();
    _resetTimerForCurrentStep();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _resetTimerForCurrentStep() {
    _timer?.cancel();
    final minutes = widget.recipe.steps[_stepIndex].timerMinutes;
    setState(() {
      _timerRunning = false;
      _remainingSeconds = (minutes ?? 0) * 60;
    });
  }

  void _startTimer() {
    if (_remainingSeconds <= 0) return;
    setState(() => _timerRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds <= 1) {
        _timer?.cancel();
        setState(() {
          _remainingSeconds = 0;
          _timerRunning = false;
        });
        _onTimerDone();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _timerRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    final minutes = widget.recipe.steps[_stepIndex].timerMinutes;
    setState(() {
      _timerRunning = false;
      _remainingSeconds = (minutes ?? 0) * 60;
    });
  }

  void _onTimerDone() {
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.vibrate();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Timer done! Move to next step.")),
    );
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  void _next() {
    if (_isLastStep) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CookingConfirmScreen(recipe: widget.recipe),
        ),
      );
    } else {
      setState(() => _stepIndex++);
      _resetTimerForCurrentStep();
    }
  }

  void _prev() {
    if (_stepIndex > 0) {
      setState(() => _stepIndex--);
      _resetTimerForCurrentStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.recipe.steps;
    final step = steps[_stepIndex];
    final progress = (_stepIndex + 1) / steps.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(steps.length, progress),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _buildStepCard(step),
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader(int totalSteps, double progress) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
      child: Column(
        children: [
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.maybePop(context),
                child: const Text(
                  "Exit",
                  style: TextStyle(
                    color: AppColors.textGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                "Step ${_stepIndex + 1} of $totalSteps",
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 36),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.borderGreen,
              valueColor: const AlwaysStoppedAnimation(AppColors.darkGreen),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [for (int i = 0; i < totalSteps; i++) _stepDot(i)],
          ),
        ],
      ),
    );
  }

  Widget _stepDot(int index) {
    final isDone = index < _stepIndex;
    final isActive = index == _stepIndex;
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDone || isActive ? AppColors.darkGreen : AppColors.background,
        shape: BoxShape.circle,
        border: isActive
            ? Border.all(color: AppColors.darkGreen, width: 2)
            : null,
      ),
      child: isDone
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : Text(
              "${index + 1}",
              style: TextStyle(
                color: isActive ? Colors.white : AppColors.textGray,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
    );
  }

  Widget _buildStepCard(CookingStep step) {
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.darkGreen,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                "${_stepIndex + 1}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              step.instructions,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 17,
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
            ),
            if (step.timerMinutes != null) ...[
              const SizedBox(height: 24),
              _buildTimer(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimer() {
    final isDone = _remainingSeconds == 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            _formatDuration(_remainingSeconds),
            style: TextStyle(
              fontFamily: "Outfit",
              fontWeight: FontWeight.w800,
              fontSize: 40,
              color: isDone ? const Color(0xFFC0392B) : AppColors.darkGreen,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: isDone
                    ? null
                    : (_timerRunning ? _pauseTimer : _startTimer),
                icon: Icon(
                  _timerRunning ? Icons.pause : Icons.play_arrow,
                  size: 18,
                ),
                label: Text(_timerRunning ? "Pause" : "Start"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.darkGreen,
                  side: const BorderSide(color: AppColors.darkGreen),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _resetTimer,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text("Reset"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textGray,
                  side: BorderSide(
                    color: AppColors.darkGreen.withValues(alpha: 0.11),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderGreen)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _stepIndex == 0 ? null : _prev,
              icon: const Icon(Icons.chevron_left, size: 18),
              label: const Text("Prev"),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textDark,
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(
                  color: AppColors.darkGreen.withValues(alpha: 0.11),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _next,
              icon: Icon(
                _isLastStep ? Icons.check : Icons.chevron_right,
                color: Colors.white,
                size: 18,
              ),
              label: Text(_isLastStep ? "Finish Cooking" : "Next"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
