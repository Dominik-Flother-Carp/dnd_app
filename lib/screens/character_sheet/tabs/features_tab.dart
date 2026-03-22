// lib/screens/character_sheet/tabs/features_tab.dart

import 'package:flutter/material.dart';
import 'package:dnd_app/models/character.dart';
import 'package:dnd_app/models/class_feature.dart';
import 'package:dnd_app/repositories/character_repository.dart';
import 'package:dnd_app/services/class_feature_service.dart';
import 'package:dnd_app/services/compendium_service.dart';
import 'package:dnd_app/theme/app_text_styles.dart';
import 'package:dnd_app/widgets/widget_utils.dart';

class FeaturesTab extends StatefulWidget {
  final Character character;
  final Color themeColor;

  const FeaturesTab({
    super.key,
    required this.character,
    required this.themeColor,
  });

  @override
  State<FeaturesTab> createState() => FeaturesTabState();
}

class FeaturesTabState extends State<FeaturesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _service    = ClassFeatureService();
  final _repo       = CharacterRepository();
  final _compendium = CompendiumService();

  List<ClassFeature> _features    = [];
  Map<String, int>    _uses       = {};
  Map<String, String> _choices    = {};
  Map<String, String> _spellNames = {};
  // Gecacht – wird nur in _load() neu berechnet, nicht bei jedem build()
  List<MapEntry<int, List<ClassFeature>>> _groupedEntries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> reload() => _load();

  Future<void> _load() async {
    await _compendium.load();
    final features = await _service.getFeaturesForCharacter(widget.character);
    final uses     = await _repo.getFeatureUses(widget.character.id);
    final choices  = await _repo.getAllFeatureChoices(widget.character.id);

    final spellNames = <String, String>{};
    for (final f in features) {
      for (final gs in f.grantedSpells ?? []) {
        final spell = _compendium.getSpellById(gs.spellId);
        spellNames[gs.spellId] = spell?.name ?? gs.spellId;
      }
    }

    await _syncGrantedSpells(features);

    if (!mounted) return;
    setState(() {
      _features      = features;
      _uses          = uses;
      _choices       = choices;
      _spellNames    = spellNames;
      _groupedEntries = _buildGroupedEntries(features);
      _isLoading     = false;
    });
  }

  Future<void> _syncGrantedSpells(List<ClassFeature> features) async {
    for (final f in features) {
      if (f.grantedSpells == null) continue;
      for (final gs in f.grantedSpells!) {
        if (gs.atLevel > widget.character.level) continue;
        final spell = _compendium.getSpellById(gs.spellId);
        if (spell == null) continue;
        await _repo.upsertSpell(spell);
        await _repo.addSpellToCharacter(
          widget.character.id,
          gs.spellId,
          isPrepared: true,
        );
      }
    }
  }

  // ── Ressourcen-Logik ───────────────────────────────────────────────────────

  int _currentUses(ClassFeature f) => _uses[f.id] ?? 0;
  int _maxUses(ClassFeature f)     => f.resource!.evaluate(widget.character);
  int _remaining(ClassFeature f)   =>
      (_maxUses(f) - _currentUses(f)).clamp(0, _maxUses(f));

  Future<void> _spend(ClassFeature f) async {
    final current = _currentUses(f);
    final max     = _maxUses(f);
    if (current >= max) return;
    final newVal = current + 1;
    setState(() => _uses[f.id] = newVal);
    await _repo.setFeatureUses(widget.character.id, f.id, newVal);
  }

  Future<void> _restore(ClassFeature f) async {
    final current = _currentUses(f);
    if (current <= 0) return;
    final newVal = current - 1;
    setState(() => _uses[f.id] = newVal);
    await _repo.setFeatureUses(widget.character.id, f.id, newVal);
  }

  Future<void> resetForRest(String restType) async {
    final toReset = _features.where((f) {
      if (f.resource == null) return false;
      if (restType == 'long') return true;
      return f.resource!.restType == 'short';
    }).map((f) => f.id).toList();

    await _repo.resetFeatureUses(widget.character.id, toReset);
    setState(() {
      for (final id in toReset) {
        _uses[id] = 0;
      }
    });
  }

  // ── Gruppierung nach Level ─────────────────────────────────────────────────

  /// Berechnet die Gruppierung einmalig – Ergebnis wird in _groupedEntries
  /// gecacht und nur bei _load() neu berechnet.
  List<MapEntry<int, List<ClassFeature>>> _buildGroupedEntries(
      List<ClassFeature> features) {
    final map = <int, List<ClassFeature>>{};
    for (final f in features) {
      if (f.extendsFeatureId != null) continue;
      map.putIfAbsent(f.unlocksAtLevel, () => []).add(f);
    }
    return (map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }

  // Flache Liste aller Zeilen für den SliverChildBuilderDelegate:
  // Abwechselnd ein Level-Header und n Feature-Karten pro Level.
  List<Widget> get _flatRows {
    final rows = <Widget>[];
    for (final entry in _groupedEntries) {
      rows.add(_buildLevelHeader(entry.key));
      rows.addAll(entry.value.map(_buildFeatureCard));
    }
    return rows;
  }

  // ── Detail-Sheet öffnen ───────────────────────────────────────────────────

  void _openDetailSheet(ClassFeature f) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FeatureDetailSheet(
        feature:    f,
        character:  widget.character,
        themeColor: widget.themeColor,
        spellNames: _spellNames,
        choices:    _choices,
        onChoiceMade: (featureId, optionId) async {
          await _repo.setFeatureChoice(
              widget.character.id, featureId, optionId);
          if (mounted) setState(() => _choices[featureId] = optionId);
        },
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_features.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_outlined,
                size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Keine Features',
                style: AppTextStyles.sectionTitle
                    .copyWith(color: Colors.grey[400])),
            const SizedBox(height: 8),
            Text(
              'Für ${widget.character.characterClass} sind\nnoch keine Features hinterlegt.',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: _buildSummaryCard(),
        ),
        Expanded(
          child: CustomScrollView(
            primary: false,
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _flatRows[i],
                    childCount: _flatRows.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Summary-Karte ──────────────────────────────────────────────────────────

  Widget _buildSummaryCard() {
    final c      = widget.character;
    final hasRes = _features.any((f) => f.resource != null);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.characterClass, style: AppTextStyles.cardTitle),
                  if (c.subclass.isNotEmpty)
                    Text(c.subclass,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.grey[500])),
                ],
              ),
            ),
            _summaryItem(
              Icons.auto_awesome_outlined,
              '${_features.where((f) => f.extendsFeatureId == null).length}',
              'Features',
            ),
            if (hasRes) ...[
              const SizedBox(width: 16),
              _summaryItem(
                Icons.battery_charging_full_outlined,
                '${_features.where((f) => f.resource != null).length}',
                'Ressourcen',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: widget.themeColor),
        const SizedBox(height: 2),
        Text(value,
            style: AppTextStyles.cardTitle
                .copyWith(color: widget.themeColor)),
        Text(label,
            style: AppTextStyles.labelXs
                .copyWith(color: Colors.grey[500])),
      ],
    );
  }

  // ── Level-Header ───────────────────────────────────────────────────────────

  Widget _buildLevelHeader(int level) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 12, 2, 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: widget.themeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Stufe $level',
              style: AppTextStyles.labelXs.copyWith(
                color: widget.themeColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: widget.themeColor.withValues(alpha: 0.2),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ── Feature-Karte (kompakt) ────────────────────────────────────────────────

  Widget _buildFeatureCard(ClassFeature f) {
    final hasChoice = f.choice != null && _choices[f.id] == null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openDetailSheet(f),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(f.name,
                              style: AppTextStyles.cardTitle),
                        ),
                        if (f.subclassName != null) ...[
                          const SizedBox(width: 6),
                          AppBadge(label: 'Unterklasse', color: widget.themeColor),
                        ],
                        if (hasChoice) ...[
                          const SizedBox(width: 6),
                          AppBadge(label: 'Wahl!', color: Colors.orange),
                        ],
                      ],
                    ),
                    if (f.resource != null) ...[
                      const SizedBox(height: 6),
                      _buildInlineResource(f),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right,
                  size: 18, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  // ── Ressource inline (auf der Karte) ───────────────────────────────────────

  Widget _buildInlineResource(ClassFeature f) {
    final remaining = _remaining(f);
    final max       = _maxUses(f);
    final isPool    = f.resource!.label == 'Pool';
    final restColor = f.resource!.restType == 'short'
        ? Colors.blue[600]!
        : Colors.purple[600]!;
    final restLabel =
        f.resource!.restType == 'short' ? 'K. Rast' : 'L. Rast';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: restColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(restLabel,
              style: AppTextStyles.labelXs.copyWith(color: restColor)),
        ),
        const SizedBox(width: 8),
        if (isPool) ...[
          _iconBtn(Icons.remove, () => _spend(f), active: remaining > 0),
          const SizedBox(width: 6),
          Text('$remaining / $max', style: AppTextStyles.bodySmall),
          const SizedBox(width: 6),
          _iconBtn(Icons.add, () => _restore(f), active: remaining < max),
        ] else ...[
          ...List.generate(max, (i) {
            final used = i >= remaining;
            return GestureDetector(
              onTap: used ? () => _restore(f) : () => _spend(f),
              child: Container(
                margin: const EdgeInsets.only(right: 5),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: used
                      ? Colors.grey[200]
                      : widget.themeColor.withValues(alpha: 0.15),
                  border: Border.all(
                    color: used ? Colors.grey[300]! : widget.themeColor,
                    width: 1.5,
                  ),
                ),
                child: used
                    ? null
                    : Icon(Icons.circle, size: 8, color: widget.themeColor),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap, {required bool active}) {
    return GestureDetector(
      onTap: active ? onTap : null,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: active
              ? widget.themeColor.withValues(alpha: 0.12)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(5),
        ),
        child: Icon(icon,
            size: 14,
            color: active ? widget.themeColor : Colors.grey[300]),
      ),
    );
  }
}

// ── Feature-Detail-Sheet ──────────────────────────────────────────────────────

class _FeatureDetailSheet extends StatelessWidget {
  final ClassFeature feature;
  final Character    character;
  final Color        themeColor;
  final Map<String, String> spellNames;
  final Map<String, String> choices;
  final Future<void> Function(String featureId, String optionId) onChoiceMade;

  const _FeatureDetailSheet({
    required this.feature,
    required this.character,
    required this.themeColor,
    required this.spellNames,
    required this.choices,
    required this.onChoiceMade,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Ziehgriff
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
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ────────────────────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.auto_awesome,
                            size: 28, color: themeColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(feature.name,
                                  style: AppTextStyles.sectionTitle),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  AppChip(label: 'Stufe ${feature.unlocksAtLevel}'),
                                  if (feature.subclassName != null)
                                    AppChip(label: 'Unterklasse', color: themeColor),
                                  if (feature.resource != null)
                                    AppChip(
                                      label: feature.resource!.restType == 'short'
                                          ? 'Kurze Rast'
                                          : 'Lange Rast',
                                      color: feature.resource!.restType == 'short'
                                          ? Colors.blue
                                          : Colors.purple,
                                    ),
                                  if (feature.choice != null &&
                                      choices[feature.id] == null)
                                    AppChip(label: 'Wahl erforderlich',
                                        color: Colors.orange),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // ── Beschreibung ──────────────────────────────────────
                    if (feature.description.isNotEmpty)
                      DetailSection(title: 'Beschreibung',
                          child: MarkdownText(feature.description)),

                    // ── Erweiterungen (Domänen) ───────────────────────────
                    if (feature.extensions.isNotEmpty)
                      DetailSection(
                        title: 'Domänen-Erweiterungen',
                        child: Column(
                          children: feature.extensions.map((ext) {
                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: themeColor.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color:
                                        themeColor.withValues(alpha: 0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(ext.name,
                                            style: AppTextStyles.cardTitle
                                                .copyWith(color: themeColor)),
                                      ),
                                      AppChip(label: 'Domäne', color: themeColor),
                                    ],
                                  ),
                                  if (ext.description.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    MarkdownText(ext.description),
                                  ],
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                    // ── Gewährte Zauber ───────────────────────────────────
                    if (feature.grantedSpells != null &&
                        feature.grantedSpells!.isNotEmpty)
                      DetailSection(
                        title: 'Gewährte Zauber',
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: feature.grantedSpells!.map((gs) {
                            final available = gs.atLevel <= character.level;
                            final name =
                                spellNames[gs.spellId] ?? gs.spellId;
                            return AppChip(label: name,
                                color: available ? themeColor : Colors.grey);
                          }).toList(),
                        ),
                      ),

                    // ── Wahl ─────────────────────────────────────────────
                    if (feature.choice != null)
                      DetailSection(title: 'Wahl', child: _buildChoice(context)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoice(BuildContext context) {
    final choice   = feature.choice!;
    final chosenId = choices[feature.id];

    if (chosenId != null) {
      final option = choice.options.firstWhere(
        (o) => o.id == chosenId,
        orElse: () => choice.options.first,
      );
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: themeColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: themeColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle_outline,
                    size: 16, color: themeColor),
                const SizedBox(width: 6),
                Text(option.name,
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            if (option.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(option.description,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: Colors.grey[600])),
            ],
          ],
        ),
      );
    }

    return _ChoiceSelector(
      choice:    choice,
      themeColor: themeColor,
      onConfirm: (optionId) async {
        await onChoiceMade(feature.id, optionId);
        if (context.mounted) Navigator.pop(context);
      },
    );
  }
}

// ── Wahl-Selektor (im Detail-Sheet, mit Bestätigung) ─────────────────────────

class _ChoiceSelector extends StatefulWidget {
  final ClassFeatureChoice choice;
  final Color themeColor;
  final Future<void> Function(String optionId) onConfirm;

  const _ChoiceSelector({
    required this.choice,
    required this.themeColor,
    required this.onConfirm,
  });

  @override
  State<_ChoiceSelector> createState() => _ChoiceSelectorState();
}

class _ChoiceSelectorState extends State<_ChoiceSelector> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.choice.prompt, style: AppTextStyles.cardTitle),
        const SizedBox(height: 8),
        ...widget.choice.options.map((opt) {
          final isSelected = _selected == opt.id;
          return GestureDetector(
            onTap: () => setState(() => _selected = opt.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? widget.themeColor.withValues(alpha: 0.08)
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? widget.themeColor
                      : Colors.grey[200]!,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    size: 18,
                    color: isSelected
                        ? widget.themeColor
                        : Colors.grey[400],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(opt.name,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? widget.themeColor
                                  : null,
                            )),
                        if (opt.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(opt.description,
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: Colors.grey[600])),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _selected == null
                ? null
                : () => widget.onConfirm(_selected!),
            style: FilledButton.styleFrom(
                backgroundColor: widget.themeColor),
            child: Text(
              _selected == null
                  ? 'Option auswählen'
                  : 'Auswahl bestätigen',
              style: AppTextStyles.body
                  .copyWith(color: const Color(0xFFF5DEB3)),
            ),
          ),
        ),
        if (_selected != null) ...[
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Diese Wahl kann nicht rückgängig gemacht werden.',
              style: AppTextStyles.labelXs.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Wahl-Dialog (wird noch vom character_sheet_screen.dart genutzt) ───────────

class _ChoiceDialog extends StatefulWidget {
  final ClassFeature feature;
  final Color themeColor;

  const _ChoiceDialog({
    required this.feature,
    required this.themeColor,
  });

  @override
  State<_ChoiceDialog> createState() => _ChoiceDialogState();
}

class _ChoiceDialogState extends State<_ChoiceDialog> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final choice = widget.feature.choice!;
    return AlertDialog(
      title: Text(choice.prompt, style: AppTextStyles.sectionTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: choice.options.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final opt      = choice.options[i];
            final selected = _selected == opt.id;
            return GestureDetector(
              onTap: () => setState(() => _selected = opt.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selected
                      ? widget.themeColor.withValues(alpha: 0.1)
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected ? widget.themeColor : Colors.grey[200]!,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          size: 18,
                          color: selected
                              ? widget.themeColor
                              : Colors.grey[400],
                        ),
                        const SizedBox(width: 8),
                        Text(opt.name,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.bold,
                              color: selected ? widget.themeColor : null,
                            )),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 26),
                      child: Text(opt.description,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: Colors.grey[600])),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Abbrechen', style: AppTextStyles.body),
        ),
        FilledButton(
          onPressed: _selected == null
              ? null
              : () => Navigator.pop(context, _selected),
          style: FilledButton.styleFrom(
              backgroundColor: widget.themeColor),
          child: Text('Bestätigen',
              style: AppTextStyles.body
                  .copyWith(color: const Color(0xFFF5DEB3))),
        ),
      ],
    );
  }
}