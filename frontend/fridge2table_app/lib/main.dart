import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'constants/colors.dart';
import 'services/auth_service.dart';
import 'services/supabase_service.dart';
import 'screens/home_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/recipe_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/ai_camera_screen.dart';
import 'screens/splash_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();

  runApp(
    const Fridge2TableApp(),
  );
}


class Fridge2TableApp extends StatefulWidget {

  const Fridge2TableApp({super.key});

  @override
  State<Fridge2TableApp> createState() => _Fridge2TableAppState();
}


class _Fridge2TableAppState extends State<Fridge2TableApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    // Google OAuth completes asynchronously via a deep-link redirect, well
    // after signInWithOAuth() itself returns (that call just opens the
    // browser). This is the one place that catches the redirect regardless
    // of which screen (Sign In or Create Account) launched it. Password
    // sign-in/sign-up handle their own navigation directly since they can
    // just await the result — SupabaseService.oauthInProgress keeps this
    // listener from also reacting to *their* signedIn events.
    if (SupabaseConfig.isConfigured) {
      _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
        if (data.event != AuthChangeEvent.signedIn || data.session == null) return;
        if (!SupabaseService.oauthInProgress) return;
        SupabaseService.oauthInProgress = false;

        final user = data.session!.user;
        final email = user.email ?? "";
        final name = (user.userMetadata?["name"] as String?) ??
            (email.contains("@") ? email.split("@").first : "Google user");
        await AuthService.cacheIdentity(name: name, email: email);
        await SupabaseService.resolveConflicts();

        _navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
      });
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: "Fridge2Table",
      theme: ThemeData(
        fontFamily: "DM Sans",
      ),
      home: const SplashScreen(),
    );
  }
}


class MainScreen extends StatefulWidget {

  const MainScreen({super.key});

  @override
  State<MainScreen> createState() =>
      _MainScreenState();
}


class _MainScreenState
    extends State<MainScreen> {

  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    InventoryScreen(),
    RecipeScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Silent best-effort background sync — never blocks the UI and any
    // failure (offline, not configured yet) is simply ignored.
    unawaited(SupabaseService.resolveConflicts());
  }

  void _openScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AiCameraScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: _screens[_currentIndex],

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
                _navItem(icon: Icons.restaurant_menu, label: "Recipes", index: 2),
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
