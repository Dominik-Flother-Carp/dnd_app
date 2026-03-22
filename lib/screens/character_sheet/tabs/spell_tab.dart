// lib/screens/character_sheet/tabs/spell_tab.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dnd_app/models/character.dart';
import 'package:dnd_app/models/spell.dart';
import 'package:dnd_app/repositories/character_repository.dart' show CharacterRepository;
import 'package:dnd_app/services/compendium_service.dart';
import 'package:dnd_app/services/class_feature_service.dart';
import 'package:dnd_app/screens/compendium/compendium_detail_sheet.dart';
import 'package:dnd_app/theme/app_text_styles.dart';
import 'package:dnd_app/models/classes.dart';
import 'package:dnd_app/utils/format_utils.dart';
import 'package:dnd_app/widgets/widget_utils.dart';

// ── Vorbereitungslimit ─────────────────────────────────────────────────────────
//
// Formel nach 5e-Regeln:
// Full-Caster:    Zauberattribut-Modifier + Charakterlevel
// Half-Caster:    Zauberattribut-Modifier + floor(Charakterlevel / 2)
// Spellbook:      Zauberattribut-Modifier + Charakterlevel (Magier)
// Zaubertricks (Grad 0) zählen nie zum Limit.
// Nicht-Zauberer: kein Limit relevant.

int _calcPreparedLimit(Character c) {
  final cls = characterClasses
      .where((cl) => cl.name == c.characterClass)
      .firstOrNull;
  if (cls == null || cls.casterType == null || cls.casterType!.isEmpty) {
    return 0;
  }
  final attrMod = c.spellcastingModifier(cls.spellcastingAttribute);
  final effectiveLevel = cls.casterType == 'half'
      ? (c.level / 2).floor()
      : c.level;
  return (effectiveLevel + attrMod).clamp(1, 99).toInt();
}

// ── Kompendium-Picker (Zauber) ────────────────────────────────────────────────

class _SpellPickerSheet extends StatefulWidget {
  final Color themeColor;
  final String characterClass;
  final Set<String> alreadyAdded; // IDs aller bereits hinzugefügten Zauber
  final int maxSpellLevel;           // Höchster erlaubter Zaubergrad

  const _SpellPickerSheet({
    required this.themeColor,
    required this.characterClass,
    required this.alreadyAdded,
    required this.maxSpellLevel,
  });

  @override
  State<_SpellPickerSheet> createState() => _SpellPickerSheetState();
}

class _SpellPickerSheetState extends State<_SpellPickerSheet> {
  final _searchCtrl = TextEditingController();
  final _service    = CompendiumService();

  List<Spell> _results = [];
  bool _loading = true;

  // Debounce-Timer: verhindert Filterung bei jedem einzelnen Tastendruck
  Timer? _debounce;

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
      className: widget.characterClass.isEmpty ? null : widget.characterClass,
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
                  if (widget.characterClass.isNotEmpty)
                    Chip(
                      label: Text(widget.characterClass,
                          style: AppTextStyles.labelXs),
                      backgroundColor:
                          widget.themeColor.withValues(alpha: 0.12),
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                ],
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
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: _levelBadge(spell.level, widget.themeColor),
        title: Text(spell.name, style: AppTextStyles.cardTitle),
        subtitle: Text(
          [
            spell.school.label,
            if (spell.concentration) 'Konzentration',
            if (spell.ritual) 'Ritual',
          ].join(' · '),
          style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[500]),
        ),
        trailing: alreadyAdded
            ? Icon(Icons.check_circle,
                color: widget.themeColor, size: 22)
            : const Icon(Icons.add_circle_outline, size: 22),
        onTap: alreadyAdded ? null : () => Navigator.pop(context, spell),
      ),
    );
  }
}

// ── Hilfsfunktionen & Widgets ─────────────────────────────────────────────────

