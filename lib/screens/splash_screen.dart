import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home_screen.dart';
import 'language_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      final user = FirebaseAuth.instance.currentUser;

      // ✅ If logged in -> Home, else -> Language
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => user == null ? const LanguageScreen() : const HomeScreen(),
        ),
      );
    });
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
              Color(0xFF12C2A9),
              Color(0xFF2F7CF6),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text("🤝", style: TextStyle(fontSize: 40)),
                  ),
                ),
                const SizedBox(height: 18),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      "Trade Connect",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text("✨", style: TextStyle(fontSize: 20)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  "Connect. Trade. Grow.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 26),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _dot(active: true),
                    const SizedBox(width: 6),
                    _dot(active: false),
                    const SizedBox(width: 6),
                    _dot(active: false),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _dot({required bool active}) {
    return Container(
      width: active ? 18 : 7,
      height: 7,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white54,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}
