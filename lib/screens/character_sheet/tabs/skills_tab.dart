// lib/screens/character_sheet/tabs/skills_tab.dart

import 'package:flutter/material.dart';
import 'package:dnd_app/models/character.dart';
import 'package:dnd_app/theme/app_text_styles.dart';

class SkillsTab extends StatelessWidget {
  final Character character;
  final Color themeColor;

  const SkillsTab({
    super.key,
    required this.character,
    required this.themeColor,
  });

  static const Map<String, String> _skillLabels = {
    'acrobatics':     'Akrobatik',
    'animalHandling': 'Tierführung',
    'arcana':         'Arkanes Wissen',
    'athletics':      'Athletik',
    'deception':      'Täuschung',
    'history':        'Geschichte',
    'insight':        'Einsicht',
    'intimidation':   'Einschüchterung',
    'investigation':  'Untersuchung',
    'medicine':       'Medizin',
    'nature':         'Naturkunde',
    'perception':     'Wahrnehmung',
    'performance':    'Aufführung',
    'persuasion':     'Überzeugung',
    'religion':       'Religion',
    'sleightOfHand':  'Fingerfertigkeit',
    'stealth':        'Heimlichkeit',
    'survival':       'Überleben',
  };

  static const Map<String, String> _skillAttributes = {
    'acrobatics':     'GES',
    'animalHandling': 'WEI',
    'arcana':         'INT',
    'athletics':      'STR',
    'deception':      'CHA',
    'history':        'INT',
    'insight':        'WEI',
    'intimidation':   'CHA',
    'investigation':  'INT',
    'medicine':       'WEI',
    'nature':         'INT',
    'perception':     'WEI',
    'performance':    'CHA',
    'persuasion':     'CHA',
    'religion':       'INT',
    'sleightOfHand':  'GES',
    'stealth':        'GES',
    'survival':       'WEI',
  };

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSavingThrows(),
        const SizedBox(height: 16),
        _buildSkills(),
      ],
    );
  }

  Widget _buildSavingThrows() {
    final saves = [
      ('STR', 'strength',     character.savingThrowBonus('strength')),
      ('GES', 'dexterity',    character.savingThrowBonus('dexterity')),
      ('KON', 'constitution', character.savingThrowBonus('constitution')),
      ('INT', 'intelligence', character.savingThrowBonus('intelligence')),
      ('WEI', 'wisdom',       character.savingThrowBonus('wisdom')),
      ('CHA', 'charisma',     character.savingThrowBonus('charisma')),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rettungswürfe',
              style: AppTextStyles.sectionTitle.copyWith(color: themeColor),
            ),
            const SizedBox(height: 12),
            ...saves.map((save) {
              final (label, key, bonus) = save;
              final isProficient =
                  character.savingThrowProficiencies[key] ?? false;
              return _buildProficiencyRow(
                label:        label,
                bonus:        bonus,
                isProficient: isProficient,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSkills() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fertigkeiten',
              style: AppTextStyles.sectionTitle.copyWith(color: themeColor),
            ),
            const SizedBox(height: 12),
            ..._skillLabels.keys.map((skillKey) {
              final bonus        = character.skillBonus(skillKey);
              final isProficient = character.skillProficiencies[skillKey] ?? false;
              final hasExpertise = character.skillExpertise[skillKey] ?? false;
              final attribute    = _skillAttributes[skillKey] ?? '';

              return _buildProficiencyRow(
                label:        '${_skillLabels[skillKey]} ($attribute)',
                bonus:        bonus,
                isProficient: isProficient,
                hasExpertise: hasExpertise,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildProficiencyRow({
    required String label,
    required int bonus,
    required bool isProficient,
    bool hasExpertise = false,
  }) {
    final bonusText = bonus >= 0 ? '+$bonus' : '$bonus';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Übungs-Indikator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasExpertise
                  ? themeColor
                  : isProficient
                      ? themeColor.withOpacity(0.5)
                      : Colors.transparent,
              border: Border.all(
                color: isProficient || hasExpertise
                    ? themeColor
                    : Colors.grey[400]!,
                width: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: AppTextStyles.body),
          ),
          Text(
            bonusText,
            style: AppTextStyles.statSmall.copyWith(
              color: isProficient || hasExpertise
                  ? themeColor
                  : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}