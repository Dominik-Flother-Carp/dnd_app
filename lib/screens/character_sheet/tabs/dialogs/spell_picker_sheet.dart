// lib/screens/character_sheet/tabs/dialogs/spell_picker_sheet.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dnd_app/models/spell.dart';
import 'package:dnd_app/services/compendium_service.dart';
import 'package:dnd_app/theme/app_text_styles.dart';

/// Badge das den Zaubergrad anzeigt. Wird auch von SpellTab verwendet.
Widget spellLevelBadge(int level, Color color) {
  final label = level == 0 ? 'T' : '$level';
  return Container(
    width: 28,
    height: 28,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: AppTextStyles.bodySmall.copyWith(
        color: color,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

class SpellPickerSheet extends StatefulWidget {
  final Color themeColor;
  final String characterClass;
  final Set<String> alreadyAdded;
  final int maxSpellLevel;
  final int? maxCount;
  final Set<String> alreadyForLimit;

  const SpellPickerSheet({
    super.key,
    required this.themeColor,
    required this.characterClass,
    required this.alreadyAdded,
    required this.maxSpellLevel,
    this.maxCount,
    Set<String>? alreadyForLimit,
  }) : alreadyForLimit = alreadyForLimit ?? alreadyAdded;

  @override
  State<SpellPickerSheet> createState() => _SpellPickerSheetState();
}

class _SpellPickerSheetState extends State<SpellPickerSheet> {
  final _searchCtrl = TextEditingController();
  final _service    = CompendiumService();

  List<Spell> _results = [];
  bool _loading = true;

  Timer? _debounce;

  bool get _isFull =>
      widget.maxCount != null &&
      widget.alreadyForLimit.length >= widget.maxCount!;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_onSearchDebounced);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.removeListener(_onSearchDebounced);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await _service.load();
    _onSearch();
  }

  void _onSearchDebounced() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () {
      if (mounted) _onSearch();
    });
  }

  void _onSearch() {
    final allResults = _service.searchSpells(
      _searchCtrl.text,
      className:
          widget.characterClass.isEmpty ? null : widget.characterClass,
    );
    final results = allResults
        .where((s) => s.level <= widget.maxSpellLevel)
        .where((s) => !widget.alreadyAdded.contains(s.id))
        .toList();
    if (mounted) {
      setState(() {
        _results = results;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollCtrl) {
        return Column(
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Text('Zauberauswahl', style: AppTextStyles.sectionTitle),
                  const Spacer(),
                  if (widget.maxCount != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _isFull
                            ? Colors.red.withValues(alpha: 0.12)
                            : widget.themeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${widget.alreadyForLimit.length} / ${widget.maxCount}',
                        style: AppTextStyles.labelXs.copyWith(
                          color: _isFull ? Colors.red : widget.themeColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (widget.characterClass.isNotEmpty)
                    Chip(
                      label: Text(
                        widget.characterClass,
                        style: AppTextStyles.labelXs,
                      ),
                      backgroundColor:
                          widget.themeColor.withValues(alpha: 0.12),
                      side: BorderSide.none,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 4),
                    ),
                ],
              ),
            ),
            if (_isFull)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'Zauberbuch voll. Auf dieser Stufe können keine weiteren Zauber eingetragen werden.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: Colors.red[700]),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  hintText: 'Zauber suchen…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _searchCtrl.clear,
                        )
                      : null,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                      ? Center(
                          child: Text(
                            'Keine Zauber gefunden',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: Colors.grey),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: _results.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 4),
                          itemBuilder: (_, i) =>
                              _buildSpellTile(_results[i]),
                        ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSpellTile(Spell spell) {
    final alreadyAdded = widget.alreadyAdded.contains(spell.id);
    final blocked = !alreadyAdded && _isFull;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: spellLevelBadge(spell.level, widget.themeColor),
        title: Text(
          spell.name,
          style: AppTextStyles.cardTitle.copyWith(
            color: blocked ? Colors.grey[400] : null,
          ),
        ),
        subtitle: Text(
          [
            spell.school.label,
            if (spell.concentration) 'Konzentration',
            if (spell.ritual) 'Ritual',
          ].join(' · '),
          style:
              AppTextStyles.bodySmall.copyWith(color: Colors.grey[500]),
        ),
        trailing: alreadyAdded
            ? Icon(Icons.check_circle,
                color: widget.themeColor, size: 22)
            : Icon(
                Icons.add_circle_outline,
                size: 22,
                color: blocked ? Colors.grey[300] : null,
              ),
        onTap: (alreadyAdded || blocked)
            ? null
            : () => Navigator.pop(context, spell),
      ),
    );
  }
}
