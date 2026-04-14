// lib/screens/character_sheet/tabs/dialogs/movement_info_dialog.dart

import 'package:flutter/material.dart';
import 'package:dnd_app/theme/app_text_styles.dart';

class MovementInfoDialog extends StatelessWidget {
  final double speed;
  final int strength;
  final int strModifier;
  final Color themeColor;

  const MovementInfoDialog({
    super.key,
    required this.speed,
    required this.strength,
    required this.strModifier,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    // Sprung (5e Regeln, Fuß → m: 1 ft ≈ 0,3 m)
    final longJumpRun   = strength * 0.3;
    final longJumpStand = longJumpRun * 0.5;
    final highJumpRun   = ((3 + strModifier) * 0.3).clamp(0, 999).toDouble();
    final highJumpStand = (highJumpRun * 0.5).toDouble();

    // Tragen/Heben (5e Regeln, 1 lb ≈ 0,45 kg)
    final carryLb = strength * 15;
    final liftLb  = strength * 30;
    final carryKg = (carryLb * 0.45).round();
    final liftKg  = (liftLb * 0.45).round();

    String fmt(double meters) {
      if (meters <= 0) return '0 m';
      final rounded = (meters * 2).round() / 2;
      return rounded == rounded.roundToDouble()
          ? '${rounded.toInt()} m'
          : '${rounded.toStringAsFixed(1)} m';
    }

    return AlertDialog(
      title: Text('Bewegung & Kraft', style: AppTextStyles.sectionTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSection(
            icon: Icons.directions_run,
            label: 'Bewegungsrate',
            color: themeColor,
            rows: [
              ('Laufen', fmt(speed)),
              ('Schleichen', fmt(speed / 2)),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            icon: Icons.open_with,
            label: 'Springen (STR $strength)',
            color: Colors.blue,
            rows: [
              ('Weiter Sprung (Anlauf)', fmt(longJumpRun)),
              ('Weiter Sprung (Stand)',  fmt(longJumpStand)),
              ('Hoher Sprung (Anlauf)',  fmt(highJumpRun)),
              ('Hoher Sprung (Stand)',   fmt(highJumpStand)),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            icon: Icons.fitness_center,
            label: 'Tragen & Heben (STR $strength)',
            color: Colors.orange,
            rows: [
              ('Tragegrenze', '$carryKg kg  ($carryLb lb)'),
              ('Bewegen',     '$liftKg kg  ($liftLb lb)'),
            ],
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          style: FilledButton.styleFrom(backgroundColor: themeColor),
          child: Text('OK', style: AppTextStyles.body),
        ),
      ],
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String label,
    required Color color,
    required List<(String, String)> rows,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(label,
                  style: AppTextStyles.bodySmall.copyWith(
                      color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(r.$1,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.grey[600])),
                    Text(r.$2,
                        style: AppTextStyles.bodySmall
                            .copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
