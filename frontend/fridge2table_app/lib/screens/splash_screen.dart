import 'package:flutter/material.dart';

import 'signin_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  void _continue(BuildContext context) {
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
            colors: [
              Color(0xFF081C15),
              Color(0xFF1B4332),
              Color(0xFF52B788),
            ],
            stops: [0.08, 0.58, 0.92],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              left: 20,
              child: _circleOutline(320),
            ),
            Positioned(
              bottom: -60,
              right: -40,
              child: _circleOutline(240),
            ),

            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 3),

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

                  const Text(
                    "Fridge2Table",
                    style: TextStyle(
                      fontFamily: "Outfit",
                      fontWeight: FontWeight.w800,
                      fontSize: 38,
                      color: Colors.white,
                      letterSpacing: -0.95,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Smart Pantry · Zero Waste · AI Recipes",
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

                  const SizedBox(height: 56),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _dot(width: 24, opacity: 1),
                      const SizedBox(width: 8),
                      _dot(width: 8, opacity: 0.35),
                      const SizedBox(width: 8),
                      _dot(width: 8, opacity: 0.35),
                    ],
                  ),

                  const Spacer(flex: 4),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _continue(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Create Free Account",
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
                        ),

                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => _continue(context),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.45),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              "I already have an account",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
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

  Widget _dot({required double width, required double opacity}) {
    return Container(
      width: width,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
