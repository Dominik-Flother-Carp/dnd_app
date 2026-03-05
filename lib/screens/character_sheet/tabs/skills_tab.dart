// lib/screens/character_sheet/tabs/skills_tab.dart

import 'package:flutter/material.dart';
import 'package:dnd_app/models/character.dart';
import 'package:dnd_app/theme/app_text_styles.dart';
import 'package:dnd_app/models/skills.dart';

class SkillsTab extends StatefulWidget {
  final Character character;
  final Color themeColor;
  final bool editMode;
  final Future<void> Function() onSave;

  const SkillsTab({
    super.key,
    required this.character,
    required this.themeColor,
    required this.editMode,
    required this.onSave,
  });

  @override
  State<SkillsTab> createState() => _SkillsTabState();
}

class _SkillsTabState extends State<SkillsTab> {

  //Rotiert durch die Edit-States
  void _toggleSkill(String key) {
    setState(() {
      final isProficient = widget.character.skillProficiencies[key] ?? false;
      final hasExpertise = widget.character.skillExpertise[key] ?? false;

      if (!isProficient && !hasExpertise) {
        // Kein Status -> Übung
        widget.character.skillProficiencies[key] = true;
        widget.character.skillExpertise[key] = false;
      } else if (isProficient && !hasExpertise) {
        // Übung -> Expertise
        widget.character.skillProficiencies[key] = true;
        widget.character.skillExpertise[key] = true;
      } else {
        // Expertise -> kein Status
        widget.character.skillProficiencies[key] = false;
        widget.character.skillExpertise[key] = false;
      }
    });
    widget.onSave();
  }

  void _toggleSavingThrow(String key) {
    setState(() {
      final current = widget.character.savingThrowProficiencies[key] ?? false;
      widget.character.savingThrowProficiencies[key] = !current;
    });
    widget.onSave();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.editMode)
          Card(
            color: widget.themeColor.withValues(alpha:0.06),
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: widget.themeColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tippe auf einen Kreis um den Status zu wechseln.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: widget.themeColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        _buildSavingThrows(),
        const SizedBox(height: 16),
        _buildSkills(),
      ],
    );
  }

  Widget _buildSavingThrows() {
    final saves = [
      ('Stärke',           'strength'),
      ('Geschicklichkeit', 'dexterity'),
      ('Konstitution',     'constitution'),
      ('Intelligenz',      'intelligence'),
      ('Weisheit',         'wisdom'),
      ('Charisma',         'charisma'),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rettungswürfe',
              style: AppTextStyles.sectionTitle.copyWith(color: widget.themeColor),
            ),
            const SizedBox(height: 12),
            ...saves.map((save) {
              final (label, key) = save;
              final isProficient =
                  widget.character.savingThrowProficiencies[key] ?? false;
              final bonus = widget.character.savingThrowBonus(key);
              return _buildProficiencyRow(
                label:        label,
                bonus:        bonus,
                isProficient: isProficient,
                hasExpertise: false,
                onTap: widget.editMode ? () => _toggleSavingThrow(key) : null
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
              style: AppTextStyles.sectionTitle.copyWith(color: widget.themeColor),
            ),
            const SizedBox(height: 12),
            ...Skills.labels.keys.map((skillKey) {
              final bonus        = widget.character.skillBonus(skillKey);
              final isProficient = widget.character.skillProficiencies[skillKey] ?? false;
              final hasExpertise = widget.character.skillExpertise[skillKey] ?? false;
              final attribute    = Skills.attribute(skillKey);

              return _buildProficiencyRow(
                label:        '${Skills.label(skillKey)} ($attribute)',
                bonus:        bonus,
                isProficient: isProficient,
                hasExpertise: hasExpertise,
                onTap: widget.editMode ? () => _toggleSkill(skillKey) : null,
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
    required bool hasExpertise,
    VoidCallback? onTap,
  }) {
    final bonusText = bonus >= 0 ? '+$bonus' : '$bonus';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Übungs-Indikator - tippbar im Edit-Mode
          GestureDetector(
            onTap: onTap,
            child: _buildProficiencyIndicator(isProficient, hasExpertise),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: AppTextStyles.body),
          ),
          Text(
            bonusText,
            style: AppTextStyles.statSmall.copyWith(
              color: isProficient || hasExpertise ? widget.themeColor : Colors.grey[600],
            ),
          ),        
        ],
      ),
    );
  }

  Widget _buildProficiencyIndicator(bool isProficient, bool hasExpertise) {
    // Expertise: voller Kreis mit Ring
    if (hasExpertise) {
      return Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.themeColor,
          border: Border.all(
            color: widget.themeColor,
            width: 2,
          ),
        ),
        child: Center(
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: Colors.white,
                width: 1
              ),
            ),
          ),
        ),
      );
    }
    // Übung: voller Kreis
    if (isProficient) {
      return Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.themeColor,
        ),
      );
    }

    // Keine Übung: leerer Kreis
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.transparent,
        border: Border.all(
          color: Colors.grey[400]!,
          width: 1.5,
        ),
      ),
    );
  }
}