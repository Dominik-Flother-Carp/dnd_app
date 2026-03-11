// lib/screens/compendium/compendium_screen.dart

import 'package:flutter/material.dart';
import 'package:dnd_app/models/item.dart';
import 'package:dnd_app/models/spell.dart';
import 'package:dnd_app/services/compendium_service.dart';
import 'package:dnd_app/screens/compendium/compendium_detail_sheet.dart';
import 'package:dnd_app/theme/app_text_styles.dart';

class CompendiumScreen extends StatefulWidget {
  const CompendiumScreen({super.key});

  @override
  State<CompendiumScreen> createState() => _CompendiumScreenState();
}

class _CompendiumScreenState extends State<CompendiumScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _service = CompendiumService();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    await _service.load();
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kompendium',
          style: AppTextStyles.cardTitle.copyWith(
            color: const Color(0xFFF5DEB3),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.backpack_outlined), text: 'Gegenstände'),
            Tab(icon: Icon(Icons.auto_fix_high), text: 'Zauber'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _ItemsTab(service: _service),
                _SpellsTab(service: _service),
              ],
            ),
    );
  }
}

// ── Gegenstände-Tab ───────────────────────────────────────────────────────────

class _ItemsTab extends StatefulWidget {
  final CompendiumService service;
  const _ItemsTab({required this.service});

  @override
  State<_ItemsTab> createState() => _ItemsTabState();
}

class _ItemsTabState extends State<_ItemsTab> {
  final _searchController = TextEditingController();
  ItemCategory? _selectedCategory;
  List<Item> _results = [];

  @override
  void initState() {
    super.initState();
    _results = widget.service.items;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() => _filter();

  void _filter() {
    setState(() {
      _results = widget.service.searchItems(
        _searchController.text,
        category: _selectedCategory,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Suchleiste + Kategoriefilter ────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Suchen…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _filter();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              // Kategorie-Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _CategoryChip(
                      label: 'Alle',
                      selected: _selectedCategory == null,
                      onTap: () => setState(() {
                        _selectedCategory = null;
                        _filter();
                      }),
                    ),
                    ...ItemCategory.values
                        .where(
                          (cat) =>
                              cat != ItemCategory.treasure &&
                              cat != ItemCategory.misc,
                        )
                        .map(
                          (cat) => _CategoryChip(
                            label: cat.label,
                            icon: cat.icon,
                            selected: _selectedCategory == cat,
                            onTap: () => setState(() {
                              _selectedCategory = _selectedCategory == cat
                                  ? null
                                  : cat;
                              _filter();
                            }),
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // ── Ergebnisliste ───────────────────────────────────────────────
        Expanded(
          child: _results.isEmpty
              ? _buildEmpty('Keine Gegenstände gefunden')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                  itemCount: _results.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (context, i) => _ItemTile(item: _results[i]),
                ),
        ),
      ],
    );
  }
}

class _ItemTile extends StatelessWidget {
  final Item item;
  const _ItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: item.rarity.color.withValues(alpha: 0.15),
        child: Icon(item.category.icon, color: item.rarity.color, size: 20),
      ),
      title: Text(item.name, style: AppTextStyles.body),
      subtitle: Text(
        _subtitle,
        style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600]),
      ),
      trailing: item.isMagical
          ? Icon(Icons.auto_awesome, size: 14, color: Colors.purple[300])
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      tileColor: Theme.of(context).cardColor,
      onTap: () => showItemDetailSheet(context, item),
    );
  }

  String get _subtitle {
    final parts = <String>[item.category.label];
    if (item is WeaponItem) {
      final w = item as WeaponItem;
      parts.add('${w.damageDice} ${w.damageType}');
    } else if (item is ArmorItem) {
      parts.add('RK ${(item as ArmorItem).armorClassBonus}');
    } else if (item is ShieldItem) {
      parts.add('+${(item as ShieldItem).armorClassBonus} RK');
    }
    return parts.join(' · ');
  }
}

