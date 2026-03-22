// lib/screens/character_list/character_card.dart

import 'package:flutter/material.dart';
import 'package:dnd_app/models/character.dart';
import 'package:dnd_app/theme/app_text_styles.dart';
import 'package:dnd_app/theme/app_colors.dart';

class CharacterCard extends StatelessWidget {
  final Character character;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const CharacterCard({
    super.key,
    required this.character,
    required this.onDelete,
    required this.onTap,
  });

  Color get _editionColor => AppColors.themeColorFor(character.useEdition2024);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Farbiger Streifen links
                Container(
                  width: 6,
                  color: _editionColor,
                ),
                // Karteninhalt
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          backgroundColor: _editionColor,
                          foregroundColor: Colors.white,
                          radius: 28,
                          child: Text(
                            character.name.isNotEmpty
                                ? character.name[0].toUpperCase()
                                : '?',
                            style: AppTextStyles.avatarMedium,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                character.name,
                                style: AppTextStyles.cardTitle,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _buildSubtitle(),
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _buildHpBar(),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          tooltip: 'Charakter löschen',
                          onPressed: onDelete,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildSubtitle() {
    final parts = <String>[];
    if (character.characterClass.isNotEmpty) {
      final classEntry = character.subclass.isNotEmpty
          ? '${character.characterClass} (${character.subclass})'
          : character.characterClass;
      parts.add(classEntry);
    }
    if (character.race.isNotEmpty) parts.add(character.race);
    parts.add('Stufe ${character.level}');
    return parts.join(' · ');
  }

  Widget _buildHpBar() {
    final ratio = character.maxHitPoints > 0
        ? character.currentHitPoints / character.maxHitPoints
        : 0.0;
    final color = AppColors.hpColor(ratio);

    return Row(
      children: [
        Text(
          'TP: ${character.currentHitPoints}/${character.maxHitPoints}',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ),
      ],
    );
  }
}