import 'package:flutter/material.dart';

import '../constants/colors.dart';

class AsyncStateBuilder<T> extends StatelessWidget {
  final AsyncSnapshot<T> snapshot;
  final Widget Function(BuildContext context, T data) builder;
  final VoidCallback onRetry;
  final bool Function(T data)? isEmpty;
  final String emptyTitle;
  final String? emptySubtitle;
  final IconData emptyIcon;

  const AsyncStateBuilder({
    super.key,
    required this.snapshot,
    required this.builder,
    required this.onRetry,
    this.isEmpty,
    this.emptyTitle = "Nothing here yet",
    this.emptySubtitle,
    this.emptyIcon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.darkGreen),
      );
    }

    if (snapshot.hasError) {
      final message = snapshot.error.toString().replaceFirst("Exception: ", "");
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: AppColors.textGray,
              ),
              const SizedBox(height: 12),
              const Text(
                "Couldn't load data",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textGray, fontSize: 12),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
                label: const Text(
                  "Retry",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final data = snapshot.data;
    if (data == null || (isEmpty?.call(data) ?? false)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(emptyIcon, size: 40, color: AppColors.textGray),
              const SizedBox(height: 12),
              Text(
                emptyTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textGray,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (emptySubtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  emptySubtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return builder(context, data);
  }
}