// ── Zauber-Tab ────────────────────────────────────────────────────────────────

class _SpellsTab extends StatefulWidget {
  final CompendiumService service;
  const _SpellsTab({required this.service});

  @override
  State<_SpellsTab> createState() => _SpellsTabState();
}

class _SpellsTabState extends State<_SpellsTab> {
  final _searchController = TextEditingController();
  List<Spell> _results = [];

  @override
  void initState() {
    super.initState();
    _results = widget.service.spells;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _results = widget.service.searchSpells(_searchController.text);
    });
  }

  // Zauber nach Grad gruppieren
  Map<int, List<Spell>> get _grouped {
    final map = <int, List<Spell>>{};
    for (final spell in _results) {
      map.putIfAbsent(spell.level, () => []).add(spell);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;
    final levels = grouped.keys.toList()..sort();

    return Column(
      children: [
        // ── Suchleiste ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Suchen…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
            ),
          ),
        ),
        // ── Ergebnisliste ───────────────────────────────────────────────
        Expanded(
          child: _results.isEmpty
              ? _buildEmpty('Keine Zauber gefunden')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  itemCount: levels.fold(
                    0,
                    (sum, lvl) => sum! + 1 + (grouped[lvl]?.length ?? 0),
                  ),
                  itemBuilder: (context, index) {
                    // Index auf Abschnitt und Eintrag mappen
                    int running = 0;
                    for (final lvl in levels) {
                      if (index == running) {
                        // Abschnittsheader
                        return _LevelHeader(level: lvl);
                      }
                      running++;
                      final spells = grouped[lvl]!;
                      if (index < running + spells.length) {
                        return _SpellTile(spell: spells[index - running]);
                      }
                      running += spells.length;
                    }
                    return const SizedBox.shrink();
                  },
                ),
        ),
      ],
    );
  }
}

class _LevelHeader extends StatelessWidget {
  final int level;
  const _LevelHeader({required this.level});

  @override
  Widget build(BuildContext context) {
    final label = level == 0 ? 'Zaubertricks' : '$level. Grad';
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 0, 6),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.grey[500],
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SpellTile extends StatelessWidget {
  final Spell spell;
  const _SpellTile({required this.spell});

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

  String get _schoolLabel {
    switch (spell.school) {
      case SpellSchool.abjuration:
        return 'Bannmagie';
      case SpellSchool.conjuration:
        return 'Beschwörung';
      case SpellSchool.divination:
        return 'Divination';
      case SpellSchool.enchantment:
        return 'Verzauberung';
      case SpellSchool.evocation:
        return 'Evokation';
      case SpellSchool.illusion:
        return 'Illusion';
      case SpellSchool.necromancy:
        return 'Nekromantie';
      case SpellSchool.transmutation:
        return 'Verwandlung';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: _schoolColor.withValues(alpha: 0.15),
        child: Icon(Icons.auto_fix_high, color: _schoolColor, size: 18),
      ),
      title: Text(spell.name, style: AppTextStyles.body),
      subtitle: Text(
        [
          _schoolLabel,
          spell.castingTime,
          if (spell.concentration) 'Konz.',
          if (spell.ritual) 'Ritual',
        ].join(' · '),
        style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600]),
      ),
      trailing: spell.dealsDamage
          ? Text(
              spell.damageDice!,
              style: AppTextStyles.labelXs.copyWith(color: Colors.red[400]),
            )
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      tileColor: Theme.of(context).cardColor,
      onTap: () => showSpellDetailSheet(context, spell),
    );
  }
}

// ── Gemeinsame Hilfswidgets ───────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? color : Colors.grey[400]!,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 12,
                  color: selected ? color : Colors.grey[600],
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: AppTextStyles.labelXs.copyWith(
                  color: selected ? color : Colors.grey[600],
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildEmpty(String message) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.search_off, size: 48, color: Colors.grey[300]),
        const SizedBox(height: 12),
        Text(
          message,
          style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[400]),
        ),
      ],
    ),
  );
}
