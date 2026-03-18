// lib/screens/character_sheet/character_sheet_screen.dart

import 'package:flutter/material.dart';
import 'package:dnd_app/models/character.dart';
import 'package:dnd_app/repositories/character_repository.dart';
import 'package:dnd_app/screens/character_sheet/tabs/overview_tab.dart';
import 'package:dnd_app/screens/character_sheet/tabs/skills_tab.dart';
import 'package:dnd_app/screens/character_sheet/tabs/inventory_tab.dart';
import 'package:dnd_app/screens/character_sheet/tabs/spell_tab.dart' show SpellTab, SpellTabState;
import 'package:dnd_app/screens/character_sheet/tabs/features_tab.dart';
import 'package:dnd_app/theme/app_text_styles.dart';
import 'package:dnd_app/models/spell_slot.dart';
import 'package:dnd_app/models/classes.dart';
import 'package:dnd_app/models/class_feature.dart';
import 'package:dnd_app/services/class_feature_service.dart';
import 'package:dnd_app/services/compendium_service.dart';

// ── Stufenaufstieg-Dialog ────────────────────────────────────────────────────

class _LevelUpResult {
  final String? newSubclass; // null = keine Unterklasse gewählt/erforderlich
  final int hpGain;
  const _LevelUpResult({this.newSubclass, required this.hpGain});
}

class _LevelUpDialog extends StatefulWidget {
  final int newLevel;          // Das Level auf das aufgestiegen wird
  final int hitDie;
  final int conModifier;
  final String characterClass;
  final String currentSubclass; // leer = noch keine
  final Color themeColor;

  const _LevelUpDialog({
    required this.newLevel,
    required this.hitDie,
    required this.conModifier,
    required this.characterClass,
    required this.currentSubclass,
    required this.themeColor,
  });

  @override
  State<_LevelUpDialog> createState() => _LevelUpDialogState();
}

class _LevelUpDialogState extends State<_LevelUpDialog> {
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

  /// Unterklasse ist bei diesem Level-Up neu wählbar wenn:
  /// - noch keine gewählt
  /// - und es Unterklassen gibt die genau bei diesem Level freischalten
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
          // ── HP-Gewinn ──────────────────────────────────────────────
          Text('Trefferpunkte', style: AppTextStyles.bodySmall
              .copyWith(color: Colors.grey[600])),
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
          // ── Unterklasse ────────────────────────────────────────────
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
              items: _availableSubs.map((s) => DropdownMenuItem(
                value: s.name,
                child: Text(s.name, style: AppTextStyles.body),
              )).toList(),
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
                  ? () => Navigator.pop(context, _LevelUpResult(
                        newSubclass: _selectedSubclass,
                        hpGain: _hpGain,
                      ))
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


// ── Trefferwürfel-Dialog ──────────────────────────────────────────────────────

class _HitDiceDialogResult {
  final int amount;
  const _HitDiceDialogResult(this.amount);
}

class _HitDiceDialog extends StatefulWidget {
  final int available;
  final int hitDie;
  final int conModifier;
  final Color themeColor;

  const _HitDiceDialog({
    required this.available,
    required this.hitDie,
    required this.conModifier,
    required this.themeColor,
  });

  @override
  State<_HitDiceDialog> createState() => _HitDiceDialogState();
}

class _HitDiceDialogState extends State<_HitDiceDialog> {
  int _amount = 1;

