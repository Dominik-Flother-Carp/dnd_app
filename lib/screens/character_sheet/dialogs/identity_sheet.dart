// lib/screens/character_sheet/dialogs/identity_sheet.dart

import 'package:flutter/material.dart';
import 'package:dnd_app/models/character.dart';
import 'package:dnd_app/services/class_feature_service.dart';
import 'package:dnd_app/theme/app_text_styles.dart';
import 'package:dnd_app/widgets/widget_utils.dart';

class IdentitySheet extends StatefulWidget {
  final Character character;
  final Color themeColor;

  const IdentitySheet({
    super.key,
    required this.character,
    required this.themeColor,
  });

  @override
  State<IdentitySheet> createState() => _IdentitySheetState();
}

class _IdentitySheetState extends State<IdentitySheet> {
  final _featureService = ClassFeatureService();
  String? _classFluff;
  String? _subclassFluff;
  bool _fluffLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadFluff();
  }

  Future<void> _loadFluff() async {
    final c = widget.character;
    if (c.characterClass.isEmpty) {
      setState(() => _fluffLoaded = true);
      return;
    }
    final classFluff = await _featureService.getClassFluff(c.characterClass);
    final subclassFluff = c.subclass.isNotEmpty
        ? await _featureService.getSubclassFluff(c.characterClass, c.subclass)
        : null;
    if (mounted) {
      setState(() {
        _classFluff    = classFluff;
        _subclassFluff = subclassFluff;
        _fluffLoaded   = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.character;
    final rows = <({String label, String value})>[
      if (c.characterClass.isNotEmpty)
        (
          label: 'Klasse',
          value: c.subclass.isNotEmpty
              ? '${c.characterClass} · ${c.subclass}'
              : c.characterClass,
        ),
      if (c.race.isNotEmpty)       (label: 'Rasse',      value: c.race),
      if (c.alignment.isNotEmpty)  (label: 'Gesinnung',  value: c.alignment),
      if (c.background.isNotEmpty) (label: 'Hintergrund', value: c.background),
    ];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize:
          (_classFluff != null || _subclassFluff != null) ? 0.6 : 0.4,
      minChildSize: 0.3,
      maxChildSize: 0.92,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name, style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 16),
                    ...rows.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 100,
                                child: Text(r.label,
                                    style: AppTextStyles.bodySmall
                                        .copyWith(color: Colors.grey[500])),
                              ),
                              Expanded(
                                child: Text(r.value,
                                    style: AppTextStyles.body),
                              ),
                            ],
                          ),
                        )),
                    if (rows.isEmpty)
                      Text('Keine weiteren Angaben.',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: Colors.grey)),
                    if (!_fluffLoaded)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator(),
                      )
                    else ...[
                      if (_classFluff != null &&
                          _classFluff!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Divider(color: Colors.grey[200]),
                        const SizedBox(height: 12),
                        Text(
                          widget.character.characterClass,
                          style: AppTextStyles.cardTitle
                              .copyWith(color: widget.themeColor),
                        ),
                        const SizedBox(height: 8),
                        MarkdownText(_classFluff!),
                      ],
                      if (_subclassFluff != null &&
                          _subclassFluff!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        if (_classFluff == null)
                          Divider(color: Colors.grey[200]),
                        if (_classFluff == null)
                          const SizedBox(height: 12),
                        Text(
                          widget.character.subclass,
                          style: AppTextStyles.cardTitle
                              .copyWith(color: widget.themeColor),
                        ),
                        const SizedBox(height: 8),
                        MarkdownText(_subclassFluff!),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