Widget _levelBadge(int level, Color color) {
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

// ── Zauber-Tab ────────────────────────────────────────────────────────────────

class SpellTab extends StatefulWidget {
  final Character character;
  final Color themeColor;

  const SpellTab({
    super.key,
    required this.character,
    required this.themeColor,
  });

  @override
  State<SpellTab> createState() => SpellTabState();
}

class SpellTabState extends State<SpellTab>
    with AutomaticKeepAliveClientMixin {
  final _repo           = CharacterRepository();
  final _featureService = ClassFeatureService();

  List<Spell> _spells = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // isPrepared is stored per-character, not on the Spell model itself.
  // We track it separately in a Set of prepared spell IDs.
  Set<String> _preparedSpellIds = {};

  /// IDs der immer vorbereiteten Zauber (grantedSpells) – zählen nicht zum Limit
  Set<String> _grantedSpellIds = {};

  // Gecacht – werden nur in _load() und _togglePrepared() neu berechnet
  List<MapEntry<int, List<Spell>>> _preparedGroupedEntries = [];
  List<Spell> _unpreparedCache = [];

  /// Wird vom character_sheet_screen aufgerufen wenn neue gewährte Zauber
  /// hinzugefügt wurden (z.B. nach Öffnen des Features-Tabs).
  Future<void> reload() => _load();

  Future<void> _load() async {
    final grantedIds = (await _featureService.getGrantedSpellIds(widget.character))
        .toSet();
    final rows = await _repo.getSpellsForCharacter(widget.character.id);
    if (!mounted) return;
    setState(() {
      _spells = rows
          .map((m) => Spell.fromMap(Map<String, dynamic>.from(m)))
          .toList();
      _preparedSpellIds = rows
          .where((m) {
            final v = m['isPrepared'];
            return v == 1 || v == true;
          })
          .map((m) => m['id'] as String)
          .toSet();
      _grantedSpellIds = grantedIds;
      _isLoading = false;
      _rebuildCaches();
    });
  }

  // ── Berechnungen ─────────────────────────────────────────────────────────

  CharacterClass? get _characterClass => characterClasses
      .where((c) => c.name == widget.character.characterClass)
      .firstOrNull;

  bool get _isSpellcaster {
    final ct = _characterClass?.casterType;
    return ct != null && ct.isNotEmpty;
  }

  int get _preparedLimit => _calcPreparedLimit(widget.character);

  /// Vorbereitete Zauber (Grad > 0), Zaubertricks und gewährte Zauber zählen nicht
  int get _preparedCount =>
      _spells.where((s) =>
          s.level > 0 &&
          _preparedSpellIds.contains(s.id) &&
          !_grantedSpellIds.contains(s.id)).length;



  bool _isPrepared(Spell s) =>
      s.level == 0 ||
      _grantedSpellIds.contains(s.id) ||
      _preparedSpellIds.contains(s.id);

  // ── Cache-Verwaltung ──────────────────────────────────────────────────────

  /// Berechnet beide Spell-Caches neu. Wird nach jedem _load() und nach
  /// _togglePrepared() aufgerufen – nie direkt im build().
  void _rebuildCaches() {
    // Vorbereitete Zauber nach Grad gruppiert
    final map = <int, List<Spell>>{};
    for (final s in _spells.where(_isPrepared)) {
      map.putIfAbsent(s.level, () => []).add(s);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.name.compareTo(b.name));
    }
    _preparedGroupedEntries = (map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key)));

    // Bekannte aber nicht vorbereitete Zauber
    _unpreparedCache = (_spells
        .where((s) =>
            s.level > 0 &&
            !_grantedSpellIds.contains(s.id) &&
            !_preparedSpellIds.contains(s.id))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name)));
  }

  // ── Zauber hinzufügen / entfernen ─────────────────────────────────────────

  Future<void> _showSpellPicker() async {
    // Maximal erlaubter Zaubergrad = höchster vorhandener Slot-Grad (mind. 0 für Zaubertricks)
    final maxLevel = widget.character.spellSlots.isEmpty
        ? 0
        : widget.character.spellSlots.keys.reduce((a, b) => a > b ? a : b);
    final spell = await showModalBottomSheet<Spell>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SpellPickerSheet(
        themeColor:      widget.themeColor,
        characterClass:  widget.character.characterClass,
        alreadyAdded: _spells.map((s) => s.id).toSet(),
        maxSpellLevel:   maxLevel,
      ),
    );
    if (spell == null || !mounted) return;
    // Zuerst Zauber in die spells-Tabelle schreiben (falls noch nicht vorhanden)
    await _repo.upsertSpell(spell);
    // Dann Charakter-Verknüpfung anlegen
    await _repo.addSpellToCharacter(
        widget.character.id, spell.id,
        isPrepared: false);
    await _load();
  }

  Future<void> _togglePrepared(Spell spell) async {
    if (spell.level == 0) return; // Zaubertricks sind immer "vorbereitet"
    if (_grantedSpellIds.contains(spell.id)) return; // gewährte Zauber sind immer vorbereitet
    final nowPrepared = !_preparedSpellIds.contains(spell.id);
    await _repo.setSpellPrepared(
        widget.character.id, spell.id, nowPrepared);
    setState(() {
      if (nowPrepared) {
        _preparedSpellIds.add(spell.id);
      } else {
        _preparedSpellIds.remove(spell.id);
      }
      _rebuildCaches();
    });
  }

  Future<void> _removeSpell(Spell spell) async {
    await _repo.removeSpellFromCharacter(widget.character.id, spell.id);
    await _load();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_isSpellcaster) return _buildNonCasterState();

    // Flache Zeilenliste aus gecachten Werten aufbauen – einmalig pro build()
    final rows = <Widget>[];
    if (_spells.isEmpty) {
      rows.add(_buildEmptySpells());
    } else {
      for (final entry in _preparedGroupedEntries) {
        rows.add(_buildLevelSection(entry.key, entry.value));
      }
      if (_unpreparedCache.isNotEmpty) {
        rows.add(_buildUnpreparedHeader());
        rows.addAll(_unpreparedCache.map(_buildSpellTile));
        rows.add(const SizedBox(height: 8));
      }
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: _buildSummaryCard(),
        ),
        Expanded(
          child: Stack(
            children: [
              CustomScrollView(
                primary: false,
                physics: const ClampingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => rows[i],
                        childCount: rows.length,
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  backgroundColor: widget.themeColor,
                  foregroundColor: const Color(0xFFF5DEB3),
                  onPressed: _showSpellPicker,
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNonCasterState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_fix_off_outlined,
              size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Kein Zauberwirker',
            style: AppTextStyles.sectionTitle
                .copyWith(color: Colors.grey[400]),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.character.characterClass} hat keine Zauberfähigkeiten.',
            style:
                AppTextStyles.bodySmall.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }



  Widget _buildUnpreparedHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 16, 2, 8),
      child: Row(
        children: [
          Icon(Icons.bookmark_border, size: 14, color: Colors.grey[400]),
          const SizedBox(width: 6),
          Text(
            'Bekannt · nicht vorbereitet',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.grey[400],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '(${_unpreparedCache.length})',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[300]),
          ),
        ],
      ),
    );
  }

  // ── Summary-Karte ─────────────────────────────────────────────────────────

  Widget _buildSummaryCard() {
    final cls       = _characterClass;
    final attr      = cls?.spellcastingAttribute ?? '';
    final attrMod   = widget.character.spellcastingModifier(attr);
    final attrLabel = widget.character.spellcastingAttrLabel(attr);
    final profBonus = widget.character.proficiencyBonus;
    final saveDC = attr.isNotEmpty ? 8 + profBonus + attrMod : 0;
    final attackBonus = attr.isNotEmpty ? profBonus + attrMod : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _summaryStat(
              label: 'SG',
              value: _isSpellcaster ? '$saveDC' : '—',
              icon: Icons.shield_outlined,
            ),
            _summaryStat(
              label: 'Angriff',
              value: _isSpellcaster
                  ? signedInt(attackBonus)
                  : '—',
              icon: Icons.bolt,
            ),
            _summaryStat(
              label: 'Attribut',
              value: _isSpellcaster ? attrLabel : '—',
              icon: Icons.psychology_outlined,
            ),
            _summaryStat(
              label: 'Vorbereitet',
              value: _isSpellcaster
                  ? '$_preparedCount / $_preparedLimit'
                  : '—',
              icon: Icons.checklist,
              color: _preparedCount > _preparedLimit
                  ? Colors.orange
                  : widget.themeColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryStat({
    required String label,
    required String value,
    required IconData icon,
    Color? color,
  }) {
    final c = color ?? widget.themeColor;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: c, size: 20),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.statMedium.copyWith(color: c)),
          Text(label, style: AppTextStyles.labelXs),
        ],
      ),
    );
  }

  // ── Leerer Zustand ────────────────────────────────────────────────────────

  Widget _buildEmptySpells() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 32),
        Icon(Icons.auto_fix_high_outlined,
            size: 64, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text(
          'Keine Zauber vorbereitet',
          style: AppTextStyles.sectionTitle
              .copyWith(color: Colors.grey[400]),
        ),
        const SizedBox(height: 8),
        Text(
          'Tippe auf + um Zauber hinzuzufügen.',
          style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── Grad-Abschnitt ────────────────────────────────────────────────────────

  Widget _buildLevelSection(int level, List<Spell> spells) {
    final label = level == 0 ? 'Zaubertricks' : 'Grad $level';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          child: Row(
            children: [
              _levelBadge(level, widget.themeColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${spells.length})',
                style: AppTextStyles.bodySmall
                    .copyWith(color: Colors.grey[400]),
              ),
            ],
          ),
        ),
        ...spells.map((s) => _buildSpellTile(s)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSpellTile(Spell spell) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showSpellDetailSheet(context, spell),
        onLongPress: () => _showSpellOptions(spell),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 44,
                decoration: BoxDecoration(
                  color: spell.concentration
                      ? Colors.purple[200]
                      : widget.themeColor.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(spell.name, style: AppTextStyles.cardTitle),
                        if (spell.ritual)
                          AppBadge(label: 'Ritual', color: Colors.teal),
                        if (spell.concentration)
                          AppBadge(label: 'Konzentration', color: Colors.purple),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _spellSubtitle(spell),
                      style: AppTextStyles.bodySmall
                          .copyWith(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  size: 18, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  String _spellSubtitle(Spell spell) {
    final parts = <String>[];
    parts.add(spell.school.label);
    parts.add(spell.castingTime);
    if (spell.dealsDamage) {
      parts.add('${spell.damageDice} ${spell.damageType}');
    }
    return parts.join(' · ');
  }

  Future<void> _showSpellOptions(Spell spell) async {
    final isPrepared  = _isPrepared(spell);
    final isGranted   = _grantedSpellIds.contains(spell.id);
    await showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text('Details', style: AppTextStyles.body),
              onTap: () {
                Navigator.pop(context);
                showSpellDetailSheet(context, spell);
              },
            ),
            if (spell.level > 0 && !isGranted)
              ListTile(
                leading: Icon(
                  isPrepared ? Icons.bookmark_remove : Icons.bookmark_add_outlined,
                  color: widget.themeColor,
                ),
                title: Text(
                  isPrepared ? 'Nicht mehr vorbereiten' : 'Vorbereiten',
                  style: AppTextStyles.body,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _togglePrepared(spell);
                },
              ),
            if (!isGranted)
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(
                  'Zauber entfernen',
                  style: AppTextStyles.body.copyWith(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _removeSpell(spell);
                },
              ),
            if (isGranted)
              ListTile(
                leading: Icon(Icons.lock_outline, color: Colors.grey[400]),
                title: Text(
                  'Gewährter Zauber – immer vorbereitet',
                  style: AppTextStyles.body.copyWith(color: Colors.grey[500]),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}