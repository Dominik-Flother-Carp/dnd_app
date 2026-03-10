// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';
import 'package:dnd_app/theme/app_text_styles.dart';
import 'package:dnd_app/screens/character_list/character_list_screen.dart';

void main() {
  runApp(const DndApp());
}

class DndApp extends StatelessWidget {
  const DndApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'D&D Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B0000),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF3B1F0A),
          foregroundColor: Color(0xFFF5DEB3),
          centerTitle: true,
        ),
        cardTheme: const CardThemeData(
          elevation: 3,
          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
      ),

      // Startseite der App
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();

    // Nach 2 Sekunden zur Charakterliste wechseln
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const CharacterListScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3B1F0A),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5DEB3).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/shield_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'D&D Companion',
                      style: AppTextStyles.sectionTitle.copyWith(
                        color: const Color(0xFFF5DEB3),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Dein Begleiter am Spieltisch',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: const Color(0xFFF5DEB3).withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
