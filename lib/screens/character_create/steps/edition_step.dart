// lib/screens/character_create/steps/edition_step.dart

import 'package:flutter/material.dart';
import 'package:dnd_app/theme/app_text_styles.dart';

class EditionStep extends StatefulWidget {
  final bool initialValue;

  const EditionStep({
    super.key,
    required this.initialValue,
  });

  @override
  State<EditionStep> createState() => EditionStepState();
}

class EditionStepState extends State<EditionStep> {
  late bool _useEdition2024;

  @override
  void initState() {
    super.initState();
    _useEdition2024 = widget.initialValue;
  }

  bool validate() => true;

  bool getValue() => _useEdition2024;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Regelwerk', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 8),
        Text(
          'Welche Edition soll für diesen Charakter verwendet werden?',
          style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        _buildEditionCard(
          title: 'D&D 5e 2014',
          subtitle: 'Klassisches Regelwerk. Rassen haben feste Attributboni, '
              'Hintergründe geben zwei Fertigkeitsübungen.',
          isSelected: !_useEdition2024,
          onTap: () => setState(() => _useEdition2024 = false),
          color: const Color(0xFF3B1F0A),
        ),
        const SizedBox(height: 16),
        _buildEditionCard(
          title: 'D&D 5e 2024',
          subtitle: 'Überarbeitetes Regelwerk. Freie Attributverteilung, '
              'Hintergründe geben zusätzlich einen Attributbonus.',
          isSelected: _useEdition2024,
          onTap: () => setState(() => _useEdition2024 = true),
          color: const Color(0xFF1B4F72),
        ),
      ],
    );
  }

  Widget _buildEditionCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha:0.08) : Colors.white,
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : Colors.grey[400]!,
                  width: 2,
                ),
                color: isSelected ? color : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.cardTitle.copyWith(
                      color: isSelected ? color : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}