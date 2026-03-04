// lib/theme/app_text_styles.dart

import 'package:flutter/material.dart';

/// Zentrale Schriftgrößen und -gewichte für die gesamte App.
/// Farben werden bewusst weggelassen – diese verwaltet Material3.
class AppTextStyles {
  AppTextStyles._();

  // ── Größen ─────────────────────────────────────────────────────────────────
  static const double _xs  = 12;
  static const double _sm  = 14;
  static const double _md  = 16;
  static const double _lg  = 18;
  static const double _xl  = 20;
  static const double _xxl = 24;
  static const double _xxxl = 30;

  // ── Überschriften ──────────────────────────────────────────────────────────
  static const TextStyle screenTitle = TextStyle(
    fontSize: _xxl,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: _lg,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: _md,
    fontWeight: FontWeight.bold,
  );

  // ── Fließtext ──────────────────────────────────────────────────────────────
  static const TextStyle body = TextStyle(
    fontSize: _md,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: _sm,
  );

  // ── Zahlen / Werte ─────────────────────────────────────────────────────────
  static const TextStyle statLarge = TextStyle(
    fontSize: _xl,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle statMedium = TextStyle(
    fontSize: _md,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle statSmall = TextStyle(
    fontSize: _sm,
    fontWeight: FontWeight.bold,
  );

  // ── Labels ─────────────────────────────────────────────────────────────────
  static const TextStyle label = TextStyle(
    fontSize: _sm,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle labelXs = TextStyle(
    fontSize: _xs,
  );

  // ── Avatar ─────────────────────────────────────────────────────────────────
  static const TextStyle avatarLarge = TextStyle(
    fontSize: _xxxl,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle avatarMedium = TextStyle(
    fontSize: _xxl,
    fontWeight: FontWeight.bold,
  );

  // ── Badge / Pill ───────────────────────────────────────────────────────────
  // Farbe bleibt weiß da Badges immer auf farbigem Hintergrund stehen
  static const TextStyle badge = TextStyle(
    fontSize: _sm,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle badgeSmall = TextStyle(
    fontSize: _xs,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
}