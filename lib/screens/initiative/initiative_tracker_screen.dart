// lib/screens/initiative/initiative_tracker_screen.dart

// ignore_for_file: unnecessary_underscores, prefer_final_fields

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dnd_app/models/character.dart';
import 'package:dnd_app/repositories/character_repository.dart';
import 'package:dnd_app/theme/app_text_styles.dart';

// ── Datenmodell ───────────────────────────────────────────────────────────────

class CombatParticipant {
  final String id;
  String name;
  int initiative;   // Endergebnis: Würfelwurf + INI-Bonus
  int? maxHp;
  int? currentHp;
  bool isPlayerCharacter;

  CombatParticipant({
    required this.id,
    required this.name,
    required this.initiative,
    this.maxHp,
    this.currentHp,
    this.isPlayerCharacter = false,
  });

  CombatParticipant copyWith({
    String? name,
    int? initiative,
    int? maxHp,
    int? currentHp,
  }) => CombatParticipant(
    id: id,
    name: name ?? this.name,
    initiative: initiative ?? this.initiative,
    maxHp: maxHp ?? this.maxHp,
    currentHp: currentHp ?? this.currentHp,
    isPlayerCharacter: isPlayerCharacter,
  );
}

// ── Hauptscreen ───────────────────────────────────────────────────────────────

class InitiativeTrackerScreen extends StatefulWidget {
  const InitiativeTrackerScreen({super.key});

  @override
  State<InitiativeTrackerScreen> createState() =>
      _InitiativeTrackerScreenState();
}

class _InitiativeTrackerScreenState extends State<InitiativeTrackerScreen> {
  static const _themeColor = Color(0xFF3B1F0A);
  static const _accent     = Color(0xFF8B0000);
  static const _cream      = Color(0xFFF5DEB3);

  List<Character> _pcList   = [];
  List<CombatParticipant> _participants = [];
  bool _combatStarted = false;
  int _round = 1;

  @override
  void initState() {
    super.initState();
    _loadCharacters();
  }

  Future<void> _loadCharacters() async {
    final repo = CharacterRepository();
    final chars = await repo.getAllCharacters();
    if (!mounted) return;
    setState(() => _pcList = chars);
  }

  // Sortierung: höchste Initiative zuerst, Gleichstand → alphabetisch
  void _sortParticipants() {
    _participants.sort((a, b) {
      final cmp = b.initiative.compareTo(a.initiative);
      return cmp != 0 ? cmp : a.name.compareTo(b.name);
    });
  }

  void _startCombat() {
    if (_participants.isEmpty) return;
    setState(() {
      _sortParticipants();
      _combatStarted = true;
      _round = 1;
    });
  }

  void _endTurn() {
    // Ersten Teilnehmer ans Ende schieben
    setState(() {
      final first = _participants.removeAt(0);
      _participants.add(first);
      // Wenn wir wieder beim ursprünglichen Anfang sind → neue Runde
      // Einfache Heuristik: Runde erhöhen wenn der erste Eintrag wieder
      // die höchste Initiative hat (sortierte Ordnung wiederhergestellt)
      if (_participants.first.initiative ==
          _participants.reduce((a, b) =>
              a.initiative >= b.initiative ? a : b).initiative) {
        _round++;
      }
    });
  }

  void _addParticipantDuringCombat(_AddParticipantResult result) {
    setState(() {
      _participants.add(result.participant);
      _sortParticipants();
    });
  }

  void _removeParticipant(CombatParticipant p) {
    setState(() => _participants.remove(p));
    if (_participants.isEmpty) {
      setState(() {
        _combatStarted = false;
        _round = 1;
      });
    }
  }

