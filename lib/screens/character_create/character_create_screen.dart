// lib/screens/character_create/character_create_screen.dart

import 'package:dnd_app/models/classes.dart';
import 'package:flutter/material.dart';
import 'package:dnd_app/models/character.dart';
import 'package:dnd_app/repositories/character_repository.dart';
import 'package:dnd_app/screens/character_create/steps/edition_step.dart';
import 'package:dnd_app/screens/character_create/steps/basic_info_step.dart';
import 'package:dnd_app/screens/character_create/steps/skills_step.dart';
import 'package:dnd_app/screens/character_create/steps/attributes_step.dart';
import 'package:dnd_app/theme/app_text_styles.dart';

class CharacterCreateScreen extends StatefulWidget {
  const CharacterCreateScreen({super.key});

  @override
  State<CharacterCreateScreen> createState() => _CharacterCreateScreenState();
}

class _CharacterCreateScreenState extends State<CharacterCreateScreen> {
  final CharacterRepository _repository = CharacterRepository();

  int _currentStep = 0;
  final Character _character = Character(name: 'Unbenannt');

  final GlobalKey<EditionStepState>    _editionKey    = GlobalKey();
  final GlobalKey<BasicInfoStepState>  _basicInfoKey  = GlobalKey();
  final GlobalKey<SkillsStepState>     _skillsKey     = GlobalKey();
  final GlobalKey<AttributesStepState> _attributesKey = GlobalKey();

  bool _isSaving = false;

  Color get _themeColor => _character.useEdition2024
      ? const Color(0xFF1B4F72)
      : const Color(0xFF3B1F0A);

  Future<void> _nextStep() async {
    final isValid = switch (_currentStep) {
      0 => _editionKey.currentState?.validate()    ?? false,
      1 => _basicInfoKey.currentState?.validate()  ?? false,
      2 => _skillsKey.currentState?.validate()     ?? false,
      3 => _attributesKey.currentState?.validate() ?? false,
      _ => false,
    };

    if (!isValid) return;

    switch (_currentStep) {
      case 0:
        _character.useEdition2024 =
            _editionKey.currentState?.getValue() ?? false;
        setState(() => _currentStep++);
        return;
      case 1:
        _basicInfoKey.currentState?.applyTo(_character);
      case 2:
        _skillsKey.currentState?.applyTo(_character);
      case 3:
        _attributesKey.currentState?.applyTo(_character);
        await _saveCharacter();
        return;
    }

    setState(() => _currentStep++);
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _saveCharacter() async {
    setState(() => _isSaving = true);
    // Rettungswürfe übernehmen nach Klasse
    characterClasses
        .firstWhere((c) => c.name == _character.characterClass)
        .proficientSavingThrows
        .forEach((attr) => _character.savingThrowProficiencies[attr] = true);

    final conMod = Character.modifier(_character.constitution);
    _character.maxHitPoints = _character.hitDie + conMod;
    _character.currentHitPoints = _character.maxHitPoints;

    _character.spellSlots = calculateSpellSlots(
      _character.characterClass,
      _character.level,
    );

    await _repository.insertCharacter(_character);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _themeColor,
        foregroundColor: const Color(0xFFF5DEB3),
        title: Text('Neuer Charakter', style: AppTextStyles.cardTitle.copyWith(
          color: const Color(0xFFF5DEB3),
        )),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _showDiscardDialog,
        ),
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildCurrentStep(),
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
  final steps = ['Edition', 'Grunddaten', 'Fertigkeiten', 'Attribute'];

  return Container(
    color: _themeColor,
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    child: Row(
      children: List.generate(steps.length, (index) {
        final isActive = index == _currentStep;
        final isDone   = index < _currentStep;

        return Expanded(
          flex: isActive ? 3 : 1,
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: isDone
                    ? Colors.green
                    : isActive
                        ? const Color(0xFFF5DEB3)
                        : Colors.grey[700],
                child: isDone
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                        '${index + 1}',
                        style: AppTextStyles.labelXs.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isActive ? _themeColor : Colors.grey[400],
                        ),
                      ),
              ),
              if (isActive) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    steps[index],
                    style: AppTextStyles.labelXs.copyWith(
                      color: const Color(0xFFF5DEB3),
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              if (index < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: isDone ? Colors.green : Colors.grey[700],
                  ),
                ),
            ],
          ),
        );
      }),
    ),
  );
}

  Widget _buildCurrentStep() {
    return switch (_currentStep) {
      0 => EditionStep(
          key: _editionKey,
          initialValue: _character.useEdition2024,
        ),
      1 => BasicInfoStep(
          key: _basicInfoKey,
          character: _character,
          useEdition2024: _character.useEdition2024,
        ),
      2 => SkillsStep(
          key: _skillsKey,
          character: _character,
        ),
      3 => AttributesStep(
          key: _attributesKey,
          character: _character,
          useEdition2024: _character.useEdition2024,
        ),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: _previousStep,
            icon: const Icon(Icons.arrow_back),
            label: Text(
              _currentStep == 0 ? 'Abbrechen' : 'Zurück',
              style: AppTextStyles.body,
            ),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: _isSaving ? null : _nextStep,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(_currentStep == 3 ? Icons.save : Icons.arrow_forward),
            label: Text(
              _currentStep == 3 ? 'Speichern' : 'Weiter',
              style: AppTextStyles.body,
            ),
            style: FilledButton.styleFrom(
              backgroundColor: _themeColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDiscardDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Abbrechen?', style: AppTextStyles.sectionTitle),
        content: Text(
          'Der neue Charakter wird nicht gespeichert.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Weiter bearbeiten', style: AppTextStyles.body),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Verwerfen', style: AppTextStyles.body),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) Navigator.pop(context);
  }
}