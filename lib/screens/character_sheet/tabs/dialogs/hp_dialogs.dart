// lib/screens/character_sheet/tabs/dialogs/hp_dialogs.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dnd_app/theme/app_text_styles.dart';

// ── HP setzen ─────────────────────────────────────────────────────────────────

class HpDialogResult {
  final int value;
  const HpDialogResult(this.value);
}

class HpDialog extends StatefulWidget {
  final int currentHp;
  final int maxHp;
  final Color themeColor;

  const HpDialog({
    super.key,
    required this.currentHp,
    required this.maxHp,
    required this.themeColor,
  });

  @override
  State<HpDialog> createState() => _HpDialogState();
}

class _HpDialogState extends State<HpDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.currentHp}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Trefferpunkte setzen', style: AppTextStyles.sectionTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Maximum: ${widget.maxHp}', style: AppTextStyles.body),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTextStyles.body,
            decoration: const InputDecoration(
              labelText: 'Aktuelle TP',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Abbrechen', style: AppTextStyles.body),
        ),
        FilledButton(
          onPressed: () {
            final value = int.tryParse(_controller.text);
            if (value != null) {
              Navigator.pop(context, HpDialogResult(value));
            }
          },
          style: FilledButton.styleFrom(backgroundColor: widget.themeColor),
          child: Text('Speichern', style: AppTextStyles.body),
        ),
      ],
    );
  }
}

// ── Schaden / Heilung ─────────────────────────────────────────────────────────

class DamageHealDialogResult {
  final int value;
  const DamageHealDialogResult(this.value);
}

class DamageHealDialog extends StatefulWidget {
  final bool isDamage;

  const DamageHealDialog({super.key, required this.isDamage});

  @override
  State<DamageHealDialog> createState() => _DamageHealDialogState();
}

class _DamageHealDialogState extends State<DamageHealDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.isDamage ? 'Schaden erleiden' : 'Heilen',
        style: AppTextStyles.sectionTitle,
      ),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: AppTextStyles.body,
        decoration: InputDecoration(
          labelText: widget.isDamage ? 'Schadenspunkte' : 'Heilungspunkte',
          border: const OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Abbrechen', style: AppTextStyles.body),
        ),
        FilledButton(
          onPressed: () {
            final value = int.tryParse(_controller.text);
            if (value != null) {
              Navigator.pop(context, DamageHealDialogResult(value));
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: widget.isDamage ? Colors.red : Colors.green,
          ),
          child: Text('Bestätigen', style: AppTextStyles.body),
        ),
      ],
    );
  }
}

// ── Temporäre TP ──────────────────────────────────────────────────────────────

class TempHpDialogResult {
  final int value;
  const TempHpDialogResult(this.value);
}

class TempHpDialog extends StatefulWidget {
  final int currentTempHp;

  const TempHpDialog({super.key, required this.currentTempHp});

  @override
  State<TempHpDialog> createState() => _TempHpDialogState();
}

class _TempHpDialogState extends State<TempHpDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.currentTempHp}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Temporäre TP', style: AppTextStyles.sectionTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Temporäre TP stapeln sich nicht – '
            'nur der höhere Wert zählt.',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTextStyles.body,
            decoration: const InputDecoration(
              labelText: 'Temporäre TP',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Abbrechen', style: AppTextStyles.body),
        ),
        FilledButton(
          onPressed: () {
            final value = int.tryParse(_controller.text);
            if (value != null) {
              Navigator.pop(context, TempHpDialogResult(value));
            }
          },
          style: FilledButton.styleFrom(backgroundColor: Colors.blue),
          child: Text('Setzen', style: AppTextStyles.body),
        ),
      ],
    );
  }
}
