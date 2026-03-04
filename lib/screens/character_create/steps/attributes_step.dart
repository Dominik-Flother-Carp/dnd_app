// lib/screens/character_create/steps/attributes_step.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dnd_app/models/character.dart';
import 'package:dnd_app/models/races.dart';
import 'package:dnd_app/theme/app_text_styles.dart';

class AttributesStep extends StatefulWidget {
  final Character character;
  final bool useEdition2024;

  const AttributesStep({
    super.key,
    required this.character,
    required this.useEdition2024,
  });

  @override
  State<AttributesStep> createState() => AttributesStepState();
}

class AttributesStepState extends State<AttributesStep> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _strController;
  late TextEditingController _dexController;
  late TextEditingController _conController;
  late TextEditingController _intController;
  late TextEditingController _wisController;
  late TextEditingController _chaController;

  int _str = 10, _dex = 10, _con = 10;
  int _int = 10, _wis = 10, _cha = 10;

  late int _freePoints;
  Map<String, int> _distributedPoints = {
    'strength': 0, 'dexterity': 0, 'constitution': 0,
    'intelligence': 0, 'wisdom': 0, 'charisma': 0,
  };

  int get _remainingPoints =>
      _freePoints - _distributedPoints.values.fold(0, (sum, v) => sum + v);

  @override
  void initState() {
    super.initState();
    _str = widget.character.strength;
    _dex = widget.character.dexterity;
    _con = widget.character.constitution;
    _int = widget.character.intelligence;
    _wis = widget.character.wisdom;
    _cha = widget.character.charisma;

    _strController = TextEditingController(text: '$_str');
    _dexController = TextEditingController(text: '$_dex');
    _conController = TextEditingController(text: '$_con');
    _intController = TextEditingController(text: '$_int');
    _wisController = TextEditingController(text: '$_wis');
    _chaController = TextEditingController(text: '$_cha');

    final selectedRace = races
        .where((r) => r.name == widget.character.race)
        .firstOrNull;
    _freePoints = selectedRace?.freeAttributePoints2024 ?? 3;
  }

  @override
  void dispose() {
    _strController.dispose();
    _dexController.dispose();
    _conController.dispose();
    _intController.dispose();
    _wisController.dispose();
    _chaController.dispose();
    super.dispose();
  }

  bool validate() {
    if (widget.useEdition2024 && _remainingPoints != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _remainingPoints > 0
                ? 'Noch $_remainingPoints Punkt${_remainingPoints == 1 ? '' : 'e'} zu verteilen'
                : 'Zu viele Punkte verteilt',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return _formKey.currentState?.validate() ?? false;
  }

  void applyTo(Character character) {
    character.strength     = _str;
    character.dexterity    = _dex;
    character.constitution = _con;
    character.intelligence = _int;
    character.wisdom       = _wis;
    character.charisma     = _cha;

    if (widget.useEdition2024) {
      character.strength     += _distributedPoints['strength']!;
      character.dexterity    += _distributedPoints['dexterity']!;
      character.constitution += _distributedPoints['constitution']!;
      character.intelligence += _distributedPoints['intelligence']!;
      character.wisdom       += _distributedPoints['wisdom']!;
      character.charisma     += _distributedPoints['charisma']!;
    }
  }

  String _modifierText(int score) {
    final mod = Character.modifier(score);
    return mod >= 0 ? '+$mod' : '$mod';
  }

  void _onAttributeChanged(String value, void Function(int) onUpdate) {
    final parsed = int.tryParse(value);
    if (parsed != null) {
      setState(() => onUpdate(parsed.clamp(1, 30)));
    }
  }

  void _addFreePoint(String attribute) {
    if (_remainingPoints <= 0) return;
    setState(() => _distributedPoints[attribute] =
        (_distributedPoints[attribute] ?? 0) + 1);
  }

  void _removeFreePoint(String attribute) {
    if ((_distributedPoints[attribute] ?? 0) <= 0) return;
    setState(() => _distributedPoints[attribute] =
        (_distributedPoints[attribute] ?? 0) - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Attribute', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 8),
          Text(
            'Gib die Werte für die 6 Kernattribute ein. '
            'Der Modifikator wird automatisch berechnet.',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          _buildAttributeRow('Stärke (STR)',           _strController, _str, (v) => _str = v, 'strength'),
          _buildAttributeRow('Geschicklichkeit (GES)', _dexController, _dex, (v) => _dex = v, 'dexterity'),
          _buildAttributeRow('Konstitution (KON)',     _conController, _con, (v) => _con = v, 'constitution'),
          _buildAttributeRow('Intelligenz (INT)',      _intController, _int, (v) => _int = v, 'intelligence'),
          _buildAttributeRow('Weisheit (WEI)',         _wisController, _wis, (v) => _wis = v, 'wisdom'),
          _buildAttributeRow('Charisma (CHA)',         _chaController, _cha, (v) => _cha = v, 'charisma'),
          const SizedBox(height: 16),
          if (widget.useEdition2024) _buildFreePointsSection(),
          _buildModifierSummary(),
        ],
      ),
    );
  }

  Widget _buildAttributeRow(
    String label,
    TextEditingController controller,
    int currentValue,
    void Function(int) onUpdate,
    String attributeKey,
  ) {
    final bonus = widget.useEdition2024
        ? (_distributedPoints[attributeKey] ?? 0)
        : 0;
    final totalValue = currentValue + bonus;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(label, style: AppTextStyles.body),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            color: const Color(0xFF8B0000),
            onPressed: currentValue > 1
                ? () {
                    final newVal = currentValue - 1;
                    controller.text = '$newVal';
                    setState(() => onUpdate(newVal));
                  }
                : null,
          ),
          SizedBox(
            width: 56,
            child: TextFormField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              style: AppTextStyles.body,
              onChanged: (v) => _onAttributeChanged(v, onUpdate),
              validator: (value) {
                final parsed = int.tryParse(value ?? '');
                if (parsed == null) return '?';
                if (parsed < 1 || parsed > 30) return '1-30';
                return null;
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            color: const Color(0xFF8B0000),
            onPressed: currentValue < 30
                ? () {
                    final newVal = currentValue + 1;
                    controller.text = '$newVal';
                    setState(() => onUpdate(newVal));
                  }
                : null,
          ),
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B1F0A),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _modifierText(totalValue),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.statSmall.copyWith(
                      color: const Color(0xFFF5DEB3),
                    ),
                  ),
                ),
                if (widget.useEdition2024 && bonus > 0)
                  Text(
                    '=$totalValue',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelXs,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreePointsSection() {
    return Card(
      color: const Color(0xFFEBF5FB),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Freie Attributpunkte (2024)',
                  style: AppTextStyles.cardTitle,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _remainingPoints == 0
                        ? Colors.green
                        : _remainingPoints < 0
                            ? Colors.red
                            : const Color(0xFF1B4F72),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_remainingPoints übrig',
                    style: AppTextStyles.badge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Verteile $_freePoints Punkte frei auf deine Attribute.',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            _buildFreePointRow('Stärke',           'strength'),
            _buildFreePointRow('Geschicklichkeit', 'dexterity'),
            _buildFreePointRow('Konstitution',     'constitution'),
            _buildFreePointRow('Intelligenz',      'intelligence'),
            _buildFreePointRow('Weisheit',         'wisdom'),
            _buildFreePointRow('Charisma',         'charisma'),
          ],
        ),
      ),
    );
  }

  Widget _buildFreePointRow(String label, String attributeKey) {
    final points = _distributedPoints[attributeKey] ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AppTextStyles.body),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 20),
            color: const Color(0xFF1B4F72),
            onPressed: points > 0 ? () => _removeFreePoint(attributeKey) : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 24,
            child: Text(
              '+$points',
              textAlign: TextAlign.center,
              style: AppTextStyles.statSmall.copyWith(
                color: points > 0
                    ? const Color(0xFF1B4F72)
                    : Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 20),
            color: const Color(0xFF1B4F72),
            onPressed: _remainingPoints > 0
                ? () => _addFreePoint(attributeKey)
                : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildModifierSummary() {
    final dexTotal = _dex + (_distributedPoints['dexterity'] ?? 0);
    final wisTotal = _wis + (_distributedPoints['wisdom'] ?? 0);

    return Card(
      color: const Color(0xFFFDF6E3),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Abgeleitete Werte', style: AppTextStyles.cardTitle),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDerivedValue('Initiative',   _modifierText(dexTotal)),
                _buildDerivedValue('Pass. Wahrn.', '${10 + Character.modifier(wisTotal)}'),
                _buildDerivedValue('Übungsbonus',  '+2'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDerivedValue(String label, String value) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.statLarge),
        Text(label, style: AppTextStyles.labelXs),
      ],
    );
  }
}