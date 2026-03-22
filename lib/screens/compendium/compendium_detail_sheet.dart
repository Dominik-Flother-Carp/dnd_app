// lib/screens/compendium/compendium_detail_sheet.dart

import 'package:flutter/material.dart';
import 'package:dnd_app/models/item.dart';
import 'package:dnd_app/models/spell.dart';
import 'package:dnd_app/models/enums.dart';
import 'package:dnd_app/theme/app_text_styles.dart';
import 'package:dnd_app/theme/app_colors.dart';
import 'package:dnd_app/widgets/widget_utils.dart';

// ── Einstiegspunkte ───────────────────────────────────────────────────────────

void showItemDetailSheet(BuildContext context, Item item, {String? notes}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ItemDetailSheet(item: item, notes: notes),
  );
}

void showSpellDetailSheet(BuildContext context, Spell spell) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SpellDetailSheet(spell: spell),
  );
}

// ── Gemeinsame Hilfswidgets ───────────────────────────────────────────────────

class _SheetContainer extends StatelessWidget {
  final Widget child;
  const _SheetContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Ziehgriff
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildInfoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600]),
          ),
        ),
        Expanded(child: Text(value, style: AppTextStyles.bodySmall)),
      ],
    ),
  );
}

// ── Item-Detailsheet ──────────────────────────────────────────────────────────

class _ItemDetailSheet extends StatelessWidget {
  final Item item;
  final String? notes;

  const _ItemDetailSheet({required this.item, this.notes});

  @override
  Widget build(BuildContext context) {
    return _SheetContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Kopfzeile ──────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(item.category.icon, size: 28, color: item.rarity.color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        AppChip(label: item.category.label),
                        const SizedBox(width: 6),
                        AppChip(label: item.rarity.label, color: item.rarity.color),
                        if (item.isMagical) ...[
                          const SizedBox(width: 6),
                          AppChip(label: 'Magisch', color: Colors.purple),
                        ],
                        if (item.requiresAttunement) ...[
                          const SizedBox(width: 6),
                          AppChip(label: 'Einstimmung', color: Colors.amber),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Basisdaten ─────────────────────────────────────────────────
          DetailSection(
              title: 'Eigenschaften',
              child: Column(
              children: [
                if (item.weight > 0)
                  _buildInfoRow('Gewicht', '${item.weight} lb'),
                _buildInfoRow('Wert', item.valueDisplay),
                if (item.magicBonus > 0)
                  _buildInfoRow('Magischer Bonus', '+${item.magicBonus}'),
                // Waffe
                if (item is WeaponItem) ..._weaponRows(item as WeaponItem),
                // Rüstung
                if (item is ArmorItem) ..._armorRows(item as ArmorItem),
                // Schild
                if (item is ShieldItem)
                  _buildInfoRow(
                    'RK-Bonus',
                    '+${(item as ShieldItem).armorClassBonus}',
                  ),
              ],
            ),
          ),

          // ── Beschreibung ───────────────────────────────────────────────
          if (item.description.isNotEmpty)
            DetailSection(
                title: 'Beschreibung',
                child: Text(item.description, style: AppTextStyles.body),
            ),

          // ── Charakter-Notiz ────────────────────────────────────────────
          if (notes != null && notes!.isNotEmpty)
            DetailSection(
                title: 'Notiz',
                child: Text(notes!, style: AppTextStyles.body),
            ),
        ],
      ),
    );
  }

  List<Widget> _weaponRows(WeaponItem w) {
    final rows = <Widget>[
      _buildInfoRow(
        'Typ',
        w.weaponCategory == WeaponCategory.simple
            ? 'Einfache Waffe'
            : 'Kriegswaffe',
      ),
      _buildInfoRow('Schaden', '${w.damageDice} ${w.damageType}'),
    ];

    if (w.versatileDice != null) {
      rows.add(_buildInfoRow('Vielseitig', w.versatileDice!));
    }

    final isRanged =
        w.properties.contains(WeaponProperty.ranged) ||
        w.properties.contains(WeaponProperty.thrown);
    if (isRanged && w.rangeMax > 1) {
      rows.add(
        _buildInfoRow('Reichweite', '${w.rangeNormal} / ${w.rangeMax} m'),
      );
    }

    if (w.properties.isNotEmpty) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 130,
                child: Text(
                  'Eigenschaften',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ),
              Expanded(
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: w.properties
                      .map((p) => AppChip(label: p.label))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return rows;
  }

  List<Widget> _armorRows(ArmorItem a) {
    final rows = <Widget>[
      _buildInfoRow('Typ', a.armorType.label),
      _buildInfoRow('Rüstungsklasse', '${a.armorClassBonus}'),
    ];
    final dex = a.maxDexBonus;
    if (dex == -1) {
      rows.add(_buildInfoRow('Max. GES-Bonus', 'Unbegrenzt'));
    } else if (dex == 0) {
      rows.add(_buildInfoRow('Max. GES-Bonus', 'Kein Bonus'));
    } else {
      rows.add(_buildInfoRow('Max. GES-Bonus', '+$dex'));
    }

    if (a.minStrength > 0) {
      rows.add(_buildInfoRow('Mindest-Stärke', '${a.minStrength}'));
    }
    if (a.stealthDisadvantage) {
      rows.add(_buildInfoRow('Heimlichkeit', 'Nachteil'));
    }

    return rows;
  }
}

