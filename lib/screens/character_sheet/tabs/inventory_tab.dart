// lib/screens/character_sheet/tabs/inventory_tab.dart

import 'package:flutter/material.dart';
import 'package:dnd_app/models/character.dart';
import 'package:dnd_app/models/item.dart';
import 'package:dnd_app/models/character_items.dart';
import 'package:dnd_app/repositories/item_repository.dart';
import 'package:dnd_app/theme/app_text_styles.dart';

// Kategorien bei denen "Ausgerüstet" sinnvoll ist
const _equippableCategories = {
  ItemCategory.weapon,
  ItemCategory.armor,
  ItemCategory.shield,
};

class InventoryTab extends StatefulWidget {
  final Character character;
  final Color themeColor;

  const InventoryTab({
    super.key,
    required this.character,
    required this.themeColor,
  });

  @override
  State<InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends State<InventoryTab>
    with AutomaticKeepAliveClientMixin {
  final ItemRepository _repository = ItemRepository();

  List<CharacterItem> _items = [];
  bool _isLoading = true;

  // Collapsed-State pro Kategorie – neue Kategorien starten aufgeklappt
  final Map<ItemCategory, bool> _categoryExpanded = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await _repository.getItemsForCharacter(widget.character.id);
    if (mounted) {
      setState(() {
        _items = items;
        _isLoading = false;
        // Neue Kategorien die noch keinen State haben → aufgeklappt
        for (final ci in items) {
          _categoryExpanded.putIfAbsent(ci.item.category, () => true);
        }
      });
    }
  }

  Future<void> _saveItem(CharacterItem characterItem) async {
    await _repository.updateCharacterItem(characterItem);
    await _repository.updateItem(characterItem.item);
  }

  // ── Gewicht ───────────────────────────────────────────────────────────────

  double get _totalWeight =>
      _items.fold(0.0, (sum, ci) => sum + ci.totalWeight);

  int get _attuneCount => _items.where((ci) => ci.isAttuned).length;

  // ── Gruppierung ───────────────────────────────────────────────────────────

