// lib/screens/character_sheet/tabs/dialogs/compendium_picker_sheet.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dnd_app/models/item.dart';
import 'package:dnd_app/services/compendium_service.dart';
import 'package:dnd_app/theme/app_text_styles.dart';

class CompendiumPickerSheet extends StatefulWidget {
  final Color themeColor;

  const CompendiumPickerSheet({super.key, required this.themeColor});

  @override
  State<CompendiumPickerSheet> createState() => _CompendiumPickerSheetState();
}

class _CompendiumPickerSheetState extends State<CompendiumPickerSheet> {
  final _searchCtrl = TextEditingController();
  final _service    = CompendiumService();

  List<Item> _results    = [];
  bool       _loading    = true;
  ItemCategory? _filterCategory;

  // Debounce-Timer: verhindert Filterung bei jedem einzelnen Tastendruck
  Timer? _debounce;

  static const _pickerCategories = [
    ItemCategory.weapon,
    ItemCategory.armor,
    ItemCategory.shield,
    ItemCategory.tool,
    ItemCategory.gear,
    ItemCategory.consumable,
  ];

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_onSearchDebounced);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.removeListener(_onSearchDebounced);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await _service.load();
    _onSearch();
  }

  void _onSearchDebounced() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () {
      if (mounted) _onSearch();
    });
  }

  void _onSearch() {
    final results = _service.searchItems(
      _searchCtrl.text,
      category: _filterCategory,
    );
    if (mounted) {
      setState(() {
        _results = results;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollCtrl) {
        return Column(
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text('Kompendium', style: AppTextStyles.sectionTitle),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  hintText: 'Gegenstand suchen…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _searchCtrl.clear,
                        )
                      : null,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _filterChip(null, 'Alle'),
                  ..._pickerCategories.map((c) => _filterChip(c, c.label)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                      ? Center(
                          child: Text(
                            'Keine Gegenstände gefunden',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: Colors.grey),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: _results.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 4),
                          itemBuilder: (_, i) =>
                              _buildResultTile(_results[i]),
                        ),
            ),
          ],
        );
      },
    );
  }

  Widget _filterChip(ItemCategory? cat, String label) {
    final selected = _filterCategory == cat;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: AppTextStyles.bodySmall),
        selected: selected,
        selectedColor: widget.themeColor.withValues(alpha: 0.15),
        checkmarkColor: widget.themeColor,
        onSelected: (_) => setState(() {
          _filterCategory = selected ? null : cat;
          _onSearch();
        }),
      ),
    );
  }

  Widget _buildResultTile(Item item) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Icon(item.category.icon, color: Colors.grey[600], size: 20),
        title: Text(item.name, style: AppTextStyles.cardTitle),
        subtitle: Text(
          [
            item.category.label,
            if (item is WeaponItem) item.damageDice,
            if (item is ArmorItem)  'RK ${item.armorClassBonus}',
            item.valueDisplay,
          ].join(' · '),
          style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[500]),
        ),
        trailing: const Icon(Icons.add_circle_outline, size: 22),
        onTap: () => Navigator.pop(context, item),
      ),
    );
  }
}
