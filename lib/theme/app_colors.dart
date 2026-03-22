// lib/theme/app_colors.dart
//
// Zentrale Farbkonstanten und Hilfsfunktionen.
// Verhindert doppelte Farbdefinitionen in character_card, character_sheet_screen
// und character_create_screen.

import 'package:flutter/material.dart';
import 'package:dnd_app/models/spell.dart';

class AppColors {
  AppColors._();

  // ── Edition-Farben ─────────────────────────────────────────────────────────
  // Werden in character_card, character_sheet_screen und character_create_screen
  // genutzt. Früher dreifach als inline-Literal definiert.

  /// Themefarbe für D&D 2014 (Braun)
  static const Color edition2014 = Color(0xFF3B1F0A);

  /// Themefarbe für D&D 2024 (Blau)
  static const Color edition2024 = Color(0xFF1B4F72);

  /// Gibt die passende Themefarbe für einen Charakter zurück.
  static Color themeColorFor(bool useEdition2024) =>
      useEdition2024 ? edition2024 : edition2014;

  // ── HP-Farbe ────────────────────────────────────────────────────────────────
  // Identische ratio-Logik war in character_card, overview_tab und
  // initiative_tracker_screen dreifach definiert.

  /// Gibt die passende HP-Farbe zurück.
  /// [ratio] = currentHp / maxHp, erwartet einen Wert zwischen 0.0 und 1.0.
  static Color hpColor(double ratio) {
    if (ratio > 0.5) return Colors.green;
    if (ratio > 0.25) return Colors.orange;
    return Colors.red;
  }

  // ── Zauberscbulen-Farben ────────────────────────────────────────────────────
  // Identische switch-Anweisung war in compendium_screen und
  // compendium_detail_sheet doppelt definiert.

  /// Gibt die Akzentfarbe für eine Zauberschule zurück.
  static Color spellSchoolColor(SpellSchool school) {
    switch (school) {
      case SpellSchool.abjuration:    return Colors.blue;
      case SpellSchool.conjuration:   return Colors.yellow[700]!;
      case SpellSchool.divination:    return Colors.cyan;
      case SpellSchool.enchantment:   return Colors.pink;
      case SpellSchool.evocation:     return Colors.orange;
      case SpellSchool.illusion:      return Colors.purple;
      case SpellSchool.necromancy:    return Colors.green[700]!;
      case SpellSchool.transmutation: return Colors.teal;
    }
  }
}