import 'package:dnd_app/widgets/collapsible_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dnd_app/models/character.dart';
import 'package:dnd_app/theme/app_text_styles.dart';
import 'package:dnd_app/models/attributes.dart';

// ── Dialog-Widgets ────────────────────────────────────────────────────────────

class _NumberDialogResult {
  final int value;
  const _NumberDialogResult(this.value);
}

class _NumberDialog extends StatefulWidget {
  final String label;
  final int currentValue;
  final int min;
  final int max;
  final Color themeColor;

  const _NumberDialog({
    required this.label,
    required this.currentValue,
    required this.min,
    required this.max,
    required this.themeColor,
  });

  @override
  State<_NumberDialog> createState() => _NumberDialogState();
}

class _NumberDialogState extends State<_NumberDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.currentValue}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.label, style: AppTextStyles.sectionTitle),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: AppTextStyles.body,
        decoration: const InputDecoration(border: OutlineInputBorder()),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Abbrechen', style: AppTextStyles.body),
        ),
        FilledButton(
          onPressed: () {
            final value = int.tryParse(_controller.text);
            if (value != null &&
                value >= widget.min &&
                value <= widget.max) {
              Navigator.pop(context, _NumberDialogResult(value));
            }
          },
          style: FilledButton.styleFrom(
              backgroundColor: widget.themeColor),
          child: Text('Speichern', style: AppTextStyles.body),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _HpDialogResult {
  final int value;
  const _HpDialogResult(this.value);
}

class _HpDialog extends StatefulWidget {
  final int currentHp;
  final int maxHp;
  final Color themeColor;

  const _HpDialog({
    required this.currentHp,
    required this.maxHp,
    required this.themeColor,
  });

  @override
  State<_HpDialog> createState() => _HpDialogState();
}

class _HpDialogState extends State<_HpDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.currentHp}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          Text('Trefferpunkte setzen', style: AppTextStyles.sectionTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Maximum: ${widget.maxHp}', style: AppTextStyles.body),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTextStyles.body,
            decoration: const InputDecoration(
              labelText: 'Aktuelle TP',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Abbrechen', style: AppTextStyles.body),
        ),
        FilledButton(
          onPressed: () {
            final value = int.tryParse(_controller.text);
            if (value != null) {
              Navigator.pop(context, _HpDialogResult(value));
            }
          },
          style: FilledButton.styleFrom(
              backgroundColor: widget.themeColor),
          child: Text('Speichern', style: AppTextStyles.body),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DamageHealDialogResult {
  final int value;
  const _DamageHealDialogResult(this.value);
}

class _DamageHealDialog extends StatefulWidget {
  final bool isDamage;

  const _DamageHealDialog({required this.isDamage});

  @override
  State<_DamageHealDialog> createState() => _DamageHealDialogState();
}

class _DamageHealDialogState extends State<_DamageHealDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.isDamage ? 'Schaden erleiden' : 'Heilen',
        style: AppTextStyles.sectionTitle,
      ),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: AppTextStyles.body,
        decoration: InputDecoration(
          labelText:
              widget.isDamage ? 'Schadenspunkte' : 'Heilungspunkte',
          border: const OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Abbrechen', style: AppTextStyles.body),
        ),
        FilledButton(
          onPressed: () {
            final value = int.tryParse(_controller.text);
            if (value != null) {
              Navigator.pop(context, _DamageHealDialogResult(value));
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor:
                widget.isDamage ? Colors.red : Colors.green,
          ),
          child: Text('Bestätigen', style: AppTextStyles.body),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TempHpDialogResult {
  final int value;
  const _TempHpDialogResult(this.value);
}

class _TempHpDialog extends StatefulWidget {
  final int currentTempHp;

  const _TempHpDialog({required this.currentTempHp});

  @override
  State<_TempHpDialog> createState() => _TempHpDialogState();
}

class _TempHpDialogState extends State<_TempHpDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: '${widget.currentTempHp}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Temporäre TP', style: AppTextStyles.sectionTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Temporäre TP stapeln sich nicht – '
            'nur der höhere Wert zählt.',
            style:
                AppTextStyles.bodySmall.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTextStyles.body,
            decoration: const InputDecoration(
              labelText: 'Temporäre TP',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Abbrechen', style: AppTextStyles.body),
        ),
        FilledButton(
          onPressed: () {
            final value = int.tryParse(_controller.text);
            if (value != null) {
              Navigator.pop(context, _TempHpDialogResult(value));
            }
          },
          style:
              FilledButton.styleFrom(backgroundColor: Colors.blue),
          child: Text('Setzen', style: AppTextStyles.body),
        ),
      ],
    );
  }
}

