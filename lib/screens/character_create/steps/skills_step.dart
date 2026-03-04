// lib/screens/character_create/steps/skills_step.dart

import 'package:flutter/material.dart';
import 'package:dnd_app/models/character.dart';
import 'package:dnd_app/models/classes.dart';
import 'package:dnd_app/models/races.dart';
import 'package:dnd_app/models/backgrounds.dart';
import 'package:dnd_app/theme/app_text_styles.dart';
import 'package:dnd_app/models/skills.dart';

class SkillsStep extends StatefulWidget {
  final Character character;

  const SkillsStep({
    super.key,
    required this.character,
  });

  @override
  State<SkillsStep> createState() => SkillsStepState();
}

class SkillsStepState extends State<SkillsStep> {
  final Set<String> _selectedSkills = {};
  late Set<String> _preselectedSkills;
  late List<String> _availableSkills;
  late int _skillChoices;

  @override
  void initState() {
    super.initState();

    final selectedClass = characterClasses
        .where((c) => c.name == widget.character.characterClass)
        .firstOrNull;
    _availableSkills = selectedClass?.availableSkills ?? [];
    _skillChoices    = selectedClass?.skillChoices ?? 2;

    _preselectedSkills = widget.character.skillProficiencies.entries
        .where((e) => e.value == true)
        .map((e) => e.key)
        .toSet();

    final extraSkills = _preselectedSkills
        .where((s) => !_availableSkills.contains(s))
        .toList();
    _availableSkills = [..._availableSkills, ...extraSkills];
  }

  bool validate() {
    if (_selectedSkills.length < _skillChoices) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bitte wähle noch '
            '${_skillChoices - _selectedSkills.length} '
            'Fertigkeit${_skillChoices - _selectedSkills.length == 1 ? '' : 'en'}',
            style: AppTextStyles.body,
          ),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }

  void applyTo(Character character) {
    for (final skill in _selectedSkills) {
      character.skillProficiencies[skill] = true;
    }
  }

  void _toggleSkill(String skill) {
    if (_preselectedSkills.contains(skill)) return;
    setState(() {
      if (_selectedSkills.contains(skill)) {
        _selectedSkills.remove(skill);
      } else if (_selectedSkills.length < _skillChoices) {
        _selectedSkills.add(skill);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fertigkeiten', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 8),
        if (_availableSkills.isEmpty)
          _buildNoClassWarning()
        else ...[
          _buildHeader(),
          const SizedBox(height: 16),
          _buildSkillList(),
          const SizedBox(height: 16),
          if (_preselectedSkills.isNotEmpty) _buildPreselectedInfo(),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    final remaining = _skillChoices - _selectedSkills.length;
    final isDone    = remaining == 0;

    return Row(
      children: [
        Expanded(
          child: Text(
            'Wähle $_skillChoices Fertigkeiten aus den '
            'verfügbaren Optionen deiner Klasse '
            '(${widget.character.characterClass}).',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isDone ? Colors.green : const Color(0xFF8B0000),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isDone ? 'Fertig!' : '$remaining übrig',
            style: AppTextStyles.badge,
          ),
        ),
      ],
    );
  }

  Widget _buildSkillList() {
    return Column(
      children: _availableSkills.map((skill) {
        final isPreselected = _preselectedSkills.contains(skill);
        final isSelected    = _selectedSkills.contains(skill) || isPreselected;
        final isDisabled    = !isSelected &&
                              _selectedSkills.length >= _skillChoices &&
                              !isPreselected;

        return _buildSkillTile(
          skill:         skill,
          isSelected:    isSelected,
          isPreselected: isPreselected,
          isDisabled:    isDisabled,
        );
      }).toList(),
    );
  }

  Widget _buildSkillTile({
    required String skill,
    required bool isSelected,
    required bool isPreselected,
    required bool isDisabled,
  }) {
    return GestureDetector(
      onTap: isDisabled ? null : () => _toggleSkill(skill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isPreselected
              ? Colors.grey[100]
              : isSelected
                  ? const Color(0xFF8B0000).withOpacity(0.08)
                  : Colors.white,
          border: Border.all(
            color: isPreselected
                ? Colors.grey[400]!
                : isSelected
                    ? const Color(0xFF8B0000)
                    : isDisabled
                        ? Colors.grey[200]!
                        : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPreselected
                    ? Colors.grey[400]
                    : isSelected
                        ? const Color(0xFF8B0000)
                        : Colors.transparent,
                border: Border.all(
                  color: isPreselected
                      ? Colors.grey[400]!
                      : isSelected
                          ? const Color(0xFF8B0000)
                          : isDisabled
                              ? Colors.grey[300]!
                              : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                Skills.label(skill),
                style: AppTextStyles.body.copyWith(
                  color: isDisabled ? Colors.grey[400] : Colors.black87,
                  fontWeight: isSelected && !isPreselected
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
            if (isPreselected)
              Text(
                _preselectedSource(skill),
                style: AppTextStyles.labelXs.copyWith(
                  color: Colors.grey[500],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _preselectedSource(String skill) {
    final race = races
        .where((r) => r.name == widget.character.race)
        .firstOrNull;
    if (race?.skillProficiencies.contains(skill) == true) {
      return race!.name;
    }

    final background = backgrounds
        .where((b) => b.name == widget.character.background)
        .firstOrNull;
    if (background?.skillProficiencies.contains(skill) == true) {
      return background!.name;
    }

    return '';
  }

  Widget _buildPreselectedInfo() {
    return Card(
      color: const Color(0xFFFDF6E3),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 16, color: Color(0xFF8B0000)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Grau markierte Fertigkeiten wurden bereits durch '
                'deine Rasse oder deinen Hintergrund übernommen.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoClassWarning() {
    return Card(
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_outlined,
                size: 16, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Keine Klasse gewählt. Gehe zurück zu Grunddaten '
                'und wähle eine Klasse aus.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}