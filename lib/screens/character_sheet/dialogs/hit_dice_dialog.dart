// lib/screens/character_sheet/dialogs/hit_dice_dialog.dart

import 'package:flutter/material.dart';
import 'package:dnd_app/theme/app_text_styles.dart';

class HitDiceDialogResult {
  final int amount;
  const HitDiceDialogResult(this.amount);
}

class HitDiceDialog extends StatefulWidget {
  final int available;
  final int hitDie;
  final int conModifier;
  final Color themeColor;

  const HitDiceDialog({
    super.key,
    required this.available,
    required this.hitDie,
    required this.conModifier,
    required this.themeColor,
  });

  @override
  State<HitDiceDialog> createState() => _HitDiceDialogState();
}

class _HitDiceDialogState extends State<HitDiceDialog> {
  int _amount = 1;

  @override
  Widget build(BuildContext context) {
    final conText = widget.conModifier >= 0
        ? '+${widget.conModifier}'
        : '${widget.conModifier}';

    return AlertDialog(
      title: Text('Trefferwürfel ausgeben', style: AppTextStyles.sectionTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.themeColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Verfügbar',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: Colors.grey)),
                Text(
                  '${widget.available} W${widget.hitDie}',
                  style: AppTextStyles.statMedium
                      .copyWith(color: widget.themeColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                color: widget.themeColor,
                onPressed: _amount > 1
                    ? () => setState(() => _amount--)
                    : null,
              ),
              Column(
                children: [
                  Text(
                    '$_amount',
                    style: AppTextStyles.statLarge
                        .copyWith(color: widget.themeColor),
                  ),
                  Text(
                    'Würfel',
                    style: AppTextStyles.labelXs.copyWith(color: Colors.grey),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                color: widget.themeColor,
                onPressed: _amount < widget.available
                    ? () => setState(() => _amount++)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Pro Würfel: W${widget.hitDie} + KON ($conText)',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Abbrechen', style: AppTextStyles.body),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, HitDiceDialogResult(_amount)),
          style: FilledButton.styleFrom(
              backgroundColor: widget.themeColor),
          child: Text('Ausgeben', style: AppTextStyles.body),
        ),
      ],
    );
  }
}
