import 'package:flutter/material.dart';

import 'signin_screen.dart';

class _OnboardingPage {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final String? description;

  const _OnboardingPage({
    this.icon,
    required this.title,
    this.subtitle,
    this.description,
  });
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardingPage> _pages = [
    _OnboardingPage(
      title: "Fridge2Table",
      subtitle: "Smart Pantry · Zero Waste · AI Recipes",
    ),
    _OnboardingPage(
      icon: Icons.kitchen_outlined,
      title: "Track your pantry",
      description:
          "Keep tabs on everything in your fridge and cupboard, with "
          "expiry alerts before food goes to waste.",
    ),
    _OnboardingPage(
      icon: Icons.camera_alt_outlined,
      title: "AI ingredient detection",
      description:
          "Snap a photo and let AI identify what you just bought — no "
          "manual typing needed.",
    ),
    _OnboardingPage(
      icon: Icons.restaurant_menu_outlined,
      title: "Get recipe recommendations",
      description:
          "Discover recipes tailored to what's already in your pantry, "
          "ranked by how well they match.",
    ),
    _OnboardingPage(
      icon: Icons.eco_outlined,
      title: "Reduce food waste",
      description:
          "Turn expiring ingredients into meals, not garbage — for your "
          "wallet and the planet.",
    ),
  ];

  bool get _isLastPage => _currentPage == _pages.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _skipToEnd() {
    _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  void _getStarted() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SignInScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF081C15), Color(0xFF1B4332), Color(0xFF52B788)],
            stops: [0.08, 0.58, 0.92],
          ),
        ),
        child: Stack(
          children: [
            Positioned(top: -80, left: 20, child: _circleOutline(320)),
            Positioned(bottom: -60, right: -40, child: _circleOutline(240)),

            SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 8, 20, 0),
                      child: Opacity(
                        opacity: _isLastPage ? 0 : 1,
                        child: IgnorePointer(
                          ignoring: _isLastPage,
                          child: TextButton(
                            onPressed: _skipToEnd,
                            child: Text(
                              "Skip",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (i) => setState(() => _currentPage = i),
                      children: [for (final page in _pages) _buildPage(page)],
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 0; i < _pages.length; i++) ...[
                        _dot(active: i == _currentPage),
                        if (i != _pages.length - 1) const SizedBox(width: 8),
                      ],
                    ],
                  ),

                  const SizedBox(height: 32),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: _isLastPage
                        ? SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _getStarted,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Get Started",
                                    style: TextStyle(
                                      color: Color(0xFF1B4332),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward,
                                    color: Color(0xFF1B4332),
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => _pageController.nextPage(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeOut,
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.45),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                "Next",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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

  Widget _buildPage(_OnboardingPage page) {
    final isBrandPage = page.icon == null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isBrandPage) ...[
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 25,
                    offset: const Offset(0, 25),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  'assets/images/f2t_logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              page.title,
              style: const TextStyle(
                fontFamily: "Outfit",
                fontWeight: FontWeight.w800,
                fontSize: 38,
                color: Colors.white,
                letterSpacing: -0.95,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              page.subtitle!,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _pill("Reduce Waste"),
                const SizedBox(width: 8),
                _pill("Regrow Scraps"),
                const SizedBox(width: 8),
                _pill("AI-Powered"),
              ],
            ),
          ] else ...[
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(page.icon, color: Colors.white, size: 44),
            ),
            const SizedBox(height: 32),
            Text(
              page.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: "Outfit",
                fontWeight: FontWeight.w800,
                fontSize: 26,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              page.description!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _circleOutline(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.333,
        ),
      ),
    );
  }

  Widget _pill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.85),
        ),
      ),
    );
  }

  Widget _dot({required bool active}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: active ? 24 : 8,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: active ? 1 : 0.35),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
