// lib/screens/character_sheet/character_sheet_screen.dart

import 'package:flutter/material.dart';
import 'package:dnd_app/models/character.dart';
import 'package:dnd_app/repositories/character_repository.dart';
import 'package:dnd_app/screens/character_sheet/tabs/overview_tab.dart';
import 'package:dnd_app/screens/character_sheet/tabs/skills_tab.dart';
import 'package:dnd_app/screens/character_sheet/tabs/inventory_tab.dart';
import 'package:dnd_app/theme/app_text_styles.dart';
import 'package:dnd_app/models/spell_slot.dart';
import 'package:dnd_app/models/classes.dart';

// ── Level-Dialog ──────────────────────────────────────────────────────────────

class _LevelDialogResult {
  final int level;
  const _LevelDialogResult(this.level);
}

class _LevelDialog extends StatefulWidget {
  final int currentLevel;
  final Color themeColor;

  const _LevelDialog({
    required this.currentLevel,
    required this.themeColor,
  });

  @override
  State<_LevelDialog> createState() => _LevelDialogState();
}

class _LevelDialogState extends State<_LevelDialog> {
  late int _level;

  @override
  void initState() {
    super.initState();
    _level = widget.currentLevel;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Stufe ändern', style: AppTextStyles.sectionTitle),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            color: widget.themeColor,
            onPressed: _level > 1
                ? () => setState(() => _level--)
                : null,
          ),
          Text(
            '$_level',
            style: AppTextStyles.statLarge
                .copyWith(color: widget.themeColor),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            color: widget.themeColor,
            onPressed: _level < 20
                ? () => setState(() => _level++)
                : null,
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, _LevelDialogResult(_level)),
          style: FilledButton.styleFrom(
              backgroundColor: widget.themeColor),
          child: Text('Fertig', style: AppTextStyles.body),
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

  Color get _themeColor => _character?.useEdition2024 == true
      ? const Color(0xFF1B4F72)
      : const Color(0xFF3B1F0A);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCharacter();
  }

  @override
  void dispose() {
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
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(innerBoxIsScrolled),
        ],
        body: TabBarView(
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
            _buildComingSoon('Zauber & Fähigkeiten'),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 150,
      pinned: true,
      backgroundColor: _themeColor,
      foregroundColor: const Color(0xFFF5DEB3),
      actions: [
        _buildAppBarButton(
            icon: Icons.bedtime, onTap: _showRestDialog),
        const SizedBox(width: 8),
        _buildAppBarButton(
          icon: _editMode ? Icons.edit_off : Icons.edit,
          onTap: () => setState(() => _editMode = !_editMode),
        ),
        const SizedBox(width: 12),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _buildHeader(),
        collapseMode: CollapseMode.pin,
      ),
      bottom: TabBar(
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

  Widget _buildHeader() {
    final character = _character!;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        color: _themeColor,
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              character.name,
              style: AppTextStyles.screenTitle
                  .copyWith(color: const Color(0xFFF5DEB3)),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: _editMode ? () => _showLevelDialog() : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      _buildSubtitle(),
                      style: AppTextStyles.body.copyWith(
                        color: const Color(0xFFF5DEB3)
                            .withValues(alpha: 0.8),
                      ),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (_editMode) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.edit,
                      size: 14,
                      color: const Color(0xFFF5DEB3)
                          .withValues(alpha: 0.7),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildSubtitle() {
    final c = _character!;
    final parts = <String>[];
    if (c.characterClass.isNotEmpty) {
      final classEntry = c.subclass.isNotEmpty
          ? '${c.characterClass} (${c.subclass})'
          : c.characterClass;
      parts.add(classEntry);
    }
    if (c.race.isNotEmpty) parts.add(c.race);
    parts.add('Stufe ${c.level}');
    return parts.join(' · ');
  }

  Widget _buildComingSoon(String label) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            '$label ist in Arbeit!',
            style:
                AppTextStyles.body.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Future<void> _showLevelDialog() async {
    final result = await showDialog<_LevelDialogResult>(
      context: context,
      builder: (_) => _LevelDialog(
        currentLevel: _character!.level,
        themeColor: _themeColor,
      ),
    );
    if (result != null) {
      setState(() => _character!.level = result.level);
      _updateSpellSlots();
      await _saveCharacter();
    }
  }

  void longRest() {
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
                longRest();
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