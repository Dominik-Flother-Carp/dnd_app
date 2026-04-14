// lib/screens/character_sheet/tabs/dialogs/notes_dialog.dart

import 'package:flutter/material.dart';
import 'package:dnd_app/theme/app_text_styles.dart';

class NotesDialog extends StatefulWidget {
  final String itemName;
  final String currentNotes;
  final Color themeColor;

  const NotesDialog({
    super.key,
    required this.itemName,
    required this.currentNotes,
    required this.themeColor,
  });

  @override
  State<NotesDialog> createState() => _NotesDialogState();
}

class _NotesDialogState extends State<NotesDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.currentNotes);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.itemName, style: AppTextStyles.sectionTitle),
      content: TextField(
        controller: _ctrl,
        style: AppTextStyles.body,
        maxLines: 5,
        textAlignVertical: TextAlignVertical.top,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Notizen zum Item…',
          border: OutlineInputBorder(),
          alignLabelWithHint: true,
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
              onPressed: () => Navigator.pop(context, _ctrl.text.trim()),
              child: Text('Speichern', style: AppTextStyles.body),
            ),
          ],
        ),
      ],
    );
  }
}
