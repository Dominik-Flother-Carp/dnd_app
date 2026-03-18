// lib/screens/compendium/compendium_detail_sheet.dart

import 'package:flutter/material.dart';
import 'package:dnd_app/models/item.dart';
import 'package:dnd_app/models/spell.dart';
import 'package:dnd_app/models/enums.dart';
import 'package:dnd_app/theme/app_text_styles.dart';

// ── Einstiegspunkte ───────────────────────────────────────────────────────────

void showItemDetailSheet(BuildContext context, Item item) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ItemDetailSheet(item: item),
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

Widget _buildSection(String title, Widget content) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 16),
      Text(
        title,
        style: AppTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.grey[500],
          letterSpacing: 0.8,
        ),
      ),
      const SizedBox(height: 8),
      content,
    ],
  );
}

Widget _buildChip(String label, {Color? color}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: (color ?? Colors.grey).withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: (color ?? Colors.grey).withValues(alpha: 0.3)),
    ),
    child: Text(
      label,
      style: AppTextStyles.labelXs.copyWith(
        color: color ?? Colors.grey[700],
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

// ── Item-Detailsheet ──────────────────────────────────────────────────────────

class _ItemDetailSheet extends StatelessWidget {
  final Item item;
  const _ItemDetailSheet({required this.item});

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
                        _buildChip(item.category.label),
                        const SizedBox(width: 6),
                        _buildChip(item.rarity.label, color: item.rarity.color),
                        if (item.isMagical) ...[
                          const SizedBox(width: 6),
                          _buildChip('Magisch', color: Colors.purple),
                        ],
                        if (item.requiresAttunement) ...[
                          const SizedBox(width: 6),
                          _buildChip('Einstimmung', color: Colors.amber),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Basisdaten ─────────────────────────────────────────────────
          _buildSection(
            'Eigenschaften',
            Column(
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
            _buildSection(
              'Beschreibung',
              Text(item.description, style: AppTextStyles.body),
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
                      .map((p) => _buildChip(p.label))
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

  String get _schoolLabel => spell.school.label;

  Color get _schoolColor {
    switch (spell.school) {
      case SpellSchool.abjuration:
        return Colors.blue;
      case SpellSchool.conjuration:
        return Colors.yellow[700]!;
      case SpellSchool.divination:
        return Colors.cyan;
      case SpellSchool.enchantment:
        return Colors.pink;
      case SpellSchool.evocation:
        return Colors.orange;
      case SpellSchool.illusion:
        return Colors.purple;
      case SpellSchool.necromancy:
        return Colors.green[700]!;
      case SpellSchool.transmutation:
        return Colors.teal;
    }
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
              Icon(Icons.auto_fix_high, size: 28, color: _schoolColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(spell.name, style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildChip(_levelLabel),
                        const SizedBox(width: 6),
                        _buildChip(_schoolLabel, color: _schoolColor),
                        if (spell.concentration) ...[
                          const SizedBox(width: 6),
                          _buildChip('Konzentration', color: Colors.red),
                        ],
                        if (spell.ritual) ...[
                          const SizedBox(width: 6),
                          _buildChip('Ritual', color: Colors.teal),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Metadaten ──────────────────────────────────────────────────
          _buildSection(
            'Details',
            Column(
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
          _buildSection(
            'Beschreibung',
            Text(spell.effectDescription, style: AppTextStyles.body),
          ),

          // ── Auf höheren Graden ─────────────────────────────────────────
          if (spell.atHigherLevels != null &&
              spell.atHigherLevels!.trim().isNotEmpty)
            _buildSection(
              'Auf höheren Graden',
              Text(spell.atHigherLevels!.trim(), style: AppTextStyles.body),
            ),
        ],
      ),
    );
  }
}