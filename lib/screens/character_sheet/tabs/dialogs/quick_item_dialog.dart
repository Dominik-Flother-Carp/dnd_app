// lib/screens/character_sheet/tabs/dialogs/quick_item_dialog.dart

import 'package:flutter/material.dart';
import 'package:dnd_app/models/item.dart';
import 'package:dnd_app/models/quick_item.dart';
import 'package:dnd_app/theme/app_text_styles.dart';

class QuickItemDialog extends StatefulWidget {
  final String characterId;
  final Color themeColor;
  final QuickItem? existing;

  const QuickItemDialog({
    super.key,
    required this.characterId,
    required this.themeColor,
    this.existing,
  });

  @override
  State<QuickItemDialog> createState() => _QuickItemDialogState();
}

class _QuickItemDialogState extends State<QuickItemDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _quantityCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _valueCtrl;
  late ItemCategory _category;

  bool get _isNew => widget.existing == null;

  static const _allowedCategories = [
    ItemCategory.treasure,
    ItemCategory.misc,
  ];

  @override
  void initState() {
    super.initState();
    final q = widget.existing;
    _nameCtrl     = TextEditingController(text: q?.name ?? '');
    _notesCtrl    = TextEditingController(text: q?.notes ?? '');
    _quantityCtrl = TextEditingController(text: '${q?.quantity ?? 1}');
    _weightCtrl   = TextEditingController(text: q != null ? '${q.weight}' : '0');
    _valueCtrl    = TextEditingController(text: q != null ? '${q.valueInCopper}' : '0');
    _category = q?.category ?? ItemCategory.misc;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    _quantityCtrl.dispose();
    _weightCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_nameCtrl.text.trim().isEmpty) return;
    final q = QuickItem(
      id:            widget.existing?.id,
      characterId:   widget.characterId,
      name:          _nameCtrl.text.trim(),
      category:      _category,
      notes:         _notesCtrl.text.trim(),
      quantity:      int.tryParse(_quantityCtrl.text) ?? 1,
      weight:        double.tryParse(_weightCtrl.text) ?? 0,
      valueInCopper: int.tryParse(_valueCtrl.text) ?? 0,
    );
    Navigator.pop(context, q);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isNew ? 'Schnellitem hinzufügen' : 'Schnellitem bearbeiten',
        style: AppTextStyles.sectionTitle,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              style: AppTextStyles.body,
              autofocus: _isNew,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ItemCategory>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Kategorie',
                border: OutlineInputBorder(),
              ),
              items: _allowedCategories
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.label, style: AppTextStyles.body),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantityCtrl,
                    keyboardType: TextInputType.number,
                    style: AppTextStyles.body,
                    decoration: const InputDecoration(
                      labelText: 'Menge',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _weightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: AppTextStyles.body,
                    decoration: const InputDecoration(
                      labelText: 'Gewicht (lb)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _valueCtrl,
                    keyboardType: TextInputType.number,
                    style: AppTextStyles.body,
                    decoration: const InputDecoration(
                      labelText: 'Wert (KM)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              style: AppTextStyles.body,
              maxLines: 2,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                labelText: 'Notizen',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
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
              style: FilledButton.styleFrom(backgroundColor: widget.themeColor),
              onPressed: _onSave,
              child: Text('Speichern', style: AppTextStyles.body),
            ),
          ],
        ),
      ],
    );
  }
}