  void _resetCombat() {
    setState(() {
      _participants.clear();
      _combatStarted = false;
      _round = 1;
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5EF),
      appBar: AppBar(
        backgroundColor: _themeColor,
        foregroundColor: _cream,
        title: _combatStarted
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Kampf', style: AppTextStyles.cardTitle
                      .copyWith(color: _cream)),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Runde $_round',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: Colors.white),
                    ),
                  ),
                ],
              )
            : Text('Initiative', style: AppTextStyles.cardTitle
                .copyWith(color: _cream)),
        actions: [
          if (_combatStarted)
            IconButton(
              icon: const Icon(Icons.stop_circle_outlined),
              tooltip: 'Kampf beenden',
              onPressed: () => _showEndCombatDialog(),
            ),
          if (_combatStarted)
            IconButton(
              icon: const Icon(Icons.person_add_outlined),
              tooltip: 'Teilnehmer hinzufügen',
              onPressed: () => _showAddParticipantSheet(duringCombat: true),
            ),
          if (!_combatStarted && _participants.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Alle entfernen',
              onPressed: _resetCombat,
            ),
        ],
      ),
      body: _combatStarted ? _buildCombatView() : _buildSetupView(),
      floatingActionButton: _combatStarted
          ? null
          : FloatingActionButton.extended(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              onPressed: _participants.isEmpty ? null : _startCombat,
              icon: const Icon(Icons.sports_martial_arts),
              label: Text('Kampf beginnen', style: AppTextStyles.body
                  .copyWith(color: Colors.white)),
            ),
    );
  }

  // ── Setup-Ansicht ─────────────────────────────────────────────────────────

  Widget _buildSetupView() {
    return Column(
      children: [
        // Spielercharaktere als Chips zum schnellen Hinzufügen
        if (_pcList.isNotEmpty) _buildPcChips(),
        // Teilnehmerliste
        Expanded(
          child: _participants.isEmpty
              ? _buildEmptySetup()
              : _buildSetupList(),
        ),
        // Manuell hinzufügen
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
          child: OutlinedButton.icon(
            onPressed: () => _showAddParticipantSheet(duringCombat: false),
            icon: const Icon(Icons.add),
            label: Text('Manuell hinzufügen', style: AppTextStyles.body),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPcChips() {
    return Container(
      color: _themeColor.withValues(alpha: 0.05),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Text('Charaktere schnell hinzufügen',
              style: AppTextStyles.bodySmall
                  .copyWith(color: Colors.grey[600]))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _pcList.map((pc) {
              final alreadyAdded =
                  _participants.any((p) => p.id == pc.id);
              return FilterChip(
                label: Text(pc.name, style: AppTextStyles.bodySmall),
                selected: alreadyAdded,
                onSelected: alreadyAdded
                    ? null
                    : (_) => _showAddParticipantSheet(
                          duringCombat: false,
                          prefillCharacter: pc,
                        ),
                selectedColor: _themeColor.withValues(alpha: 0.2),
                checkmarkColor: _themeColor,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySetup() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Keine Teilnehmer',
              style: AppTextStyles.sectionTitle
                  .copyWith(color: Colors.grey[400])),
          const SizedBox(height: 8),
          Text(
            'Füge Charaktere oder Monster hinzu\num den Kampf zu beginnen.',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSetupList() {
    final sorted = [..._participants]
      ..sort((a, b) => b.initiative.compareTo(a.initiative));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      itemCount: sorted.length,
      itemBuilder: (_, i) => _buildSetupTile(sorted[i]),
    );
  }

  Widget _buildSetupTile(CombatParticipant p) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: p.isPlayerCharacter
              ? _themeColor.withValues(alpha: 0.15)
              : Colors.grey[200],
          child: Text(
            '${p.initiative}',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: p.isPlayerCharacter ? _themeColor : Colors.grey[700],
            ),
          ),
        ),
        title: Text(p.name, style: AppTextStyles.body),
        subtitle: p.maxHp != null
            ? Text('${p.maxHp} TP', style: AppTextStyles.bodySmall
                .copyWith(color: Colors.grey[500]))
            : null,
        trailing: IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: () => _removeParticipant(p),
        ),
      ),
    );
  }

  // ── Kampf-Ansicht ─────────────────────────────────────────────────────────

  Widget _buildCombatView() {
    if (_participants.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_outlined,
                size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Alle Teilnehmer entfernt',
                style: AppTextStyles.sectionTitle
                    .copyWith(color: Colors.grey[400])),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Aktiver Teilnehmer (oben prominent)
        _buildActiveCard(_participants.first),
        // Restliche Reihenfolge
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: _participants.length - 1,
            itemBuilder: (_, i) =>
                _buildQueueTile(_participants[i + 1], i + 1),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveCard(CombatParticipant p) {
    return GestureDetector(
      onTap: _endTurn,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _themeColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _themeColor.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _cream.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Jetzt am Zug',
                      style: AppTextStyles.labelXs
                          .copyWith(color: _cream.withValues(alpha: 0.8)),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'INI ${p.initiative}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(p.name,
                  style: AppTextStyles.screenTitle
                      .copyWith(color: _cream, fontSize: 22)),
              if (p.maxHp != null) ...[
                const SizedBox(height: 12),
                _buildHpBar(p, light: true),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // HP bearbeiten
                  if (p.maxHp != null)
                    Row(
                      children: [
                        _hpButton(p, delta: -1, icon: Icons.remove),
                        const SizedBox(width: 6),
                        _hpButton(p, delta: 1, icon: Icons.add),
                      ],
                    )
                  else
                    const SizedBox.shrink(),
                  // Zug beenden
                  FilledButton.icon(
                    onPressed: _endTurn,
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: Text('Zug beenden', style: AppTextStyles.body),
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQueueTile(CombatParticipant p, int position) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Position
            SizedBox(
              width: 28,
              child: Text(
                '$position.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: Colors.grey[400]),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 8),
            // INI-Badge
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                '${p.initiative}',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name + HP
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, style: AppTextStyles.body),
                  if (p.maxHp != null)
                    _buildHpBar(p, light: false),
                ],
              ),
            ),
            // HP-Buttons
            if (p.maxHp != null) ...[
              _hpButton(p, delta: -1, icon: Icons.remove, small: true),
              const SizedBox(width: 4),
              _hpButton(p, delta: 1, icon: Icons.add, small: true),
              const SizedBox(width: 4),
            ],
            // Entfernen
            GestureDetector(
              onLongPress: () => _confirmRemove(p),
              child: const Icon(Icons.more_vert,
                  size: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHpBar(CombatParticipant p, {required bool light}) {
    final hp    = p.currentHp ?? p.maxHp!;
    final max   = p.maxHp!;
    final ratio = (hp / max).clamp(0.0, 1.0);
    final color = ratio > 0.5
        ? Colors.green[400]!
        : ratio > 0.25
            ? Colors.orange[400]!
            : Colors.red[400]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 6,
                  backgroundColor: light
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$hp/$max',
              style: AppTextStyles.labelXs.copyWith(
                color: light
                    ? _cream.withValues(alpha: 0.7)
                    : Colors.grey[500],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _hpButton(
    CombatParticipant p, {
    required int delta,
    required IconData icon,
    bool small = false,
  }) {
    final size = small ? 28.0 : 34.0;
    return GestureDetector(
      onTap: () {
        final current = p.currentHp ?? p.maxHp!;
        final newHp = (current + delta).clamp(0, p.maxHp!);
        setState(() {
          final idx = _participants.indexOf(p);
          if (idx >= 0) {
            _participants[idx] = p.copyWith(currentHp: newHp);
          }
        });
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: delta < 0
              ? Colors.red.withValues(alpha: small ? 0.1 : 0.15)
              : Colors.green.withValues(alpha: small ? 0.1 : 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: small ? 14 : 18,
          color: delta < 0 ? Colors.red[400] : Colors.green[400],
        ),
      ),
    );
  }

  // ── Dialoge ───────────────────────────────────────────────────────────────

  Future<void> _showAddParticipantSheet({
    required bool duringCombat,
    Character? prefillCharacter,
  }) async {
    final result = await showModalBottomSheet<_AddParticipantResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _AddParticipantSheet(
        pcList: _pcList,
        prefillCharacter: prefillCharacter,
        themeColor: _themeColor,
        accentColor: _accent,
      ),
    );
    if (result == null || !mounted) return;
    if (duringCombat) {
      _addParticipantDuringCombat(result);
    } else {
      setState(() => _participants.add(result.participant));
    }
  }

  Future<void> _showEndCombatDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Kampf beenden?', style: AppTextStyles.sectionTitle),
        content: Text(
          'Die aktuelle Kampfreihenfolge wird gelöscht.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Abbrechen', style: AppTextStyles.body),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: _accent),
            child: Text('Beenden', style: AppTextStyles.body
                .copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) _resetCombat();
  }

  Future<void> _confirmRemove(CombatParticipant p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Entfernen?', style: AppTextStyles.sectionTitle),
        content: Text('${p.name} aus dem Kampf entfernen?',
            style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Abbrechen', style: AppTextStyles.body),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Entfernen', style: AppTextStyles.body),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) _removeParticipant(p);
  }
}

// ── Teilnehmer-Hinzufügen-Sheet ───────────────────────────────────────────────

class _AddParticipantResult {
  final CombatParticipant participant;
  const _AddParticipantResult(this.participant);
}

class _AddParticipantSheet extends StatefulWidget {
  final List<Character> pcList;
  final Character? prefillCharacter;
  final Color themeColor;
  final Color accentColor;

  const _AddParticipantSheet({
    required this.pcList,
    required this.prefillCharacter,
    required this.themeColor,
    required this.accentColor,
  });

  @override
  State<_AddParticipantSheet> createState() => _AddParticipantSheetState();
}

class _AddParticipantSheetState extends State<_AddParticipantSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _dexCtrl;
  late TextEditingController _bonusCtrl;
  late TextEditingController _rollCtrl;
  late TextEditingController _hpCtrl;

  @override
  void initState() {
    super.initState();
    final pc = widget.prefillCharacter;
    _nameCtrl  = TextEditingController(text: pc?.name ?? '');
    _dexCtrl   = TextEditingController(
        text: pc != null ? '${pc.dexterity}' : '');
    _bonusCtrl = TextEditingController(
        text: pc != null
            ? '${Character.modifier(pc.dexterity)}'
            : '');
    _rollCtrl  = TextEditingController();
    _hpCtrl    = TextEditingController(
        text: pc != null ? '${pc.maxHitPoints}' : '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dexCtrl.dispose();
    _bonusCtrl.dispose();
    _rollCtrl.dispose();
    _hpCtrl.dispose();
    super.dispose();
  }

  int get _initiative {
    final bonus = int.tryParse(_bonusCtrl.text) ?? 0;
    final roll  = int.tryParse(_rollCtrl.text) ?? 0;
    return bonus + roll;
  }

  void _onDexChanged(String val) {
    final dex = int.tryParse(val);
    if (dex != null) {
      _bonusCtrl.text = '${Character.modifier(dex)}';
    }
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final hp = int.tryParse(_hpCtrl.text);
    final p = CombatParticipant(
      id: '${DateTime.now().millisecondsSinceEpoch}_$name',
      name: name,
      initiative: _initiative,
      maxHp: hp,
      currentHp: hp,
      isPlayerCharacter: widget.prefillCharacter != null,
    );
    Navigator.pop(context, _AddParticipantResult(p));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Griffleiste
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Teilnehmer hinzufügen',
                  style: AppTextStyles.sectionTitle),
              const SizedBox(height: 16),
              // Name
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                style: AppTextStyles.body,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              // GES | INI-Bonus | Würfelwurf
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _dexCtrl,
                      onChanged: _onDexChanged,
                      decoration: const InputDecoration(
                        labelText: 'GES',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      style: AppTextStyles.body,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _bonusCtrl,
                      decoration: const InputDecoration(
                        labelText: 'INI-Bonus',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      style: AppTextStyles.body,
                      keyboardType: const TextInputType.numberWithOptions(
                          signed: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^-?\d*')),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _rollCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Würfelwurf',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      style: AppTextStyles.body,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // INI-Vorschau
              ValueListenableBuilder(
                valueListenable: _rollCtrl,
                builder: (_, __, ___) => ValueListenableBuilder(
                  valueListenable: _bonusCtrl,
                  builder: (_, __, ___) => Text(
                    'Initiative: $_initiative',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: widget.themeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // TP
              TextField(
                controller: _hpCtrl,
                decoration: const InputDecoration(
                  labelText: 'Max. Trefferpunkte (optional)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                style: AppTextStyles.body,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.accentColor,
                  ),
                  child: Text('Hinzufügen',
                      style: AppTextStyles.body
                          .copyWith(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}