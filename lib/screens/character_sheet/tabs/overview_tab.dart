// lib/screens/character_sheet/tabs/overview_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dnd_app/models/character.dart';
import 'package:dnd_app/theme/app_text_styles.dart';

class OverviewTab extends StatelessWidget {
  final Character character;
  final Color themeColor;
  final VoidCallback onChanged;
  final Future<void> Function() onSave;

  const OverviewTab({
    super.key,
    required this.character,
    required this.themeColor,
    required this.onChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCombatStats(context),
        const SizedBox(height: 16),
        _buildAttributes(),
      ],
    );
  }

  // ── Kampfwerte ─────────────────────────────────────────────────────────────

  Widget _buildCombatStats(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kampfwerte',
              style: AppTextStyles.sectionTitle.copyWith(color: themeColor),
            ),
            const SizedBox(height: 16),
            _buildHpSection(context),
            const Divider(height: 24),
            Row(
              children: [
                _buildStatBox('RK', '${character.armorClass}'),
                _buildStatBox(
                  'Initiative',
                  character.initiative >= 0
                      ? '+${character.initiative}'
                      : '${character.initiative}',
                ),
                _buildStatBox('Geschw.', '${character.speed} m'),
                _buildStatBox('Übungsb.', '+${character.proficiencyBonus}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHpSection(BuildContext context) {
    final ratio = character.maxHitPoints > 0
        ? character.currentHitPoints / character.maxHitPoints
        : 0.0;

    final hpColor = ratio > 0.5
        ? Colors.green
        : ratio > 0.25
            ? Colors.orange
            : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Trefferpunkte',
              style: AppTextStyles.cardTitle,
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _showHpDialog(context),
              child: Text(
                '${character.currentHitPoints} / ${character.maxHitPoints}',
                style: AppTextStyles.statLarge.copyWith(color: hpColor),
              ),
            ),
          ],
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(hpColor),
            minHeight: 8,
          ),
        ),
        if (character.temporaryHitPoints > 0) ...[
          const SizedBox(height: 4),
          Text(
            '+${character.temporaryHitPoints} temporäre TP',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.blue),
          ),
        ],
      ],
    );
  }

  Widget _buildStatBox(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.statLarge.copyWith(color: themeColor),
          ),
          Text(label, style: AppTextStyles.labelXs),
        ],
      ),
    );
  }

  Future<void> _showHpDialog(BuildContext context) async {
    final controller = TextEditingController(
      text: '${character.currentHitPoints}',
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Trefferpunkte ändern', style: AppTextStyles.sectionTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Maximum: ${character.maxHitPoints}',
              style: AppTextStyles.body,
            ),
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
            onPressed: () async {
              final value = int.tryParse(controller.text);
              if (value != null) {
                character.currentHitPoints = value;
                onChanged();
                await onSave();
              }
              if (context.mounted) Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: themeColor),
            child: Text('Speichern', style: AppTextStyles.body),
          ),
        ],
      ),
    );
  }

  // ── Attribute ──────────────────────────────────────────────────────────────

  Widget _buildAttributes() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attribute',
              style: AppTextStyles.sectionTitle.copyWith(color: themeColor),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildAttributeBox('STR', character.strength,     character.strModifier),
                _buildAttributeBox('GES', character.dexterity,    character.dexModifier),
                _buildAttributeBox('KON', character.constitution, character.conModifier),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildAttributeBox('INT', character.intelligence, character.intModifier),
                _buildAttributeBox('WEI', character.wisdom,       character.wisModifier),
                _buildAttributeBox('CHA', character.charisma,     character.chaModifier),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttributeBox(String label, int score, int modifier) {
    final modText = modifier >= 0 ? '+$modifier' : '$modifier';

    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(label, style: AppTextStyles.label),
            const SizedBox(height: 4),
            Text(
              modText,
              style: AppTextStyles.statLarge.copyWith(color: themeColor),
            ),
            Text('$score', style: AppTextStyles.labelXs),
          ],
        ),
      ),
    );
  }
}