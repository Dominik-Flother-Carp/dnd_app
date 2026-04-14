// lib/screens/character_sheet/dialogs/level_up_dialog.dart

import 'package:flutter/material.dart';
import 'package:dnd_app/models/classes.dart';
import 'package:dnd_app/theme/app_text_styles.dart';

class LevelUpResult {
  final String? newSubclass; // null = keine Unterklasse gewählt/erforderlich
  final int hpGain;
  const LevelUpResult({this.newSubclass, required this.hpGain});
}

class LevelUpDialog extends StatefulWidget {
  final int newLevel;
  final int hitDie;
  final int conModifier;
  final String characterClass;
  final String currentSubclass; // leer = noch keine
  final Color themeColor;

  const LevelUpDialog({
    super.key,
    required this.newLevel,
    required this.hitDie,
    required this.conModifier,
    required this.characterClass,
    required this.currentSubclass,
    required this.themeColor,
  });

  @override
  State<LevelUpDialog> createState() => _LevelUpDialogState();
}

class _LevelUpDialogState extends State<LevelUpDialog> {
  String? _selectedSubclass;
  bool _useMax = false;

  @override
  void initState() {
    super.initState();
    _selectedSubclass = widget.currentSubclass.isEmpty
        ? null
        : widget.currentSubclass;
  }

  List<CharacterSubclass> get _availableSubs =>
      availableSubclasses(widget.characterClass, widget.newLevel);

  bool get _subclassChoiceRequired =>
      widget.currentSubclass.isEmpty &&
      _availableSubs.any((s) => s.unlocksAtLevel == widget.newLevel);

  int get _hpGain {
    final roll = _useMax ? widget.hitDie : (widget.hitDie / 2).ceil();
    return (roll + widget.conModifier).clamp(1, 999);
  }

  bool get _canConfirm =>
      !_subclassChoiceRequired || _selectedSubclass != null;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Stufenaufstieg auf Stufe ${widget.newLevel}',
        style: AppTextStyles.sectionTitle,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Trefferpunkte',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600])),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                      value: false,
                      label: Text(
                        'Durchschnitt (+${(widget.hitDie / 2).ceil() + widget.conModifier})',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text(
                        'Maximum (+${widget.hitDie + widget.conModifier})',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ],
                  selected: {_useMax},
                  onSelectionChanged: (s) =>
                      setState(() => _useMax = s.first),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? widget.themeColor
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_subclassChoiceRequired) ...[
            const SizedBox(height: 16),
            Text('Unterklasse wählen',
                style: AppTextStyles.bodySmall
                    .copyWith(color: Colors.grey[600])),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedSubclass,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                hintText: 'Wählen…',
              ),
              items: _availableSubs
                  .map((s) => DropdownMenuItem(
                        value: s.name,
                        child: Text(s.name, style: AppTextStyles.body),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedSubclass = v),
            ),
          ],
        ],
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Abbrechen', style: AppTextStyles.body),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: _canConfirm
                  ? () => Navigator.pop(
                        context,
                        LevelUpResult(
                          newSubclass: _selectedSubclass,
                          hpGain: _hpGain,
                        ),
                      )
                  : null,
              style: FilledButton.styleFrom(
                  backgroundColor: widget.themeColor),
              child: Text('Aufsteigen', style: AppTextStyles.body),
            ),
          ],
        ),
      ],
    );
  }
}
