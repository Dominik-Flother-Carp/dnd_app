import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dnd_app/models/character.dart';
import 'package:dnd_app/theme/app_text_styles.dart';
import 'package:dnd_app/models/attributes.dart';

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

class _OverviewTabState extends State<OverviewTab> {
  Character get c => widget.character;

  void _save() {
    widget.onChanged();
    widget.onSave();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCombatCard(),
        const SizedBox(height: 16),
        _buildAttributesCard(),
        const SizedBox(height: 16),
        _buildCurrencyCard(),
      ],
    );
  }

  // ── Kampfwerte ─────────────────────────────────────────────────────────────

  Widget _buildCombatCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kampfwerte',
              style: AppTextStyles.sectionTitle.copyWith(
                color: widget.themeColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildHpSection(),
            const Divider(height: 24),
            Row(
              children: [
                _buildStatBox(
                  'RK',
                  '${c.armorClass}',
                  onTap: widget.editMode
                      ? () => _showNumberDialog(
                            'Rüstungsklasse',
                            c.armorClass,
                            min: 1,
                            max: 30,
                            onSave: (v) => setState(() => c.armorClass = v),
                          )
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
                            'Bewegungsgeschwindigkeit',
                            c.speed,
                            min: 0,
                            max: 99,
                            onSave: (v) => setState(() => c.speed = v),
                          )
                      : null,
                ),
                _buildStatBox('Übung', '+${c.proficiencyBonus}'),
              ],
            ),
            const Divider(height: 24),
            _buildHitDiceSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHitDiceSection() {
  final available = c.level - c.usedHitDice;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text('Trefferwürfel', style: AppTextStyles.cardTitle),
          const Spacer(),
          Text(
            'W${c.hitDie}',
            style: AppTextStyles.statMedium.copyWith(
              color: widget.themeColor,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      // Würfel-Anzeige
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
      // Buttons
      Row(
        children: [
          Text(
            '$available / ${c.level} verfügbar',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
          ),
          const Spacer(),
          const SizedBox(width: 8),
          _buildHpButton(
            label: 'Ausgeben',
            icon: Icons.remove_circle_outline,
            color: available > 0 ? widget.themeColor : Colors.grey,
            onTap: available > 0
                ? () => _showUseHitDiceDialog()
                : () {},
          ),
        ],
      ),
    ],
  );
}

  Widget _buildHpSection() {
    final ratio = c.maxHitPoints > 0
        ? c.currentHitPoints / c.maxHitPoints
        : 0.0;

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
            // Aktuelle TP bearbeiten
            GestureDetector(
              onTap: () => _showHpDialog(),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${c.currentHitPoints} / ${c.maxHitPoints}',
                      style: AppTextStyles.statLarge.copyWith(color: hpColor),
                    ),
                    if (hasTemp)
                      TextSpan(
                        text: ' +${c.temporaryHitPoints}',
                        style: AppTextStyles.statMedium.copyWith(
                          color: Colors.blue,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // HP-Balken
        Stack(
          children: [
            // Basis-Balken
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(hpColor),
                minHeight: 8,
              ),
            ),
            // Temporäre TP als blauer Overlay
            if (hasTemp)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (c.temporaryHitPoints / c.maxHitPoints)
                      .clamp(0.0, 1.0),
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.blue.withValues(alpha:0.5),
                  ),
                  minHeight: 8,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Buttons für TP-Verwaltung
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
            color: color.withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha:0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTextStyles.labelXs.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: widget.editMode && onTap != null
              ? BoxDecoration(
                  border: Border.all(
                    color: widget.themeColor.withValues(alpha:0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: Column(
            children: [
              Text(
                value,
                style: AppTextStyles.statLarge.copyWith(
                  color: widget.themeColor,
                ),
              ),
              Text(label, style: AppTextStyles.labelXs),
            ],
          ),
        ),
      ),
    );
  }

  // ── Attribute ──────────────────────────────────────────────────────────────

  Widget _buildAttributesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attribute',
              style: AppTextStyles.sectionTitle.copyWith(
                color: widget.themeColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildAttributeBox('STR', c.strength,     c.strModifier, 'strength'),
                _buildAttributeBox('GES', c.dexterity,    c.dexModifier, 'dexterity'),
                _buildAttributeBox('KON', c.constitution, c.conModifier, 'constitution'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildAttributeBox('INT', c.intelligence, c.intModifier, 'intelligence'),
                _buildAttributeBox('WEI', c.wisdom,       c.wisModifier, 'wisdom'),
                _buildAttributeBox('CHA', c.charisma,     c.chaModifier, 'charisma'),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
                  onSave: (v) => setState(() => _setAttributeValue(key, v)),
                )
            : null,
        child: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: widget.editMode
                  ? widget.themeColor.withValues(alpha:0.4)
                  : Colors.grey[300]!,
              width: widget.editMode ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(label, style: AppTextStyles.label),
              const SizedBox(height: 4),
              Text(
                modText,
                style: AppTextStyles.statLarge.copyWith(
                  color: widget.themeColor,
                ),
              ),
              Text('$score', style: AppTextStyles.labelXs),
            ],
          ),
        ),
      ),
    );
  }

  void _setAttributeValue(String key, int value) {
    switch (key) {
      case 'strength':     c.strength     = value;
      case 'dexterity':    c.dexterity    = value;
      case 'constitution': c.constitution = value;
      case 'intelligence': c.intelligence = value;
      case 'wisdom':       c.wisdom       = value;
      case 'charisma':     c.charisma     = value;
    }
  }

  // ── Währung ────────────────────────────────────────────────────────────────

  Widget _buildCurrencyCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Währung',
              style: AppTextStyles.sectionTitle.copyWith(
                color: widget.themeColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildCurrencyBox('PP', c.platinumPieces, 'platinum'),
                _buildCurrencyBox('GP', c.goldPieces,     'gold'),
                _buildCurrencyBox('EP', c.electrumPieces, 'electrum'),
                _buildCurrencyBox('SP', c.silverPieces,   'silver'),
                _buildCurrencyBox('KP', c.copperPieces,   'copper'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyBox(String label, int amount, String key) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _showNumberDialog(
                  _currencyLabel(key),
                  amount,
                  min: 0,
                  max: 9999999,
                  onSave: (v) => setState(() => _setCurrencyValue(key, v)),
                ),
        child: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey[300]!,
              width: widget.editMode ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: _currencyColor(key).withValues(alpha:0.05),
          ),
          child: Column(
            children: [
              Text(
                '$amount',
                style: AppTextStyles.statMedium.copyWith(
                  color: _currencyColor(key),
                ),
              ),
              Text(label, style: AppTextStyles.labelXs),
            ],
          ),
        ),
      ),
    );
  }

  void _setCurrencyValue(String key, int value) {
    switch (key) {
      case 'platinum':  c.platinumPieces  = value;
      case 'gold':      c.goldPieces      = value;
      case 'electrum':  c.electrumPieces  = value;
      case 'silver':    c.silverPieces    = value;
      case 'copper':    c.copperPieces    = value;
    }
  }

  String _currencyLabel(String key) {
    const labels = {
      'platinum': 'Platinmünzen',
      'gold':     'Goldmünzen',
      'electrum': 'Elektrummünzen',
      'silver':   'Silbermünzen',
      'copper':   'Kupfermünzen',
    };
    return labels[key] ?? key;
  }

  Color _currencyColor(String key) {
    switch (key) {
      case 'platinum': return Colors.blueGrey;
      case 'gold':     return const Color(0xFFB8860B);
      case 'electrum': return Colors.teal;
      case 'silver':   return Colors.grey;
      case 'copper':   return const Color(0xFFB87333);
      default:         return Colors.grey;
    }
  }

  // ── Dialoge ────────────────────────────────────────────────────────────────

  Future<void> _showUseHitDiceDialog() async {
    final available = c.level - c.usedHitDice;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Trefferwürfel ausgeben',
          style: AppTextStyles.sectionTitle,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Verfügbar: $available W${c.hitDie}',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 8),
            Text(
              'Wirf einen W${c.hitDie} und addiere deinen '
              'Konstitutionsmodifikator (${c.conModifier >= 0 ? '+${c.conModifier}' : '${c.conModifier}'}) '
              'um TP zu regenerieren.',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
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
              setState(() => c.usedHitDice++);
              _save();
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: widget.themeColor),
            child: Text('Würfel ausgeben', style: AppTextStyles.body),
          ),
        ],
      ),
    );
  }

  Future<void> _showHpDialog() async {
    final controller = TextEditingController(
      text: '${c.currentHitPoints}',
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Trefferpunkte setzen',
            style: AppTextStyles.sectionTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Maximum: ${c.maxHitPoints}', style: AppTextStyles.body),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
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
              final value = int.tryParse(controller.text);
              if (value != null) {
                setState(() => c.currentHitPoints = value);
                _save();
              }
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
                backgroundColor: widget.themeColor),
            child: Text('Speichern', style: AppTextStyles.body),
          ),
        ],
      ),
    );
  }

  Future<void> _showDamageHealDialog({required bool isDamage}) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isDamage ? 'Schaden erleiden' : 'Heilen',
          style: AppTextStyles.sectionTitle,
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: AppTextStyles.body,
          decoration: InputDecoration(
            labelText: isDamage ? 'Schadenspunkte' : 'Heilungspunkte',
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
              final value = int.tryParse(controller.text);
              if (value != null) {
                setState(() {
                  if (isDamage) {
                    // Schaden zieht zuerst temporäre TP ab
                    final tempReduction =
                        value.clamp(0, c.temporaryHitPoints);
                    c.temporaryHitPoints -= tempReduction;
                    c.currentHitPoints -= (value - tempReduction);
                  } else {
                    c.currentHitPoints += value;
                  }
                });
                _save();
              }
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: isDamage ? Colors.red : Colors.green,
            ),
            child: Text('Bestätigen', style: AppTextStyles.body),
          ),
        ],
      ),
    );
  }

  Future<void> _showTempHpDialog() async {
    final controller = TextEditingController(
      text: '${c.temporaryHitPoints}',
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Temporäre TP', style: AppTextStyles.sectionTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Temporäre TP stapeln sich nicht – '
              'nur der höhere Wert zählt.',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
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
              final value = int.tryParse(controller.text);
              if (value != null) {
                setState(() {
                  // Nur setzen wenn neuer Wert höher ist
                  c.temporaryHitPoints =
                      value > c.temporaryHitPoints ? value : c.temporaryHitPoints;
                });
                _save();
              }
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.blue),
            child: Text('Setzen', style: AppTextStyles.body),
          ),
        ],
      ),
    );
  }

  Future<void> _showNumberDialog(
    String label,
    int currentValue, {
    required int min,
    required int max,
    required void Function(int) onSave,
  }) async {
    final controller = TextEditingController(text: '$currentValue');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(label, style: AppTextStyles.sectionTitle),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: AppTextStyles.body,
          decoration: InputDecoration(
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
              final value = int.tryParse(controller.text);
              if (value != null && value >= min && value <= max) {
                onSave(value);
                _save();
              }
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
                backgroundColor: widget.themeColor),
            child: Text('Speichern', style: AppTextStyles.body),
          ),
        ],
      ),
    );
  }
}