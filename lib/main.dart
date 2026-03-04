import 'package:flutter/material.dart';
import 'package:dnd_app/screens/character_list/character_list_screen.dart';

void main() {
  runApp(const DndApp());
}

class DndApp extends StatelessWidget {
  const DndApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DnD Charakterverwaltung',
      debugShowCheckedModeBanner: false,
      
      // ── Theme ──────────────────────────────────────────────────────────────
      // ColorScheme.fromSeed generiert eine vollständige Farbpalette
      // aus einer einzigen Hauptfarbe
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B0000), // Dunkelrot – klassisches DnD
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: const TextTheme(
          bodyMedium:  TextStyle(fontSize: 15),
          bodySmall:   TextStyle(fontSize: 13),
          bodyLarge:   TextStyle(fontSize: 17),
          titleMedium: TextStyle(fontSize: 17),
          titleSmall:  TextStyle(fontSize: 15),
        ),
        // AppBar einheitlich dunkel gestalten
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF3B1F0A),
          foregroundColor: Color(0xFFF5DEB3),
          centerTitle: true,
        ),

        // Karten leicht erhöht darstellen
        cardTheme: const CardThemeData(
          elevation: 3,
          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
      ),

      // Startseite der App
      home: const CharacterListScreen(),
    );
  }
}