import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../constants/colors.dart';

bool isOfflineResult(List<ConnectivityResult> results) {
  return results.isEmpty || results.every((r) => r == ConnectivityResult.none);
}

/// Thin banner shown app-wide whenever the device has no network path at
/// all -- tells the user their pantry edits are still being saved (just not
/// synced yet) rather than leaving them to wonder why nothing seems to be
/// reaching the server. Purely a passive indicator: it has no effect on
/// whether syncing actually happens (see MainScreen's connectivity
/// listener for that).
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        final offline = snapshot.hasData && isOfflineResult(snapshot.data!);
        if (!offline) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          color: AppColors.darkGreen,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.cloud_off, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  "You're offline — changes will sync when you're back online",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
