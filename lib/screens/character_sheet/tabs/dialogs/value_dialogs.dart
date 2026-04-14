// lib/screens/character_sheet/tabs/dialogs/value_dialogs.dart
//
// Generische Eingabe-Dialoge für Zahlen (int und double).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dnd_app/theme/app_text_styles.dart';
import 'package:dnd_app/utils/format_utils.dart';

// ── Integer-Dialog ────────────────────────────────────────────────────────────

class NumberDialogResult {
  final int value;
  const NumberDialogResult(this.value);
}

class NumberDialog extends StatefulWidget {
  final String label;
  final int currentValue;
  final int min;
  final int max;
  final Color themeColor;

  const NumberDialog({
    super.key,
    required this.label,
    required this.currentValue,
    required this.min,
    required this.max,
    required this.themeColor,
  });

  @override
  State<NumberDialog> createState() => _NumberDialogState();
}

class _NumberDialogState extends State<NumberDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.currentValue}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.label, style: AppTextStyles.sectionTitle),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: AppTextStyles.body,
        decoration: const InputDecoration(border: OutlineInputBorder()),
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
            if (value != null &&
                value >= widget.min &&
                value <= widget.max) {
              Navigator.pop(context, NumberDialogResult(value));
            }
          },
          style: FilledButton.styleFrom(backgroundColor: widget.themeColor),
          child: Text('Speichern', style: AppTextStyles.body),
        ),
      ],
    );
  }
}

// ── Double-Dialog ─────────────────────────────────────────────────────────────

class DoubleDialogResult {
  final double value;
  const DoubleDialogResult(this.value);
}

class DoubleDialog extends StatefulWidget {
  final String label;
  final double currentValue;
  final double min;
  final double max;
  final Color themeColor;

  const DoubleDialog({
    super.key,
    required this.label,
    required this.currentValue,
    required this.min,
    required this.max,
    required this.themeColor,
  });

  @override
  State<DoubleDialog> createState() => _DoubleDialogState();
}

class _DoubleDialogState extends State<DoubleDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: fmtSpeed(widget.currentValue).replaceAll(' m', ''),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.label, style: AppTextStyles.sectionTitle),
      content: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*[,.]?\d*')),
        ],
        style: AppTextStyles.body,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          suffixText: 'm',
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
            final text = _controller.text.replaceAll(',', '.');
            final value = double.tryParse(text);
            if (value != null &&
                value >= widget.min &&
                value <= widget.max) {
              Navigator.pop(context, DoubleDialogResult(value));
            }
          },
          style: FilledButton.styleFrom(backgroundColor: widget.themeColor),
          child: Text('Speichern', style: AppTextStyles.body),
        ),
      ],
    );
  }
}
