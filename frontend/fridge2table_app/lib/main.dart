import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/api_config.dart';
import 'config/supabase_config.dart';
import 'constants/colors.dart';
import 'services/api_service.dart';
import 'services/app_settings_service.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/supabase_service.dart';
import 'screens/home_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/recipe_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/ai_camera_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/splash_screen.dart';
import 'widgets/offline_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.initialize();
  await SupabaseService.initialize();
  // Sets up the notification channel only -- does NOT request permission
  // yet, since that's a user-facing prompt deliberately deferred until
  // right after sign-in (see every navigation to MainScreen below).
  await NotificationService.initialize();

  runApp(const Fridge2TableApp());
}

// Shared at the top level (rather than kept private to
// _Fridge2TableAppState) so ApiService -- a plain class with no
// BuildContext of its own -- can also navigate to SignInScreen directly,
// specifically for the "a 401 means the session is dead, kick the user
// back to sign-in" case.
final rootNavigatorKey = GlobalKey<NavigatorState>();

class Fridge2TableApp extends StatefulWidget {
  const Fridge2TableApp({super.key});

  @override
  State<Fridge2TableApp> createState() => _Fridge2TableAppState();
}

class _Fridge2TableAppState extends State<Fridge2TableApp> {
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    // Catches sign-in completing asynchronously — Google OAuth (browser
    // redirect lands later) and email-confirmation links (opened from the
    // user's inbox, possibly after the app was backgrounded) — regardless
    // of which screen originally triggered it. Password sign-in handles its
    // own navigation directly via suppressRootAuthListener, since it can
    // just await the result.
    if (SupabaseConfig.isConfigured) {
      _authSub = Supabase.instance.client.auth.onAuthStateChange.listen(
        (data) async {
          debugPrint(
            "[AuthListener] event=${data.event} hasSession=${data.session != null} "
            "userId=${data.session?.user.id} email=${data.session?.user.email} "
            "suppressed=${SupabaseService.suppressRootAuthListener}",
          );
          if (data.event != AuthChangeEvent.signedIn || data.session == null) {
            return;
          }
          if (SupabaseService.suppressRootAuthListener) return;

          try {
            await _handleSignedIn(data.session!.user);
          } catch (error, stackTrace) {
            debugPrint(
              "[AuthListener] Unhandled error while processing signedIn event: $error\n$stackTrace",
            );
            await _showAuthProblemAndReturnToSignIn(error);
          }
        },
        onError: (Object error, StackTrace stackTrace) async {
          // Reached for failures that never produce a signedIn event at all —
          // most commonly an expired or already-used confirmation link
          // (Supabase's own hosted /verify redirects straight to an error
          // instead of exchanging a session), or an invalid/reused PKCE code.
          // Previously this was silently debugPrint-only, which is exactly
          // what made the screen look like nothing happened: the deep link
          // lands, the exchange fails, and the app just sits on whatever was
          // already showing with zero feedback.
          debugPrint(
            "[AuthListener] Stream error: ${error.runtimeType} $error\n$stackTrace",
          );
          await _showAuthProblemAndReturnToSignIn(error);
        },
      );
    }
  }

  String _friendlyAuthErrorMessage(Object error) {
    if (error is AuthException) {
      final statusCode = error.statusCode;
      if (statusCode == "otp_expired" || error.code == "otp_expired") {
        return "This confirmation link has expired or was already used. "
            "Please sign in, or create the account again to get a new link.";
      }
      return error.message;
    }
    return "Something went wrong confirming your email. Please try signing in.";
  }

  Future<void> _showAuthProblemAndReturnToSignIn(Object error) async {
    if (!mounted) return;
    final message = _friendlyAuthErrorMessage(error);
    debugPrint("[AuthListener] Showing auth problem dialog: $message");

    final dialogContext = rootNavigatorKey.currentContext;
    if (dialogContext != null && dialogContext.mounted) {
      await showDialog<void>(
        context: dialogContext,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          icon: const Icon(
            Icons.error_outline,
            color: Color(0xFFC0392B),
            size: 32,
          ),
          title: const Text("Couldn't confirm email"),
          content: Text(message, textAlign: TextAlign.center),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "OK",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (!mounted) return;

    debugPrint("[AuthListener] Navigating to SignInScreen after auth problem");
    rootNavigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInScreen()),
      (route) => false,
    );
  }

  Future<void> _handleSignedIn(User user) async {
    final provider = user.appMetadata["provider"] as String?;
    // Anything other than the plain "email" provider means this session
    // came from an external OAuth flow (Google, etc.) rather than an
    // email-confirmation link — checking "not email" instead of hardcoding
    // "google" doesn't depend on guessing Supabase's exact provider string
    // and still generalizes to any provider added later.
    final isOAuthProvider = provider != null && provider != "email";
    debugPrint(
      "[AuthListener] provider=$provider isOAuthProvider=$isOAuthProvider",
    );

    if (isOAuthProvider) {
      final email = user.email ?? "";
      final name =
          (user.userMetadata?["name"] as String?) ??
          (email.contains("@") ? email.split("@").first : "there");

      // Google's own account picker already happened in the browser before
      // this event ever fires. What we *can* still do here is confirm
      // before entering the app, and tell new vs. returning users apart.
      // Supabase's OAuth exchange finds-or-creates the account server-side
      // as a single atomic step — there's no separate "check first" call
      // before that happens, so this is a post-hoc confirmation rather than
      // a true pre-creation check. createdAt/lastSignInAt landing within a
      // few seconds of each other means this session is that account's
      // very first sign-in.
      final createdAt = DateTime.tryParse(user.createdAt);
      final lastSignInAt = user.lastSignInAt == null
          ? null
          : DateTime.tryParse(user.lastSignInAt!);
      final isNewUser =
          createdAt != null &&
          lastSignInAt != null &&
          lastSignInAt.difference(createdAt).abs() <
              const Duration(seconds: 10);
      debugPrint(
        "[AuthListener] OAuth sign-in ($provider) for $email — isNewUser=$isNewUser",
      );

      if (!mounted) return;
      var confirmed = true;
      final dialogContext = rootNavigatorKey.currentContext;
      if (dialogContext != null && dialogContext.mounted) {
        confirmed =
            await showDialog<bool>(
              context: dialogContext,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                icon: Icon(
                  isNewUser ? Icons.person_add_alt : Icons.login,
                  color: AppColors.darkGreen,
                  size: 32,
                ),
                title: Text(isNewUser ? "New account" : "Welcome back"),
                content: Text(
                  isNewUser
                      ? "No account found for $email. Create one and continue?"
                      : "Continue as $email?",
                  textAlign: TextAlign.center,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.darkGreen,
                    ),
                    child: Text(isNewUser ? "Create & Continue" : "Continue"),
                  ),
                ],
              ),
            ) ??
            false;
      }
      if (!mounted) return;

      if (!confirmed) {
        debugPrint(
          "[AuthListener] User declined the confirmation — signing back out",
        );
        await Supabase.instance.client.auth.signOut();
        return;
      }

      debugPrint("[AuthListener] Confirmed — caching identity and syncing");
      await AuthService.cacheIdentity(name: name, email: email);
      await SupabaseService.resolveConflicts();
      await NotificationService.requestPermission();

      debugPrint("[AuthListener] Navigating to MainScreen");
      rootNavigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    } else {
      // An email-confirmation link auto-creates a session via the
      // deep-link redirect, but confirming an email shouldn't silently log
      // the user in — sign back out and send them to Sign In to enter
      // their credentials explicitly.
      debugPrint(
        "[AuthListener] Email confirmation link landed for ${user.email} — signing back out, not auto-logging in",
      );
      try {
        await Supabase.instance.client.auth.signOut();
        debugPrint(
          "[AuthListener] Sign-out after email confirmation succeeded",
        );
      } catch (error, stackTrace) {
        // Don't let a signOut failure (e.g. offline right at this instant)
        // swallow navigation — the confirmation dialog is more important
        // than whether the now-redundant session got revoked server-side.
        debugPrint(
          "[AuthListener] Sign-out after email confirmation failed (continuing anyway): $error\n$stackTrace",
        );
      }
      if (!mounted) return;
      debugPrint(
        "[AuthListener] Navigating to SignInScreen with emailJustVerified=true",
      );
      rootNavigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const SignInScreen(emailJustVerified: true),
        ),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Supabase.initialize() (awaited in main() before runApp()) already
    // restored any persisted session from secure storage, so this
    // synchronously reflects whether one exists. Skip the onboarding/sign-in
    // flow entirely for a returning user with a valid session — they should
    // only see it again after an explicit logout or a fresh install, not
    // just from closing and reopening the app.
    final hasPersistedSession =
        SupabaseConfig.isConfigured &&
        Supabase.instance.client.auth.currentSession != null;
    debugPrint("[Startup] hasPersistedSession=$hasPersistedSession");

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: "Fridge2Table",
      theme: ThemeData(fontFamily: "DM Sans"),
      home: hasPersistedSession ? const MainScreen() : const SplashScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;

  Timer? _backgroundBackupTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool? _wasOffline;

  static const _backgroundBackupInterval = Duration(minutes: 15);

  final List<Widget> _screens = const [
    HomeScreen(),
    InventoryScreen(),
    RecipeScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Silent best-effort backup — never blocks the UI and any failure
    // (offline, not configured yet, user hasn't opted into this connection
    // type) is simply ignored. Respects the "Auto Backup on WiFi"/"Auto
    // Backup on Mobile Data" toggles from the Backup & Restore screen.
    unawaited(SupabaseService.autoBackupIfAllowed());
    _startBackgroundBackupTimer();
    _listenForReconnect();
  }

  /// Pushes any locally-queued offline pantry changes the moment the
  /// connection comes back, rather than waiting for the user to happen to
  /// pull-to-refresh the Pantry screen. getInventory() already does both
  /// halves of a sync pass (push everything queued, then pull the fresh
  /// server state back into the local cache) -- this just triggers that on
  /// the offline->online transition specifically, ignoring every other
  /// connectivity event so it doesn't refire on e.g. wifi-to-mobile handoffs
  /// that were never actually offline in between.
  void _listenForReconnect() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final offlineNow = isOfflineResult(results);
      final wasOffline = _wasOffline;
      _wasOffline = offlineNow;

      if (wasOffline == true && !offlineNow) {
        debugPrint("[MainScreen] Connectivity restored, syncing pantry...");
        unawaited(_syncPantryAfterReconnect());
      }
    });
  }

  Future<void> _syncPantryAfterReconnect() async {
    try {
      await ApiService.getInventory();
    } catch (e) {
      debugPrint("[MainScreen] Reconnect sync failed: $e");
    }
  }

  /// "Background Backup" (AppSettingsService) means periodic backups while
  /// the app is open, on top of the one-shot launch trigger above -- this
  /// timer runs for as long as MainScreen is mounted and re-checks the
  /// toggle on every tick (rather than only at startup) so turning it off
  /// mid-session in the Backup & Restore screen takes effect immediately.
  void _startBackgroundBackupTimer() {
    _backgroundBackupTimer = Timer.periodic(_backgroundBackupInterval, (
      _,
    ) async {
      if (await AppSettingsService.getBackgroundBackupEnabled()) {
        await SupabaseService.autoBackupIfAllowed();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _backgroundBackupTimer?.cancel();
    _connectivitySub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-checks expiry notifications whenever the app comes back to the
    // foreground (e.g. reopened from the app switcher) -- not just on the
    // initial launch, since an ingredient could have crossed into
    // "expiring soon"/"expired" during however long the app was backgrounded.
    if (state == AppLifecycleState.resumed) {
      unawaited(NotificationService.checkAndNotify());
    }
  }

  void _openScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AiCameraScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const OfflineBanner(),
            Expanded(child: _screens[_currentIndex]),
          ],
        ),
      ),

      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return SizedBox(
      height: 88,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(icon: Icons.home, label: "Home", index: 0),
                _navItem(icon: Icons.kitchen, label: "Pantry", index: 1),
                const SizedBox(width: 56),
                _navItem(
                  icon: Icons.restaurant_menu,
                  label: "Recipes",
                  index: 2,
                ),
                _navItem(icon: Icons.person, label: "Profile", index: 3),
              ],
            ),
          ),

          Positioned(
            top: -22,
            child: GestureDetector(
              onTap: _openScanner,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.darkGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = index == _currentIndex;
    final color = isSelected ? AppColors.darkGreen : AppColors.textGray;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