  @override
  Widget build(BuildContext context) {
    final conText = widget.conModifier >= 0
        ? '+${widget.conModifier}'
        : '${widget.conModifier}';

    return AlertDialog(
      title: Text(
        'Trefferwürfel ausgeben',
        style: AppTextStyles.sectionTitle,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.themeColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Verfügbar',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: Colors.grey)),
                Text(
                  '${widget.available} W${widget.hitDie}',
                  style: AppTextStyles.statMedium
                      .copyWith(color: widget.themeColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                color: widget.themeColor,
                onPressed: _amount > 1
                    ? () => setState(() => _amount--)
                    : null,
              ),
              Column(
                children: [
                  Text(
                    '$_amount',
                    style: AppTextStyles.statLarge
                        .copyWith(color: widget.themeColor),
                  ),
                  Text(
                    'Würfel',
                    style: AppTextStyles.labelXs
                        .copyWith(color: Colors.grey),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                color: widget.themeColor,
                onPressed: _amount < widget.available
                    ? () => setState(() => _amount++)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Pro Würfel: W${widget.hitDie} + KON ($conText)',
            style:
                AppTextStyles.bodySmall.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Abbrechen', style: AppTextStyles.body),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, _HitDiceDialogResult(_amount)),
          style: FilledButton.styleFrom(
              backgroundColor: widget.themeColor),
          child: Text('Ausgeben', style: AppTextStyles.body),
        ),
      ],
    );
  }
}

// ── Haupt-Screen ──────────────────────────────────────────────────────────────

class CharacterSheetScreen extends StatefulWidget {
  final String characterId;

  const CharacterSheetScreen({super.key, required this.characterId});

  @override
  State<CharacterSheetScreen> createState() =>
      _CharacterSheetScreenState();
}

class _CharacterSheetScreenState extends State<CharacterSheetScreen>
    with SingleTickerProviderStateMixin {
  final CharacterRepository _repository = CharacterRepository();

  Character? _character;
  bool _isLoading = true;
  bool _editMode = false;
  late TabController _tabController;
  final _featuresTabKey = GlobalKey<FeaturesTabState>();
  final _spellTabKey    = GlobalKey<SpellTabState>();

  Color get _themeColor => _character?.useEdition2024 == true
      ? const Color(0xFF1B4F72)
      : const Color(0xFF3B1F0A);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadCharacter();
  }

  // Features-Tab ist Index 3, Spell-Tab ist Index 4
  // Wenn man vom Features-Tab wegwechselt, SpellTab neu laden
  int _previousTabIndex = 0;
  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    if (_previousTabIndex == 3) {
      _spellTabKey.currentState?.reload();
    }
    _previousTabIndex = _tabController.index;
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCharacter() async {
    final character =
        await _repository.getCharacterById(widget.characterId);
    setState(() {
      _character = character;
      _isLoading = false;
    });
    if (_character != null) {
      await _syncClassSpells(_character!);
    }
  }

  /// Für prepared-Caster: trägt alle Klassenzauber bis zum verfügbaren
  /// Zaubergrad als bekannt (isPrepared=false) ein. Idempotent.
  Future<void> _syncClassSpells(Character c) async {
    final featureService  = ClassFeatureService();
    final compendium      = CompendiumService();
    await compendium.load();

    final features = await featureService.getFeaturesForCharacter(c);
    final hasPrepared = features.any((f) => f.spellcasting?.type == 'prepared');
    if (!hasPrepared) return;

    // Zauberbuch-Caster (Magier) verwalten ihre Zauber manuell
    final cls = characterClasses.where((cl) => cl.name == c.characterClass).firstOrNull;
    if (cls?.casterType == 'spellbook') return;

    if (c.spellSlots.isEmpty) return;
    final maxGrade = c.spellSlots.keys.reduce((a, b) => a > b ? a : b);

    final classSpells = compendium
        .searchSpells('', className: c.characterClass)
        .where((s) => s.level > 0 && s.level <= maxGrade)
        .toList();

    for (final spell in classSpells) {
      await _repository.upsertSpell(spell);
      await _repository.addSpellToCharacter(
        c.id,
        spell.id,
        isPrepared: false,
      );
    }
  }

  Future<void> _saveCharacter() async {
    if (_character == null) return;
    try {
      await _repository.updateCharacter(_character!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fehler beim Speichern'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    if (_character == null) {
      return Scaffold(
        appBar: AppBar(
            title: Text('Fehler', style: AppTextStyles.cardTitle)),
        body: Center(
          child: Text('Charakter nicht gefunden',
              style: AppTextStyles.body),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // ── AppBar als normales Widget ─────────────────────────────
          _buildAppBar(),
          // ── Tabs ──────────────────────────────────────────────────
          _buildTabBar(),
          // ── Tab-Inhalte mit fester Höhe ───────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                OverviewTab(
                  character: _character!,
                  themeColor: _themeColor,
                  editMode: _editMode,
                  onChanged: () => setState(() {}),
                  onSave: _saveCharacter,
                ),
                SkillsTab(
                  character: _character!,
                  themeColor: _themeColor,
                  editMode: _editMode,
                  onSave: _saveCharacter,
                ),
                InventoryTab(
                  character: _character!,
                  themeColor: _themeColor,
                ),
                FeaturesTab(
                  key: _featuresTabKey,
                  character: _character!,
                  themeColor: _themeColor,
                ),
                SpellTab(
                  key: _spellTabKey,
                  character: _character!,
                  themeColor: _themeColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      color: _themeColor,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFFF5DEB3)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: GestureDetector(
                onLongPress: _showIdentitySheet,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _buildFirstName(),
                      style: AppTextStyles.screenTitle.copyWith(
                          color: const Color(0xFFF5DEB3), fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    if (_buildLastName().isNotEmpty)
                      Text(
                        _buildLastName(),
                        style: AppTextStyles.screenTitle.copyWith(
                            color: const Color(0xFFF5DEB3), fontSize: 18),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),
            if (_character!.level < 20)
              _buildAppBarButton(
                  icon: Icons.arrow_circle_up_outlined,
                  onTap: _showLevelUpDialog),
            const SizedBox(width: 8),
            _buildAppBarButton(
                icon: Icons.bedtime, onTap: _showRestDialog),
            const SizedBox(width: 8),
            _buildAppBarButton(
              icon: _editMode ? Icons.edit_off : Icons.edit,
              onTap: () => setState(() => _editMode = !_editMode),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: _themeColor,
      child: TabBar(
        isScrollable: true,
        controller: _tabController,
        tabAlignment: TabAlignment.center,
        indicatorColor: const Color(0xFFF5DEB3),
        labelColor: const Color(0xFFF5DEB3),
        unselectedLabelColor:
            const Color(0xFFF5DEB3).withValues(alpha: 0.5),
        labelStyle: AppTextStyles.label,
        tabs: const [
          Tab(text: 'Übersicht'),
          Tab(text: 'Fertigkeiten'),
          Tab(text: 'Ausrüstung'),
          Tab(text: 'Features'),
          Tab(text: 'Zauber'),
        ],
      ),
    );
  }

  Widget _buildAppBarButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xFFF5DEB3).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Icon(icon, color: const Color(0xFFF5DEB3), size: 30),
      ),
    );
  }

  // ── Name splitten ────────────────────────────────────────────────────────

  String _buildFirstName() {
    final parts = _character!.name.trim().split(' ');
    return parts.first;
  }

  String _buildLastName() {
    final parts = _character!.name.trim().split(' ');
    if (parts.length <= 1) return '';
    return parts.skip(1).join(' ');
  }

  // ── Identitäts-Sheet ─────────────────────────────────────────────────────

  void _showIdentitySheet() {
    final c = _character!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _IdentitySheet(
        character:    c,
        themeColor:   _themeColor,
      ),
    );
  }

  Future<void> _showLevelUpDialog() async {
    final newLevel = _character!.level + 1;
    if (newLevel > 20) return;
    final result = await showDialog<_LevelUpResult>(
      context: context,
      builder: (_) => _LevelUpDialog(
        newLevel:        newLevel,
        hitDie:          _character!.hitDie,
        conModifier:     _character!.conModifier,
        characterClass:  _character!.characterClass,
        currentSubclass: _character!.subclass,
        themeColor:      _themeColor,
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _character!.level          = newLevel;
      _character!.maxHitPoints  += result.hpGain;
      _character!.currentHitPoints = (_character!.currentHitPoints + result.hpGain)
          .clamp(0, _character!.maxHitPoints);
      if (result.newSubclass != null) {
        _character!.subclass = result.newSubclass!;
      }
    });
    _updateSpellSlots();
    await _saveCharacter();
    await _syncClassSpells(_character!);

    // Neue Features laden und anzeigen
    if (!mounted) return;
    final featureService = ClassFeatureService();
    await featureService.loadForClass(_character!.characterClass);
    final allFeatures = await featureService.getFeaturesForCharacter(_character!);
    final newFeatures = allFeatures.where((f) => f.unlocksAtLevel == newLevel).toList();

    // FeaturesTab neu laden (syncGrantedSpells schreibt gewährte Zauber in DB)
    await _featuresTabKey.currentState?.reload();
    // Erst danach SpellTab laden, damit gewährte Zauber bereits in der DB sind
    await _spellTabKey.currentState?.reload();

    if (newFeatures.isNotEmpty && mounted) {
      await _showNewFeaturesDialog(newLevel, newFeatures);
    }
  }

  Future<void> _showNewFeaturesDialog(
      int level, List<ClassFeature> features) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        builder: (_, ctrl) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: _themeColor, size: 22),
                  const SizedBox(width: 10),
                  Text('Neu auf Stufe $level',
                      style: AppTextStyles.sectionTitle),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Folgende Features wurden freigeschaltet:',
                style: AppTextStyles.bodySmall
                    .copyWith(color: Colors.grey[500]),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  controller: ctrl,
                  itemCount: features.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final f = features[i];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _themeColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _themeColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(f.name,
                                    style: AppTextStyles.cardTitle),
                              ),
                              if (f.subclassName != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _themeColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('Unterklasse',
                                      style: AppTextStyles.labelXs
                                          .copyWith(color: _themeColor)),
                                ),
                            ],
                          ),
                          if (f.description.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              f.description.length > 200
                                  ? '${f.description.substring(0, 200)}…'
                                  : f.description,
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: Colors.grey[600]),
                            ),
                          ],
                          if (f.choice != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.touch_app_outlined,
                                    size: 14,
                                    color: Colors.orange[600]),
                                const SizedBox(width: 4),
                                Text(
                                  'Wahl erforderlich im Features-Tab',
                                  style: AppTextStyles.bodySmall.copyWith(
                                      color: Colors.orange[600]),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Direkt zum Features-Tab navigieren
                    _tabController.animateTo(3);
                  },
                  style: FilledButton.styleFrom(
                      backgroundColor: _themeColor),
                  child: Text('Zum Features-Tab',
                      style: AppTextStyles.body.copyWith(
                          color: const Color(0xFFF5DEB3))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _longRest() {
    setState(() {
      _character!.currentHitPoints = _character!.maxHitPoints;
      _character!.usedHitDice = (_character!.usedHitDice -
              (_character!.level / 2)
                  .floor()
                  .clamp(1, _character!.level))
          .clamp(0, _character!.level);
      _character!.temporaryHitPoints = 0;
      _character!.deathSaveSuccesses = 0;
      _character!.deathSaveFailures = 0;
      _character!.isStabilized = false;
      for (final slot in _character!.spellSlots.values) {
        slot.current = slot.max;
      }
    });
    // Feature-Ressourcen zurücksetzen (lange Rast)
    _featuresTabKey.currentState?.resetForRest('long');
  }

  Future<void> _showRestDialog() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rast einlegen', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 8),
            _buildRestOption(
              icon: Icons.coffee,
              title: 'Kurze Rast',
              description: 'Trefferwürfel können ausgegeben werden.',
              color: Colors.orange,
              onTap: () {
                Navigator.pop(context);
                _showUseHitDiceDialog();
                _featuresTabKey.currentState?.resetForRest('short');
              },
            ),
            const SizedBox(height: 12),
            _buildRestOption(
              icon: Icons.bedtime,
              title: 'Lange Rast',
              description:
                  'TP, Zauberplätze und die Hälfte der Trefferwürfel werden wiederhergestellt.',
              color: _themeColor,
              onTap: () {
                Navigator.pop(context);
                _longRest();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _showUseHitDiceDialog() async {
    final available = _character!.level - _character!.usedHitDice;
    final result = await showDialog<_HitDiceDialogResult>(
      context: context,
      builder: (_) => _HitDiceDialog(
        available: available,
        hitDie: _character!.hitDie,
        conModifier: _character!.conModifier,
        themeColor: _themeColor,
      ),
    );
    if (result != null) {
      setState(() => _character!.usedHitDice += result.amount);
      await _saveCharacter();
    }
  }

  Widget _buildRestOption({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          border:
              Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.cardTitle
                          .copyWith(color: color)),
                  const SizedBox(height: 2),
                  Text(description,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: Colors.grey[600])),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: color.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  void _updateSpellSlots() {
    final newSlots = calculateSpellSlots(
      _character!.characterClass,
      _character!.level,
    );

    if (newSlots.isEmpty) {
      _character!.spellSlots = {};
      return;
    }

    final updated = <int, SpellSlot>{};
    for (final entry in newSlots.entries) {
      final grade = entry.key;
      final newMax = entry.value.max;
      final existing = _character!.spellSlots[grade];

      if (existing == null) {
        updated[grade] = SpellSlot(max: newMax, current: newMax);
      } else {
        updated[grade] = SpellSlot(
          max: newMax,
          current: existing.current.clamp(0, newMax),
        );
      }
    }
    _character!.spellSlots = updated;
  }
}

// ── Hilfsklasse für Identity-Sheet ───────────────────────────────────────────

class _IdentityRow {
  final String label;
  final String value;
  const _IdentityRow({required this.label, required this.value});
}

// ── Identity-Sheet ────────────────────────────────────────────────────────────

class _IdentitySheet extends StatefulWidget {
  final Character character;
  final Color themeColor;

  const _IdentitySheet({
    required this.character,
    required this.themeColor,
  });

  @override
  State<_IdentitySheet> createState() => _IdentitySheetState();
}

class _IdentitySheetState extends State<_IdentitySheet> {
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
    if (mounted) setState(() {
      _classFluff    = classFluff;
      _subclassFluff = subclassFluff;
      _fluffLoaded   = true;
    });
  }

  Widget _buildFluffText(String text) {
    final baseStyle = AppTextStyles.body.copyWith(color: Colors.grey[700]);
    final boldStyle = baseStyle.copyWith(
      fontWeight: FontWeight.bold,
      color: Colors.grey[900],
    );
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

  @override
  Widget build(BuildContext context) {
    final c = widget.character;
    final rows = <_IdentityRow>[
      if (c.characterClass.isNotEmpty)
        _IdentityRow(
          label: 'Klasse',
          value: c.subclass.isNotEmpty
              ? '${c.characterClass} · ${c.subclass}'
              : c.characterClass,
        ),
      if (c.race.isNotEmpty)
        _IdentityRow(label: 'Rasse', value: c.race),
      if (c.alignment.isNotEmpty)
        _IdentityRow(label: 'Gesinnung', value: c.alignment),
      if (c.background.isNotEmpty)
        _IdentityRow(label: 'Hintergrund', value: c.background),
    ];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: (_classFluff != null || _subclassFluff != null) ? 0.6 : 0.4,
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
            // Griffleiste
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40, height: 4,
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
                    // Identitäts-Zeilen
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
                    // Fluff-Texte
                    if (!_fluffLoaded)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator(),
                      )
                    else ...[
                      if (_classFluff != null && _classFluff!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Divider(color: Colors.grey[200]),
                        const SizedBox(height: 12),
                        Text(
                          widget.character.characterClass,
                          style: AppTextStyles.cardTitle
                              .copyWith(color: widget.themeColor),
                        ),
                        const SizedBox(height: 8),
                        _buildFluffText(_classFluff!),
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
                        _buildFluffText(_subclassFluff!),
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