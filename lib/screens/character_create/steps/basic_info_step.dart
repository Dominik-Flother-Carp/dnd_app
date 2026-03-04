// lib/screens/character_create/steps/basic_info_step.dart

import 'package:flutter/material.dart';
import 'package:dnd_app/models/character.dart';
import 'package:dnd_app/models/classes.dart';
import 'package:dnd_app/models/races.dart';
import 'package:dnd_app/models/backgrounds.dart';
import 'package:dnd_app/theme/app_text_styles.dart';

class BasicInfoStep extends StatefulWidget {
  final Character character;
  final bool useEdition2024;

  const BasicInfoStep({
    super.key,
    required this.character,
    required this.useEdition2024,
  });

  @override
  State<BasicInfoStep> createState() => BasicInfoStepState();
}

class BasicInfoStepState extends State<BasicInfoStep> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _subclassController;

  CharacterClass? _selectedClass;
  Race? _selectedRace;
  Background? _selectedBackground;
  String? _selectedAlignment;

  static const List<String> _alignments = [
    'Rechtschaffen Gut',
    'Neutral Gut',
    'Chaotisch Gut',
    'Rechtschaffen Neutral',
    'Neutral',
    'Chaotisch Neutral',
    'Rechtschaffen Böse',
    'Neutral Böse',
    'Chaotisch Böse',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.character.name == 'Unbenannt' ? '' : widget.character.name,
    );
    _subclassController = TextEditingController(
      text: widget.character.subclass,
    );
    _selectedClass = characterClasses
        .where((c) => c.name == widget.character.characterClass)
        .firstOrNull;
    _selectedRace = races
        .where((r) => r.name == widget.character.race)
        .firstOrNull;
    _selectedBackground = backgrounds
        .where((b) => b.name == widget.character.background)
        .firstOrNull;
    _selectedAlignment = widget.character.alignment.isEmpty
        ? null
        : widget.character.alignment;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subclassController.dispose();
    super.dispose();
  }

  bool validate() => _formKey.currentState?.validate() ?? false;

  void applyTo(Character character) {
    character.name      = _nameController.text.trim();
    character.subclass  = _subclassController.text.trim();
    character.alignment = _selectedAlignment ?? '';

    if (_selectedClass != null) {
      character.characterClass = _selectedClass!.name;
      character.hitDie         = _selectedClass!.hitDie;
    }

    if (_selectedRace != null) {
      character.race  = _selectedRace!.name;
      character.speed = _selectedRace!.speed;

      for (final skill in _selectedRace!.skillProficiencies) {
        character.skillProficiencies[skill] = true;
      }

      if (!widget.useEdition2024) {
        _selectedRace!.attributeBonuses2014.forEach((attribute, bonus) {
          _applyAttributeBonus(character, attribute, bonus);
        });
      }
    }

    if (_selectedBackground != null) {
      character.background = _selectedBackground!.name;

      for (final skill in _selectedBackground!.skillProficiencies) {
        character.skillProficiencies[skill] = true;
      }

      if (widget.useEdition2024 &&
          _selectedBackground!.bonusAttribute2024 != null) {
        _applyAttributeBonus(
          character,
          _selectedBackground!.bonusAttribute2024!,
          _selectedBackground!.bonusValue2024,
        );
      }
    }
  }

  void _applyAttributeBonus(
      Character character, String attribute, int bonus) {
    switch (attribute) {
      case 'strength':     character.strength     += bonus;
      case 'dexterity':    character.dexterity    += bonus;
      case 'constitution': character.constitution += bonus;
      case 'intelligence': character.intelligence += bonus;
      case 'wisdom':       character.wisdom       += bonus;
      case 'charisma':     character.charisma     += bonus;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEditionBadge(),
          const SizedBox(height: 16),
          Text('Identität', style: AppTextStyles.sectionTitle),
          _buildTextField(
            controller: _nameController,
            label: 'Name *',
            hint: 'z.B. Thorin Eichenschild',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Bitte gib einen Namen ein';
              }
              return null;
            },
          ),
          Text('Klasse', style: AppTextStyles.sectionTitle),
          _buildClassDropdown(),
          _buildTextField(
            controller: _subclassController,
            label: 'Unterklasse',
            hint: 'z.B. Champion, Evokation',
          ),
          Text('Rasse', style: AppTextStyles.sectionTitle),
          _buildRaceDropdown(),
          Text('Hintergrund', style: AppTextStyles.sectionTitle),
          _buildBackgroundDropdown(),
          _buildAlignmentDropdown(),
          if (_selectedClass != null ||
              _selectedRace != null ||
              _selectedBackground != null)
            _buildDerivedValuesSummary(),
        ],
      ),
    );
  }

  Widget _buildEditionBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: widget.useEdition2024
            ? const Color(0xFF1B4F72)
            : const Color(0xFF3B1F0A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        widget.useEdition2024 ? 'D&D 2024' : 'D&D 2014',
        style: AppTextStyles.badge,
      ),
    );
  }

  Widget _buildClassDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<CharacterClass>(
        initialValue: _selectedClass,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
        ),
        hint: Text('Klasse wählen', style: AppTextStyles.body),
        items: characterClasses.map((c) {
          return DropdownMenuItem(
            value: c,
            child: Text(c.name, style: AppTextStyles.body),
          );
        }).toList(),
        onChanged: (value) => setState(() => _selectedClass = value),
      ),
    );
  }

  Widget _buildRaceDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<Race>(
        initialValue: _selectedRace,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
        ),
        hint: Text('Rasse wählen', style: AppTextStyles.body),
        items: races.map((r) {
          return DropdownMenuItem(
            value: r,
            child: Text(r.name, style: AppTextStyles.body),
          );
        }).toList(),
        onChanged: (value) => setState(() => _selectedRace = value),
      ),
    );
  }

  Widget _buildBackgroundDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<Background>(
        initialValue: _selectedBackground,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
        ),
        hint: Text('Hintergrund wählen', style: AppTextStyles.body),
        items: backgrounds.map((b) {
          return DropdownMenuItem(
            value: b,
            child: Text(b.name, style: AppTextStyles.body),
          );
        }).toList(),
        onChanged: (value) => setState(() => _selectedBackground = value),
      ),
    );
  }

  Widget _buildAlignmentDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedAlignment,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
        ),
        hint: Text('Gesinnung wählen', style: AppTextStyles.body),
        items: _alignments.map((a) {
          return DropdownMenuItem(
            value: a,
            child: Text(a, style: AppTextStyles.body),
          );
        }).toList(),
        onChanged: (value) => setState(() => _selectedAlignment = value),
      ),
    );
  }

  Widget _buildDerivedValuesSummary() {
    return Card(
      color: const Color(0xFFFDF6E3),
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Automatisch übernommen', style: AppTextStyles.cardTitle),
            const SizedBox(height: 8),
            if (_selectedClass != null) ...[
              _buildDerivedRow(
                Icons.casino,
                'Trefferwürfel',
                'W${_selectedClass!.hitDie}',
              ),
              if (_selectedClass!.spellcastingAttribute.isNotEmpty)
                _buildDerivedRow(
                  Icons.auto_fix_high,
                  'Zauberattribut',
                  _spellcastingAttributeLabel(
                      _selectedClass!.spellcastingAttribute),
                ),
            ],
            if (_selectedRace != null) ...[
              _buildDerivedRow(
                Icons.directions_walk,
                'Bewegungsgeschwindigkeit',
                '${_selectedRace!.speed} m',
              ),
              if (!widget.useEdition2024 &&
                  _selectedRace!.attributeBonuses2014.isNotEmpty)
                _buildDerivedRow(
                  Icons.add_circle_outline,
                  'Attributboni (Rasse)',
                  _formatAttributeBonuses(
                      _selectedRace!.attributeBonuses2014),
                ),
            ],
            if ((_selectedBackground != null &&
                    _selectedBackground!.skillProficiencies.isNotEmpty) ||
                (_selectedRace != null &&
                    _selectedRace!.skillProficiencies.isNotEmpty)) ...[
              _buildDerivedRow(
                Icons.school,
                'Fertigkeitsübungen',
                {
                  ...?_selectedRace?.skillProficiencies,
                  ...?_selectedBackground?.skillProficiencies,
                }.map((s) => _skillLabel(s)).join(', '),
              ),
            ],
            if (widget.useEdition2024 &&
                _selectedBackground?.bonusAttribute2024 != null)
              _buildDerivedRow(
                Icons.add_circle_outline,
                'Attributbonus (2024)',
                '+${_selectedBackground!.bonusValue2024} ${_attributeLabel(_selectedBackground!.bonusAttribute2024!)}',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDerivedRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF8B0000)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.bodySmall),
                Text(value, style: AppTextStyles.statSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        style: AppTextStyles.body,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        validator: validator,
      ),
    );
  }

  String _spellcastingAttributeLabel(String attribute) {
    const labels = {
      'intelligence': 'Intelligenz',
      'wisdom':       'Weisheit',
      'charisma':     'Charisma',
    };
    return labels[attribute] ?? attribute;
  }

  String _attributeLabel(String attribute) {
    const labels = {
      'strength':     'Stärke',
      'dexterity':    'Geschicklichkeit',
      'constitution': 'Konstitution',
      'intelligence': 'Intelligenz',
      'wisdom':       'Weisheit',
      'charisma':     'Charisma',
    };
    return labels[attribute] ?? attribute;
  }

  String _skillLabel(String skill) {
    const labels = {
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
    return labels[skill] ?? skill;
  }

  String _formatAttributeBonuses(Map<String, int> bonuses) {
    return bonuses.entries
        .map((e) => '+${e.value} ${_attributeLabel(e.key)}')
        .join(', ');
  }
}