  Map<ItemCategory, List<CharacterItem>> get _grouped {
    final map = <ItemCategory, List<CharacterItem>>{};
    for (final ci in _items) {
      map.putIfAbsent(ci.item.category, () => []).add(ci);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        _items.isEmpty ? _buildEmptyState() : _buildList(),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            backgroundColor: widget.themeColor,
            foregroundColor: const Color(0xFFF5DEB3),
            onPressed: () => _showItemDialog(),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.backpack_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Kein Inventar',
            style: AppTextStyles.sectionTitle.copyWith(color: Colors.grey[400]),
          ),
          const SizedBox(height: 8),
          Text(
            'Tippe auf + um einen Gegenstand hinzuzufügen.',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final grouped = _grouped;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        _buildSummaryCard(),
        const SizedBox(height: 16),
        ...grouped.entries.map((entry) => _buildCategorySection(
              entry.key,
              entry.value,
            )),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildSummaryStat(
              label: 'Gesamtgewicht',
              value: '${_totalWeight.toStringAsFixed(1)} lb',
              icon: Icons.scale,
            ),
            _buildSummaryStat(
              label: 'Einstimmungen',
              value: '$_attuneCount / 3',
              icon: Icons.auto_awesome,
              color: _attuneCount >= 3 ? Colors.red : widget.themeColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStat({
    required String label,
    required String value,
    required IconData icon,
    Color? color,
  }) {
    final c = color ?? widget.themeColor;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: c, size: 20),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.statMedium.copyWith(color: c)),
          Text(label, style: AppTextStyles.labelXs),
        ],
      ),
    );
  }

  Widget _buildCategorySection(
      ItemCategory category, List<CharacterItem> items) {
    final isExpanded = _categoryExpanded[category] ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kategorie-Header – tippbar zum Auf-/Zuklappen
        InkWell(
          onTap: () => setState(
              () => _categoryExpanded[category] = !isExpanded),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
            child: Row(
              children: [
                Icon(category.icon, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  category.label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${items.length})',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey[400],
                  ),
                ),
                const Spacer(),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: Colors.grey[500],
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[
          ...items.map((ci) => _buildItemTile(ci)),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildItemTile(CharacterItem ci) {
    final item = ci.item;
    final rarityColor = item.rarity.color;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showItemDialog(characterItem: ci),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: rarityColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(item.name,
                              style: AppTextStyles.cardTitle),
                        ),
                        if (ci.isEquipped)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: widget.themeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Ausgerüstet',
                              style: AppTextStyles.labelXs.copyWith(
                                color: widget.themeColor,
                              ),
                            ),
                          ),
                        if (ci.isAttuned) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Eingestimmt',
                              style: AppTextStyles.labelXs.copyWith(
                                color: Colors.purple,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        item.rarity.label,
                        if (item.weight > 0) '${item.weight} lb',
                        if (ci.quantity > 1) '×${ci.quantity}',
                      ].join(' · '),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => _updateQuantity(ci, ci.quantity - 1),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.remove, size: 16),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _updateQuantity(ci, ci.quantity + 1),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.add, size: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateQuantity(CharacterItem ci, int newQuantity) async {
    await _repository.updateQuantity(ci, newQuantity);
    await _loadItems();
  }

  // ── Dialog ────────────────────────────────────────────────────────────────

  Future<void> _showItemDialog({CharacterItem? characterItem}) async {
    final isNew = characterItem == null;

    final nameController = TextEditingController(
        text: isNew ? '' : characterItem.item.name);
    final descController = TextEditingController(
        text: isNew ? '' : characterItem.item.description);
    final weightController = TextEditingController(
        text: isNew ? '0' : '${characterItem.item.weight}');
    final valueController = TextEditingController(
        text: isNew ? '0' : '${characterItem.item.valueInCopper}');
    final damageDiceController = TextEditingController(
        text: isNew ? '' : (characterItem.item.damageDice ?? ''));

    DateTime? lastRemoveTap;

    try {
      final result = await showDialog<({
        Item item,
        CharacterItem ci,
        bool isNew,
        bool remove,
      })>(
        context: context,
        builder: (dialogContext) {
          var selectedCategory =
              characterItem?.item.category ?? ItemCategory.misc;
          var selectedRarity =
              characterItem?.item.rarity ?? ItemRarity.common;
          var requiresAttunement =
              characterItem?.item.requiresAttunement ?? false;
          var isEquipped = characterItem?.isEquipped ?? false;
          var isAttuned = characterItem?.isAttuned ?? false;

          return StatefulBuilder(
            builder: (context, setDialogState) {
              final showEquipped =
                  _equippableCategories.contains(selectedCategory);

              void onCategoryChanged(ItemCategory newCat) {
                setDialogState(() {
                  selectedCategory = newCat;
                  if (!_equippableCategories.contains(newCat)) {
                    isEquipped = false;
                  }
                });
              }

              return AlertDialog(
                title: Text(
                  isNew
                      ? 'Gegenstand hinzufügen'
                      : 'Gegenstand bearbeiten',
                  style: AppTextStyles.sectionTitle,
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameController,
                        style: AppTextStyles.body,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                        ),
                        autofocus: isNew,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<ItemCategory>(
                        initialValue: selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Kategorie',
                          border: OutlineInputBorder(),
                        ),
                        items: ItemCategory.values
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c.label,
                                      style: AppTextStyles.body),
                                ))
                            .toList(),
                        onChanged: (v) => onCategoryChanged(v!),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<ItemRarity>(
                        initialValue: selectedRarity,
                        decoration: const InputDecoration(
                          labelText: 'Seltenheit',
                          border: OutlineInputBorder(),
                        ),
                        items: ItemRarity.values
                            .map((r) => DropdownMenuItem(
                                  value: r,
                                  child: Text(r.label,
                                      style: AppTextStyles.body),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setDialogState(() => selectedRarity = v!),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: weightController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              style: AppTextStyles.body,
                              decoration: const InputDecoration(
                                labelText: 'Gewicht (lb)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: valueController,
                              keyboardType: TextInputType.number,
                              style: AppTextStyles.body,
                              decoration: const InputDecoration(
                                labelText: 'Wert (KP)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (selectedCategory == ItemCategory.weapon) ...[
                        TextField(
                          controller: damageDiceController,
                          style: AppTextStyles.body,
                          decoration: const InputDecoration(
                            labelText: 'Schadenswürfel (z.B. 1d8)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (showEquipped)
                        SwitchListTile(
                          value: isEquipped,
                          activeThumbColor: widget.themeColor,
                          title: Text('Ausgerüstet',
                              style: AppTextStyles.body),
                          contentPadding: EdgeInsets.zero,
                          onChanged: (v) =>
                              setDialogState(() => isEquipped = v),
                        ),
                      if (requiresAttunement)
                        SwitchListTile(
                          value: isAttuned,
                          activeThumbColor: widget.themeColor,
                          title: Text('Eingestimmt',
                              style: AppTextStyles.body),
                          contentPadding: EdgeInsets.zero,
                          onChanged: (v) => setDialogState(() {
                            if (v &&
                                _attuneCount >= 3 &&
                                characterItem?.isAttuned != true) return;
                            isAttuned = v;
                          }),
                        ),
                      const SizedBox(height: 12),
                      // Beschreibung: Label oben links ausgerichtet
                      TextField(
                        controller: descController,
                        style: AppTextStyles.body,
                        maxLines: 3,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(
                          labelText: 'Beschreibung',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  if (!isNew)
                    StatefulBuilder(
                      builder: (context, setRemoveState) {
                        final isArmed = lastRemoveTap != null &&
                            DateTime.now().difference(lastRemoveTap!) <
                                const Duration(milliseconds: 800);
                        return TextButton(
                          onPressed: () {
                            final now = DateTime.now();
                            final isDoubleTap = lastRemoveTap != null &&
                                now.difference(lastRemoveTap!) <
                                    const Duration(milliseconds: 800);
                            if (isDoubleTap) {
                              Navigator.pop(
                                context,
                                (
                                  item: characterItem.item,
                                  ci: characterItem,
                                  isNew: false,
                                  remove: true,
                                ),
                              );
                            } else {
                              lastRemoveTap = now;
                              setRemoveState(() {});
                            }
                          },
                          child: Text(
                            isArmed ? 'Bestätigen?' : 'Entfernen',
                            style: AppTextStyles.body.copyWith(
                              color: isArmed
                                  ? Colors.orange
                                  : Colors.red,
                            ),
                          ),
                        );
                      },
                    ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Abbrechen', style: AppTextStyles.body),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: widget.themeColor),
                    onPressed: () {
                      if (nameController.text.trim().isEmpty) return;

                      final showEquippedFinal =
                          _equippableCategories.contains(selectedCategory);

                      final updatedItem = isNew
                          ? Item(
                              name: nameController.text.trim(),
                              description: descController.text.trim(),
                              isCustom: true,
                              category: selectedCategory,
                              rarity: selectedRarity,
                              weight: double.tryParse(
                                      weightController.text) ??
                                  0,
                              valueInCopper:
                                  int.tryParse(valueController.text) ??
                                      0,
                              damageDice: selectedCategory ==
                                          ItemCategory.weapon &&
                                      damageDiceController.text
                                          .trim()
                                          .isNotEmpty
                                  ? damageDiceController.text.trim()
                                  : null,
                            )
                          : characterItem.item
                        ..name = nameController.text.trim()
                        ..description = descController.text.trim()
                        ..category = selectedCategory
                        ..rarity = selectedRarity
                        ..weight =
                            double.tryParse(weightController.text) ?? 0
                        ..valueInCopper =
                            int.tryParse(valueController.text) ?? 0
                        ..damageDice = selectedCategory ==
                                    ItemCategory.weapon &&
                                damageDiceController.text.trim().isNotEmpty
                            ? damageDiceController.text.trim()
                            : null;

                      final updatedCi = isNew
                          ? CharacterItem(
                              characterId: widget.character.id,
                              item: updatedItem,
                              quantity: 1,
                              isEquipped: showEquippedFinal && isEquipped,
                              isAttuned: requiresAttunement && isAttuned,
                            )
                          : characterItem
                        ..isEquipped = showEquippedFinal && isEquipped
                        ..isAttuned = requiresAttunement && isAttuned;

                      Navigator.pop(
                        context,
                        (
                          item: updatedItem,
                          ci: updatedCi,
                          isNew: isNew,
                          remove: false,
                        ),
                      );
                    },
                    child: Text('Speichern', style: AppTextStyles.body),
                  ),
                ],
              );
            },
          );
        },
      );

      // ── Async-Logik außerhalb des Dialogs ─────────────────────────────────
      if (result == null) return;

      if (result.remove) {
        await _repository.removeItemFromCharacter(result.ci);
      } else if (result.isNew) {
        await _repository.addItemToCharacter(result.ci);
      } else {
        await _saveItem(result.ci);
      }

      await _loadItems();
    } finally {
      nameController.dispose();
      descController.dispose();
      weightController.dispose();
      valueController.dispose();
      damageDiceController.dispose();
    }
  }
}