// ── Bewegungs-Info-Dialog ─────────────────────────────────────────────────────

class _MovementInfoDialog extends StatelessWidget {
  final int speed;
  final int strength;
  final int strModifier;
  final Color themeColor;

  const _MovementInfoDialog({
    required this.speed,
    required this.strength,
    required this.strModifier,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    // ── Sprung (5e Regeln, Fuß → in m umgerechnet: 1 ft ≈ 0,3 m) ─────────
    final longJumpRun   = (strength * 0.3);          // STR ft mit Anlauf
    final longJumpStand = (longJumpRun * 0.5);    // STR/2 ft aus dem Stand
    final highJumpRun   = ((3 + strModifier) * 0.3).clamp(0, 999).toDouble();
    final highJumpStand = (highJumpRun * 0.5).toDouble();

    // ── Tragen/Heben (5e Regeln) ──────────────────────────────────────────
    // 1 lb ≈ 0,45 kg
    final carryLb  = strength * 15;
    final liftLb   = strength * 30;
    final carryKg  = (carryLb * 0.45).round();
    final liftKg   = (liftLb * 0.45).round();

    String fmt(double meters) {
      if (meters <= 0) return '0 m';
      final rounded = (meters * 2).round() / 2; // auf 0,5 m runden
      return rounded == rounded.roundToDouble()
          ? '${rounded.toInt()} m'
          : '${rounded.toStringAsFixed(1)} m';
    }

    return AlertDialog(
      title: Text('Bewegung & Kraft', style: AppTextStyles.sectionTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSection(
            icon: Icons.directions_run,
            label: 'Bewegungsrate',
            color: themeColor,
            rows: [
              ('Laufen', '$speed m'),
              ('Schleichen', '${(speed / 2).floor()} m'),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            icon: Icons.open_with,
            label: 'Springen (STR $strength)',
            color: Colors.blue,
            rows: [
              ('Weiter Sprung (Anlauf)', fmt(longJumpRun)),
              ('Weiter Sprung (Stand)',  fmt(longJumpStand)),
              ('Hoher Sprung (Anlauf)',  fmt(highJumpRun)),
              ('Hoher Sprung (Stand)',   fmt(highJumpStand)),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            icon: Icons.fitness_center,
            label: 'Tragen & Heben (STR $strength)',
            color: Colors.orange,
            rows: [
              ('Tragegrenze',              '$carryKg kg  ($carryLb lb)'),
              ('Bewegen','$liftKg kg  ($liftLb lb)'),
            ],
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          style: FilledButton.styleFrom(backgroundColor: themeColor),
          child: Text('OK', style: AppTextStyles.body),
        ),
      ],
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String label,
    required Color color,
    required List<(String, String)> rows,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(label,
                  style: AppTextStyles.bodySmall.copyWith(
                      color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(r.$1,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.grey[600])),
                    Text(r.$2,
                        style: AppTextStyles.bodySmall
                            .copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ── Haupt-Widget ──────────────────────────────────────────────────────────────

class OverviewTab extends StatefulWidget {
  final Character character;
  final Color themeColor;
  final bool editMode;
  final VoidCallback onChanged;
  final Future<void> Function() onSave;

  const OverviewTab({
    super.key,
    required this.character,
    required this.themeColor,
    required this.editMode,
    required this.onChanged,
    required this.onSave,
  });

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab>
    with AutomaticKeepAliveClientMixin {
  Character get c => widget.character;

  void _save() {
    widget.onChanged();
    widget.onSave();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCombatCard(),
        if (c.spellSlots.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSpellSlotsCard(),
        ],
        const SizedBox(height: 16),
        _buildHitDiceCard(),
      ],
    );
  }

  // ── Kampfwerte ──────────────────────────────────────────────────────────────

  Widget _buildCombatCard() {
    final isDying = c.currentHitPoints <= 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Allgemein',
              style: AppTextStyles.sectionTitle
                  .copyWith(color: widget.themeColor),
            ),
            const SizedBox(height: 16),
            _buildHpSection(),
            const Divider(height: 24),
            if (isDying)
              _buildDeathSavesSection()
            else ...[
              Row(
                children: [
                  _buildStatBox(
                    'RK',
                    '${c.armorClass}',
                    onTap: widget.editMode
                        ? () => _showNumberDialog(
                            'Rüstungsklasse', c.armorClass,
                            min: 1,
                            max: 30,
                            onSave: (v) =>
                                setState(() => c.armorClass = v))
                        : null,
                  ),
                  _buildStatBox(
                    'Initiative',
                    c.initiative >= 0
                        ? '+${c.initiative}'
                        : '${c.initiative}',
                  ),
                  _buildStatBox(
                    'Bewegung',
                    '${c.speed} m',
                    onTap: widget.editMode
                        ? () => _showNumberDialog(
                            'Bewegungsgeschwindigkeit', c.speed,
                            min: 0,
                            max: 99,
                            onSave: (v) => setState(() => c.speed = v))
                        : () => showDialog(
                            context: context,
                            builder: (_) => _MovementInfoDialog(
                              speed: c.speed,
                              strength: c.strength,
                              strModifier: c.strModifier,
                              themeColor: widget.themeColor,
                            )),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildStatBox('Übung', '+${c.proficiencyBonus}'),
                  _buildStatBox('Pass. Wahrn.', '${c.passivePerception}'),
                ],
              ),
              const Divider(height: 24),
              _buildAttributesContent(),
            ],
          ],
        ),
      ),
    );
  }

  // ── Trefferwürfel ───────────────────────────────────────────────────────────

  Widget _buildHitDiceCard() {
    return CollapsibleCard(
      title: 'Trefferwürfel',
      themeColor: widget.themeColor,
      child: _buildHitDiceSection(),
    );
  }

  Widget _buildHitDiceSection() {
    final available = c.level - c.usedHitDice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(c.level, (index) {
            final isUsed = index >= available;
            return Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isUsed
                    ? Colors.grey[300]
                    : widget.themeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isUsed
                      ? Colors.grey[400]!
                      : widget.themeColor,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  'W${c.hitDie}',
                  style: AppTextStyles.labelXs.copyWith(
                    color: isUsed
                        ? Colors.grey[400]
                        : widget.themeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          '$available / ${c.level} verfügbar',
          style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildHpSection() {
    final ratio =
        c.maxHitPoints > 0 ? c.currentHitPoints / c.maxHitPoints : 0.0;
    final hpColor = ratio > 0.5
        ? Colors.green
        : ratio > 0.25
            ? Colors.orange
            : Colors.red;
    final hasTemp = c.temporaryHitPoints > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Trefferpunkte', style: AppTextStyles.cardTitle),
            const Spacer(),
            GestureDetector(
              onTap: () => _showHpDialog(),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text:
                          '${c.currentHitPoints} / ${c.maxHitPoints}',
                      style: AppTextStyles.statLarge
                          .copyWith(color: hpColor),
                    ),
                    if (hasTemp)
                      TextSpan(
                        text: ' +${c.temporaryHitPoints}',
                        style: AppTextStyles.statMedium
                            .copyWith(color: Colors.blue),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(hpColor),
                minHeight: 8,
              ),
            ),
            if (hasTemp)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (c.temporaryHitPoints / c.maxHitPoints)
                      .clamp(0.0, 1.0),
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blue.withValues(alpha: 0.5)),
                  minHeight: 8,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildHpButton(
              label: 'Schaden',
              icon: Icons.remove,
              color: Colors.red,
              onTap: () => _showDamageHealDialog(isDamage: true),
            ),
            const SizedBox(width: 8),
            _buildHpButton(
              label: 'Heilung',
              icon: Icons.favorite,
              color: Colors.green,
              onTap: () => _showDamageHealDialog(isDamage: false),
            ),
            const SizedBox(width: 8),
            _buildHpButton(
              label: 'Temp. TP',
              icon: Icons.shield,
              color: Colors.blue,
              onTap: () => _showTempHpDialog(),
            ),
            if (widget.editMode) ...[
              const SizedBox(width: 8),
              _buildHpButton(
                label: 'Maximum',
                icon: Icons.settings,
                color: widget.themeColor,
                onTap: () => _showNumberDialog(
                  'Maximale Trefferpunkte',
                  c.maxHitPoints,
                  min: 1,
                  max: 9999,
                  onSave: (v) => setState(() => c.maxHitPoints = v),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildHpButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(height: 2),
              Text(label,
                  style: AppTextStyles.labelXs.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value,
      {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: widget.editMode && onTap != null
              ? BoxDecoration(
                  border: Border.all(
                      color: widget.themeColor.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: Column(
            children: [
              Text(value,
                  style: AppTextStyles.statLarge
                      .copyWith(color: widget.themeColor)),
              Text(label, style: AppTextStyles.labelXs),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeathSavesSection() {
    if (c.isStabilized) {
      return Column(
        children: [
          const SizedBox(height: 8),
          Icon(Icons.favorite, color: Colors.green[300], size: 32),
          const SizedBox(height: 8),
          Text('Stabilisiert',
              style: AppTextStyles.sectionTitle
                  .copyWith(color: Colors.green[400])),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Der Charakter ist bewusstlos aber stabil.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Text('Todesrettungswürfe',
            style: AppTextStyles.cardTitle,
            textAlign: TextAlign.center),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildDeathSaveGroup(
              label: 'Erfolge',
              count: c.deathSaveSuccesses,
              color: Colors.green,
              icon: Icons.check,
              onTap: (index, filled) {
                setState(() => c.deathSaveSuccesses =
                    filled ? index : index + 1);
                _save();
              },
            ),
            _buildDeathSaveGroup(
              label: 'Misserfolge',
              count: c.deathSaveFailures,
              color: Colors.red,
              icon: Icons.close,
              onTap: (index, filled) {
                setState(() => c.deathSaveFailures =
                    filled ? index : index + 1);
                _save();
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () {
            setState(() {
              c.isStabilized = true;
              c.deathSaveSuccesses = 0;
              c.deathSaveFailures = 0;
            });
            _save();
          },
          icon: const Icon(Icons.favorite, color: Colors.green),
          label: Text('Stabilisieren',
              style:
                  AppTextStyles.body.copyWith(color: Colors.green)),
        ),
      ],
    );
  }

  Widget _buildDeathSaveGroup({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
    required void Function(int index, bool filled) onTap,
  }) {
    return Column(
      children: [
        Text(label,
            style: AppTextStyles.bodySmall.copyWith(color: color)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(3, (index) {
            final filled = index < count;
            return GestureDetector(
              onTap: () => onTap(index, filled),
              child: Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? color : Colors.transparent,
                  border: Border.all(color: color, width: 2),
                ),
                child: filled
                    ? Icon(icon, size: 18, color: Colors.white)
                    : null,
              ),
            );
          }),
        ),
      ],
    );
  }

  // ── Zauberplätze ────────────────────────────────────────────────────────────

  Widget _buildSpellSlotsCard() {
    return CollapsibleCard(
      title: 'Zauberplätze',
      themeColor: widget.themeColor,
      child: _buildSpellSlotsContent(),
    );
  }

  Widget _buildSpellSlotsContent() {
    return Column(
      children: [
        const SizedBox(height: 16),
        ...c.spellSlots.entries.map((entry) {
          final grade = entry.key;
          final slot = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  child: Text('Grad $grade',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: Colors.grey[600])),
                ),
                Expanded(
                  child: Row(
                    children: List.generate(slot.max, (index) {
                      final filled = index < slot.current;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            slot.current =
                                filled ? index : index + 1;
                          });
                          _save();
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: filled
                                ? widget.themeColor
                                : Colors.transparent,
                            border: Border.all(
                              color: filled
                                  ? widget.themeColor
                                  : Colors.grey[400]!,
                              width: 2,
                            ),
                          ),
                          child: filled
                              ? const Icon(Icons.auto_awesome,
                                  size: 14, color: Colors.white)
                              : null,
                        ),
                      );
                    }),
                  ),
                ),
                Text('${slot.current}/${slot.max}',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: Colors.grey[500])),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Attribute ───────────────────────────────────────────────────────────────

  Widget _buildAttributeBox(
      String label, int score, int modifier, String key) {
    final modText = modifier >= 0 ? '+$modifier' : '$modifier';

    return Expanded(
      child: GestureDetector(
        onTap: widget.editMode
            ? () => _showNumberDialog(
                  Attributes.label(key),
                  score,
                  min: 1,
                  max: 30,
                  onSave: (v) =>
                      setState(() => _setAttributeValue(key, v)),
                )
            : null,
        child: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: widget.editMode
                  ? widget.themeColor.withValues(alpha: 0.4)
                  : Colors.grey[300]!,
              width: widget.editMode ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(label, style: AppTextStyles.label),
              const SizedBox(height: 4),
              Text(modText,
                  style: AppTextStyles.statLarge
                      .copyWith(color: widget.themeColor)),
              Text('$score', style: AppTextStyles.labelXs),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttributesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildAttributeBox(
                'STR', c.strength, c.strModifier, 'strength'),
            _buildAttributeBox(
                'GES', c.dexterity, c.dexModifier, 'dexterity'),
            _buildAttributeBox(
                'KON', c.constitution, c.conModifier, 'constitution'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildAttributeBox(
                'INT', c.intelligence, c.intModifier, 'intelligence'),
            _buildAttributeBox(
                'WEI', c.wisdom, c.wisModifier, 'wisdom'),
            _buildAttributeBox(
                'CHA', c.charisma, c.chaModifier, 'charisma'),
          ],
        ),
      ],
    );
  }

  void _setAttributeValue(String key, int value) {
    switch (key) {
      case 'strength':
        c.strength = value;
      case 'dexterity':
        c.dexterity = value;
      case 'constitution':
        c.constitution = value;
      case 'intelligence':
        c.intelligence = value;
      case 'wisdom':
        c.wisdom = value;
      case 'charisma':
        c.charisma = value;
    }
  }

  // ── Dialog-Aufrufe ──────────────────────────────────────────────────────────

  Future<void> _showHpDialog() async {
    final result = await showDialog<_HpDialogResult>(
      context: context,
      builder: (_) => _HpDialog(
        currentHp: c.currentHitPoints,
        maxHp: c.maxHitPoints,
        themeColor: widget.themeColor,
      ),
    );
    if (result != null) {
      setState(() => c.currentHitPoints = result.value);
      _save();
    }
  }

  Future<void> _showDamageHealDialog({required bool isDamage}) async {
    final result = await showDialog<_DamageHealDialogResult>(
      context: context,
      builder: (_) => _DamageHealDialog(isDamage: isDamage),
    );
    if (result != null) {
      setState(() {
        if (isDamage) {
          if (c.isStabilized) {
            c.isStabilized = false;
            c.deathSaveFailures = 1;
          }
          final tempReduction =
              result.value.clamp(0, c.temporaryHitPoints);
          c.temporaryHitPoints -= tempReduction;
          c.currentHitPoints -= (result.value - tempReduction);
        } else {
          c.currentHitPoints += result.value;
          c.isStabilized = false;
          c.deathSaveFailures = 0;
          c.deathSaveSuccesses = 0;
        }
      });
      _save();
    }
  }

  Future<void> _showTempHpDialog() async {
    final result = await showDialog<_TempHpDialogResult>(
      context: context,
      builder: (_) =>
          _TempHpDialog(currentTempHp: c.temporaryHitPoints),
    );
    if (result != null) {
      setState(() {
        c.temporaryHitPoints = result.value > c.temporaryHitPoints
            ? result.value
            : c.temporaryHitPoints;
      });
      _save();
    }
  }

  Future<void> _showNumberDialog(
    String label,
    int currentValue, {
    required int min,
    required int max,
    required void Function(int) onSave,
  }) async {
    final result = await showDialog<_NumberDialogResult>(
      context: context,
      builder: (_) => _NumberDialog(
        label: label,
        currentValue: currentValue,
        min: min,
        max: max,
        themeColor: widget.themeColor,
      ),
    );
    if (result != null) {
      onSave(result.value);
      _save();
    }
  }
}