// ── Zauber-Detailsheet ────────────────────────────────────────────────────────

class _SpellDetailSheet extends StatelessWidget {
  final Spell spell;
  const _SpellDetailSheet({required this.spell});

  String get _levelLabel {
    if (spell.level == 0) return 'Zaubertrick';
    return '${spell.level}. Grad';
  }

  String get _savingThrowLabel {
    switch (spell.savingThrowAttribute) {
      case SavingThrowAttribute.strength:
        return 'STR';
      case SavingThrowAttribute.dexterity:
        return 'GES';
      case SavingThrowAttribute.constitution:
        return 'KON';
      case SavingThrowAttribute.intelligence:
        return 'INT';
      case SavingThrowAttribute.wisdom:
        return 'WEI';
      case SavingThrowAttribute.charisma:
        return 'CHA';
      case SavingThrowAttribute.none:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Kopfzeile ──────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_fix_high, size: 28,
                  color: AppColors.spellSchoolColor(spell.school)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(spell.name, style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        AppChip(label: _levelLabel),
                        const SizedBox(width: 6),
                        AppChip(label: spell.school.label,
                            color: AppColors.spellSchoolColor(spell.school)),
                        if (spell.concentration) ...[
                          const SizedBox(width: 6),
                          AppChip(label: 'Konzentration', color: Colors.red),
                        ],
                        if (spell.ritual) ...[
                          const SizedBox(width: 6),
                          AppChip(label: 'Ritual', color: Colors.teal),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Metadaten ──────────────────────────────────────────────────
          DetailSection(
              title: 'Details',
              child: Column(
              children: [
                _buildInfoRow('Zeitaufwand', spell.castingTime),
                _buildInfoRow('Reichweite', spell.range),
                _buildInfoRow('Wirkungsdauer', spell.duration),
                _buildInfoRow('Komponenten', spell.componentsDisplay),
                if (spell.dealsDamage)
                  _buildInfoRow(
                    'Schaden',
                    '${spell.damageDice} ${spell.damageType}',
                  ),
                if (spell.requiresAttackRoll)
                  _buildInfoRow(
                    'Angriffswurf',
                    spell.attackRollType == AttackRollType.melee
                        ? 'Nahkampf'
                        : 'Fernkampf',
                  ),
                if (spell.requiresSavingThrow)
                  _buildInfoRow('Rettungswurf', _savingThrowLabel),
              ],
            ),
          ),

          // ── Beschreibung ───────────────────────────────────────────────
          DetailSection(
              title: 'Beschreibung',
              child: Text(spell.effectDescription, style: AppTextStyles.body),
          ),

          // ── Auf höheren Graden ─────────────────────────────────────────
          if (spell.atHigherLevels != null &&
              spell.atHigherLevels!.trim().isNotEmpty)
            DetailSection(
                title: 'Auf höheren Graden',
                child: Text(spell.atHigherLevels!.trim(), style: AppTextStyles.body),
            ),
        ],
      ),
    );
  }
}