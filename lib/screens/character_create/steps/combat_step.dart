// lib/screens/character_create/steps/combat_step.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dnd_app/models/character.dart';
import 'package:dnd_app/theme/app_text_styles.dart';

class CombatStep extends StatefulWidget {
  final Character character;

  const CombatStep({
    super.key,
    required this.character,
  });

  @override
  State<CombatStep> createState() => CombatStepState();
}

class CombatStepState extends State<CombatStep> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _maxHpController;
  late TextEditingController _armorClassController;

  @override
  void initState() {
    super.initState();
    _maxHpController = TextEditingController(
      text: '${widget.character.maxHitPoints}',
    );
    _armorClassController = TextEditingController(
      text: '${widget.character.armorClass}',
    );
  }

  @override
  void dispose() {
    _maxHpController.dispose();
    _armorClassController.dispose();
    super.dispose();
  }

  bool validate() => _formKey.currentState?.validate() ?? false;

  void applyTo(Character character) {
    character.maxHitPoints     = int.tryParse(_maxHpController.text) ?? 8;
    character.currentHitPoints = character.maxHitPoints;
    character.armorClass       = int.tryParse(_armorClassController.text) ?? 10;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kampfwerte', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 8),
          Text(
            'Diese Werte können später jederzeit angepasst werden.',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          _buildNumberField(
            controller: _maxHpController,
            label: 'Maximale Trefferpunkte *',
            hint: 'z.B. 10',
            min: 1,
            max: 9999,
          ),
          _buildNumberField(
            controller: _armorClassController,
            label: 'Rüstungsklasse *',
            hint: 'z.B. 12',
            min: 1,
            max: 30,
          ),
          const SizedBox(height: 8),
          _buildInfoCard(),
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required int min,
    required int max,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: AppTextStyles.body,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          final parsed = int.tryParse(value ?? '');
          if (parsed == null) return 'Bitte eine Zahl eingeben';
          if (parsed < min || parsed > max) return '$min–$max';
          return null;
        },
      ),
    );
  }

  Widget _buildInfoCard() {
    final hitDie         = widget.character.hitDie;
    final characterClass = widget.character.characterClass;
    final speed          = widget.character.speed;

    return Card(
      color: const Color(0xFFFDF6E3),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aus vorherigen Schritten übernommen',
              style: AppTextStyles.cardTitle,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.casino,
              'Trefferwürfel',
              characterClass.isNotEmpty
                  ? 'W$hitDie ($characterClass)'
                  : 'W$hitDie',
            ),
            _buildInfoRow(
              Icons.directions_walk,
              'Bewegungsgeschwindigkeit',
              '$speed m',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF8B0000)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: AppTextStyles.bodySmall),
          ),
          Text(value, style: AppTextStyles.statSmall),
        ],
      ),
    );
  }
}