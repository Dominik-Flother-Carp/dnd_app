// lib/screens/character_sheet/tabs/features_tab.dart

import 'package:flutter/material.dart';
import 'package:dnd_app/models/character.dart';
import 'package:dnd_app/models/class_feature.dart';
import 'package:dnd_app/repositories/character_repository.dart';
import 'package:dnd_app/services/class_feature_service.dart';
import 'package:dnd_app/services/compendium_service.dart';
import 'package:dnd_app/theme/app_text_styles.dart';

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

  List<ClassFeature> _features   = [];
  Map<String, int>    _uses      = {}; // featureId → verbrauchte Nutzungen
  Map<String, String> _choices   = {}; // featureId → gewählte optionId
  Map<String, String> _spellNames = {}; // spellId → Zaubername
  bool _isLoading = true;


  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Wird vom character_sheet_screen aufgerufen nach Levelup.
  Future<void> reload() => _load();

  Future<void> _load() async {
    await _compendium.load();
    final features = await _service.getFeaturesForCharacter(widget.character);
    final uses     = await _repo.getFeatureUses(widget.character.id);
    final choices  = await _repo.getAllFeatureChoices(widget.character.id);

    // Zaubernamen für grantedSpells auflösen
    final spellNames = <String, String>{};
    for (final f in features) {
      for (final gs in f.grantedSpells ?? []) {
        final spell = _compendium.getSpellById(gs.spellId);
        spellNames[gs.spellId] = spell?.name ?? gs.spellId;
      }
    }

    // Gewährte Zauber automatisch zum Charakter hinzufügen (idempotent)
    await _syncGrantedSpells(features);

    if (!mounted) return;
    setState(() {
      _features   = features;
      _uses       = uses;
      _choices    = choices;
      _spellNames = spellNames;
      _isLoading = false;
    });
  }

  /// Fügt alle fälligen grantedSpells automatisch zum Charakter hinzu.
  /// isPrepared=true da Domänenzauber immer vorbereitet sind.
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

  int _maxUses(ClassFeature f) =>
      f.resource!.evaluate(widget.character);

  int _remaining(ClassFeature f) =>
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

  /// Wird vom character_sheet_screen aus aufgerufen wenn eine Rast gemacht wird.
  Future<void> resetForRest(String restType) async {
    // 'short': nur Features mit restType == 'short' zurücksetzen
    // 'long':  alle Features zurücksetzen (lange Rast schließt kurze ein)
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

  // ── Wahl-Logik ─────────────────────────────────────────────────────────────

  Future<void> _showChoiceDialog(ClassFeature f) async {
    final chosen = await showDialog<String>(
      context: context,
      builder: (_) => _ChoiceDialog(
        feature:    f,
        themeColor: widget.themeColor,
      ),
    );
    if (chosen == null || !mounted) return;
    await _repo.setFeatureChoice(widget.character.id, f.id, chosen);
    setState(() => _choices[f.id] = chosen);
  }

  // ── Gruppierung nach Level ─────────────────────────────────────────────────

  Map<int, List<ClassFeature>> get _grouped {
    final map = <int, List<ClassFeature>>{};
    for (final f in _features) {
      // Features mit extends werden im Basis-Feature angezeigt, nicht separat
      if (f.extendsFeatureId != null) continue;
      map.putIfAbsent(f.unlocksAtLevel, () => []).add(f);
    }
    return Map.fromEntries(
      map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
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
            Text(
              'Keine Features',
              style: AppTextStyles.sectionTitle
                  .copyWith(color: Colors.grey[400]),
            ),
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
        // ── Fixe Summary ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: _buildSummaryCard(),
        ),
        // ── Scrollbarer Inhalt ───────────────────────────────────────────────
        Expanded(
          child: CustomScrollView(
            primary: false,
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    for (final entry in _grouped.entries) ...[
                      _buildLevelHeader(entry.key),
                      ...entry.value.map(_buildFeatureCard),
                      const SizedBox(height: 8),
                    ],
                  ]),
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
    final c       = widget.character;
    final hasRes  = _features.any((f) => f.resource != null);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Klasse + Unterklasse
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.characterClass,
                      style: AppTextStyles.cardTitle),
                  if (c.subclass.isNotEmpty)
                    Text(c.subclass,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.grey[500])),
                ],
              ),
            ),
            // Feature-Anzahl
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

  // ── Feature-Karte ──────────────────────────────────────────────────────────

  Widget _buildFeatureCard(ClassFeature f) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding:
              const EdgeInsets.fromLTRB(14, 0, 14, 12),
          title: Row(
            children: [
              Expanded(
                child: Text(f.name, style: AppTextStyles.cardTitle),
              ),
              // Unterklassen-Chip
              if (f.subclassName != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.themeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Unterklasse',
                    style: AppTextStyles.labelXs
                        .copyWith(color: widget.themeColor),
                  ),
                ),
              ],
            ],
          ),
          subtitle: _buildSubtitle(f),
          children: [
            // Beschreibung
            _buildDescription(f.description),

            // Ressource
            if (f.resource != null) ...[
              const SizedBox(height: 12),
              _buildResourceRow(f),
            ],

            // Wahl
            if (f.choice != null) ...[
              const SizedBox(height: 12),
              _buildChoiceRow(f),
            ],

            // Erweiterungen (z.B. Domänen-Kanal)
            if (f.extensions.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...f.extensions.map(_buildExtensionTile),
            ],

            // Gewährte Zauber
            if (f.grantedSpells != null && f.grantedSpells!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildGrantedSpells(f),
            ],
          ],
        ),
      ),
    );
  }

  Widget? _buildSubtitle(ClassFeature f) {
    // Ressource: verbleibende Nutzungen als Subtitle
    if (f.resource != null) {
      final remaining = _remaining(f);
      final max       = _maxUses(f);
      final color = remaining > 0 ? widget.themeColor : Colors.red[300]!;
      return Text(
        '${f.resource!.label}: $remaining / $max',
        style: AppTextStyles.bodySmall.copyWith(color: color),
      );
    }
    // Wahl: gewählte Option als Subtitle
    if (f.choice != null) {
      final chosenId = _choices[f.id];
      if (chosenId != null) {
        final option = f.choice!.options
            .firstWhere((o) => o.id == chosenId,
                orElse: () => f.choice!.options.first);
        return Text(
          option.name,
          style: AppTextStyles.bodySmall
              .copyWith(color: Colors.grey[500]),
        );
      }
      return Text(
        'Noch keine Wahl getroffen',
        style: AppTextStyles.bodySmall
            .copyWith(color: Colors.orange[400]),
      );
    }
    return null;
  }

  // ── Ressource-Zeile ────────────────────────────────────────────────────────

  Widget _buildResourceRow(ClassFeature f) {
    final remaining = _remaining(f);
    final max       = _maxUses(f);
    final isPool    = f.resource!.label == 'Pool';

    return Row(
      children: [
        // Rast-Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: f.resource!.restType == 'short'
                ? Colors.blue.withValues(alpha: 0.1)
                : Colors.purple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            f.resource!.restType == 'short' ? 'K. Rast' : 'L. Rast',
            style: AppTextStyles.labelXs.copyWith(
              color: f.resource!.restType == 'short'
                  ? Colors.blue[600]
                  : Colors.purple[600],
            ),
          ),
        ),
        const SizedBox(width: 12),
        if (isPool) ...[
          // Pool: numerischer Zähler mit +/− Buttons
          _hpStyleButton(Icons.remove, () => _spend(f),
              active: remaining > 0),
          const SizedBox(width: 8),
          Text('$remaining / $max', style: AppTextStyles.body),
          const SizedBox(width: 8),
          _hpStyleButton(Icons.add, () => _restore(f),
              active: remaining < max),
        ] else ...[
          // Nutzungen: Kreise
          ...List.generate(max, (i) {
            final used = i >= remaining;
            return GestureDetector(
              onTap: used ? () => _restore(f) : () => _spend(f),
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape:       BoxShape.circle,
                  color:       used
                      ? Colors.grey[200]
                      : widget.themeColor.withValues(alpha: 0.15),
                  border:      Border.all(
                    color: used
                        ? Colors.grey[300]!
                        : widget.themeColor,
                    width: 1.5,
                  ),
                ),
                child: used
                    ? null
                    : Icon(Icons.circle,
                        size: 10, color: widget.themeColor),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _hpStyleButton(IconData icon, VoidCallback onTap,
      {required bool active}) {
    return GestureDetector(
      onTap: active ? onTap : null,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: active
              ? widget.themeColor.withValues(alpha: 0.12)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 16,
          color: active ? widget.themeColor : Colors.grey[300],
        ),
      ),
    );
  }

  // ── Wahl-Zeile ─────────────────────────────────────────────────────────────

  Widget _buildChoiceRow(ClassFeature f) {
    final chosenId = _choices[f.id];
    if (chosenId != null) {
      final option = f.choice!.options
          .firstWhere((o) => o.id == chosenId,
              orElse: () => f.choice!.options.first);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline,
                  size: 16, color: widget.themeColor),
              const SizedBox(width: 6),
              Text(option.name,
                  style: AppTextStyles.body
                      .copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          _buildDescription(option.description),
        ],
      );
    }
    return OutlinedButton.icon(
      onPressed: () => _showChoiceDialog(f),
      icon: const Icon(Icons.touch_app_outlined, size: 16),
      label: Text(f.choice!.prompt, style: AppTextStyles.bodySmall),
    );
  }

  // ── Erweiterungs-Kachel ────────────────────────────────────────────────────

  Widget _buildExtensionTile(ClassFeature ext) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: widget.themeColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: widget.themeColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.add_circle_outline,
                  size: 14, color: widget.themeColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(ext.name,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: widget.themeColor,
                    )),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: widget.themeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('Domäne',
                    style: AppTextStyles.labelXs
                        .copyWith(color: widget.themeColor)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _buildDescription(ext.description),
        ],
      ),
    );
  }

  // ── Gewährte Zauber ────────────────────────────────────────────────────────

  /// Rendert einen Text mit **fett**-Unterstützung.
  /// Text zwischen ** wird fett dargestellt.
  Widget _buildDescription(String text, {Color? color}) {
    final baseColor = color ?? Colors.grey[600]!;
    final baseStyle = AppTextStyles.bodySmall.copyWith(color: baseColor);
    final boldStyle = baseStyle.copyWith(
      fontWeight: FontWeight.bold,
      color: Colors.grey[800],
    );

    // Text in Segmente aufteilen: normaler Text und **fetter Text**
    final spans = <TextSpan>[];
    final re = RegExp(r'\*\*(.+?)\*\*');
    int last = 0;
    for (final match in re.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(text: text.substring(last, match.start)));
      }
      spans.add(TextSpan(text: match.group(1), style: boldStyle));
      last = match.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }

    return RichText(
      text: TextSpan(style: baseStyle, children: spans),
    );
  }

  Widget _buildGrantedSpells(ClassFeature f) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gewährte Zauber',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.grey[500],
              fontWeight: FontWeight.bold,
            )),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: f.grantedSpells!.map((gs) {
            final available = gs.atLevel <= widget.character.level;
            final name = _spellNames[gs.spellId] ?? gs.spellId;
            return Chip(
              label: Text(
                name,
                style: AppTextStyles.labelXs.copyWith(
                  color: available
                      ? widget.themeColor
                      : Colors.grey[400],
                ),
              ),
              backgroundColor: available
                  ? widget.themeColor.withValues(alpha: 0.08)
                  : Colors.grey[100],
              side: BorderSide(
                color: available
                    ? widget.themeColor.withValues(alpha: 0.3)
                    : Colors.grey[300]!,
              ),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Wahl-Dialog ───────────────────────────────────────────────────────────────

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
                    color: selected
                        ? widget.themeColor
                        : Colors.grey[200]!,
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
                              color: selected
                                  ? widget.themeColor
                                  : null,
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