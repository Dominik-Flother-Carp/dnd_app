// lib/screens/character_sheet/tabs/inventory_tab.dart

import 'package:flutter/material.dart';
import 'package:dnd_app/models/character.dart';
import 'package:dnd_app/models/item.dart';
import 'package:dnd_app/models/character_items.dart';
import 'package:dnd_app/repositories/item_repository.dart';
import 'package:dnd_app/theme/app_text_styles.dart';

const _equippableCategories = {
  ItemCategory.weapon,
  ItemCategory.armor,
  ItemCategory.shield,
};

// ── Rückgabewert des Dialogs ──────────────────────────────────────────────────

class _ItemDialogResult {
  final Item item;
  final CharacterItem ci;
  final bool isNew;
  final bool remove;

  const _ItemDialogResult({
    required this.item,
    required this.ci,
    required this.isNew,
    required this.remove,
  });
}

// ── Dialog-Widget ─────────────────────────────────────────────────────────────

class _ItemDialog extends StatefulWidget {
  final CharacterItem? characterItem;
  final String characterId;
  final Color themeColor;
  final int currentAttuneCount;

  const _ItemDialog({
    required this.characterId,
    required this.themeColor,
    required this.currentAttuneCount,
    this.characterItem,
  });

  @override
  State<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<_ItemDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _weightController;
  late final TextEditingController _valueController;
  late final TextEditingController _damageDiceController;

  late ItemCategory _selectedCategory;
  late ItemRarity _selectedRarity;
  late bool _requiresAttunement;
  late bool _isEquipped;
  late bool _isAttuned;

  bool get _isNew => widget.characterItem == null;

  @override
  void initState() {
    super.initState();
    final item = widget.characterItem?.item;
    _nameController       = TextEditingController(text: item?.name ?? '');
    _descController       = TextEditingController(text: item?.description ?? '');
    _weightController     = TextEditingController(text: item != null ? '${item.weight}' : '0');
    _valueController      = TextEditingController(text: item != null ? '${item.valueInCopper}' : '0');
    _damageDiceController = TextEditingController(text: item?.damageDice ?? '');

    _selectedCategory   = item?.category ?? ItemCategory.misc;
    _selectedRarity     = item?.rarity ?? ItemRarity.common;
    _requiresAttunement = item?.requiresAttunement ?? false;
    _isEquipped         = widget.characterItem?.isEquipped ?? false;
    _isAttuned          = widget.characterItem?.isAttuned ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _weightController.dispose();
    _valueController.dispose();
    _damageDiceController.dispose();
    super.dispose();
  }

  void _onCategoryChanged(ItemCategory newCat) {
    setState(() {
      _selectedCategory = newCat;
      if (!_equippableCategories.contains(newCat)) {
        _isEquipped = false;
      }
    });
  }

  void _onSave() {
    if (_nameController.text.trim().isEmpty) return;

    final showEquipped = _equippableCategories.contains(_selectedCategory);

    final updatedItem = _isNew
        ? Item(
            name: _nameController.text.trim(),
            description: _descController.text.trim(),
            isCustom: true,
            category: _selectedCategory,
            rarity: _selectedRarity,
            weight: double.tryParse(_weightController.text) ?? 0,
            valueInCopper: int.tryParse(_valueController.text) ?? 0,
            damageDice: _selectedCategory == ItemCategory.weapon &&
                    _damageDiceController.text.trim().isNotEmpty
                ? _damageDiceController.text.trim()
                : null,
            requiresAttunement: _requiresAttunement,
          )
        : widget.characterItem!.item
      ..name = _nameController.text.trim()
      ..description = _descController.text.trim()
      ..category = _selectedCategory
      ..rarity = _selectedRarity
      ..weight = double.tryParse(_weightController.text) ?? 0
      ..valueInCopper = int.tryParse(_valueController.text) ?? 0
      ..damageDice = _selectedCategory == ItemCategory.weapon &&
              _damageDiceController.text.trim().isNotEmpty
          ? _damageDiceController.text.trim()
          : null
      ..requiresAttunement = _requiresAttunement;

    final updatedCi = _isNew
        ? CharacterItem(
            characterId: widget.characterId,
            item: updatedItem,
            quantity: 1,
            isEquipped: showEquipped && _isEquipped,
            isAttuned: _requiresAttunement && _isAttuned,
          )
        : widget.characterItem!
      ..isEquipped = showEquipped && _isEquipped
      ..isAttuned = _requiresAttunement && _isAttuned;

    Navigator.pop(
      context,
      _ItemDialogResult(
        item: updatedItem,
        ci: updatedCi,
        isNew: _isNew,
        remove: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showEquipped = _equippableCategories.contains(_selectedCategory);

    return AlertDialog(
      title: Text(
        _isNew ? 'Gegenstand hinzufügen' : 'Gegenstand bearbeiten',
        style: AppTextStyles.sectionTitle,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              style: AppTextStyles.body,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              autofocus: _isNew,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ItemCategory>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Kategorie',
                border: OutlineInputBorder(),
              ),
              items: ItemCategory.values
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.label, style: AppTextStyles.body),
                      ))
                  .toList(),
              onChanged: (v) => _onCategoryChanged(v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ItemRarity>(
              initialValue: _selectedRarity,
              decoration: const InputDecoration(
                labelText: 'Seltenheit',
                border: OutlineInputBorder(),
              ),
              items: ItemRarity.values
                  .map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(r.label, style: AppTextStyles.body),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedRarity = v!),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
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
                    controller: _valueController,
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
            if (_selectedCategory == ItemCategory.weapon) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _damageDiceController,
                style: AppTextStyles.body,
                decoration: const InputDecoration(
                  labelText: 'Schadenswürfel (z.B. 1w8)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            if (showEquipped) ...[
              const SizedBox(height: 4),
              SwitchListTile(
                value: _isEquipped,
                activeThumbColor: widget.themeColor,
                title: Text('Ausgerüstet', style: AppTextStyles.body),
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => setState(() => _isEquipped = v),
              ),
            ],
            SwitchListTile(
              value: _requiresAttunement,
              activeThumbColor: widget.themeColor,
              title: Text('Erfordert Einstimmung', style: AppTextStyles.body),
              contentPadding: EdgeInsets.zero,
              onChanged: (v) => setState(() {
                _requiresAttunement = v;
                if (!v) _isAttuned = false;
              }),
            ),
            if (_requiresAttunement)
              SwitchListTile(
                value: _isAttuned,
                activeThumbColor: widget.themeColor,
                title: Text('Eingestimmt', style: AppTextStyles.body),
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => setState(() {
                  if (v &&
                      widget.currentAttuneCount >= 3 &&
                      widget.characterItem?.isAttuned != true) {
                    return;
                  }
                  _isAttuned = v;
                }),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Abbrechen', style: AppTextStyles.body),
        ),
        SizedBox(
          width: 10,
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: widget.themeColor),
          onPressed: _onSave,
          child: Text('Speichern', style: AppTextStyles.body),
        ),])
      ],
    );
  }
}

// ── Haupt-Tab ─────────────────────────────────────────────────────────────────

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

  double get _totalWeight =>
      _items.fold(0.0, (sum, ci) => sum + ci.totalWeight);

  int get _attuneCount => _items.where((ci) => ci.isAttuned).length;

  Map<ItemCategory, List<CharacterItem>> get _grouped {
    final map = <ItemCategory, List<CharacterItem>>{};
    for (final ci in _items) {
      map.putIfAbsent(ci.item.category, () => []).add(ci);
    }
    return {
      for (final cat in ItemCategory.values)
        if (map.containsKey(cat)) cat: map[cat]!,
    };
  }

  Future<void> _showItemDialog({CharacterItem? characterItem}) async {
    final result = await showDialog<_ItemDialogResult>(
      context: context,
      builder: (_) => _ItemDialog(
        characterId: widget.character.id,
        themeColor: widget.themeColor,
        currentAttuneCount: _attuneCount,
        characterItem: characterItem,
      ),
    );

    if (result == null) return;

    if (result.remove) {
      await _repository.removeItemFromCharacter(result.ci);
    } else if (result.isNew) {
      await _repository.addItemToCharacter(result.ci);
    } else {
      await _saveItem(result.ci);
    }

    await _loadItems();
  }

  Future<void> _updateQuantity(CharacterItem ci, int newQuantity) async {
    await _repository.updateQuantity(ci, newQuantity);
    await _loadItems();
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
        ...grouped.entries.map((e) => _buildCategorySection(e.key, e.value)),
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
        InkWell(
          onTap: () =>
              setState(() => _categoryExpanded[category] = !isExpanded),
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
                  style: AppTextStyles.bodySmall
                      .copyWith(color: Colors.grey[400]),
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
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(item.name, style: AppTextStyles.cardTitle),
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
                              style: AppTextStyles.labelXs
                                  .copyWith(color: widget.themeColor),
                            ),
                          ),
                        if (ci.isAttuned)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Eingestimmt',
                              style: AppTextStyles.labelXs
                                  .copyWith(color: Colors.purple),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        item.rarity.label,
                        if (item.weight > 0) '${item.weight} lb',
                        '×${ci.quantity}',
                      ].join(' · '),
                      style: AppTextStyles.bodySmall
                          .copyWith(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (ci.quantity > 1)
                    GestureDetector(
                      onTap: () => _updateQuantity(ci, ci.quantity - 1),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: widget.themeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.remove, size: 25),
                      ),
                    ),
                    if (ci.quantity == 1)
                     GestureDetector(
                      onTap: () => _updateQuantity(ci, ci.quantity - 1),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: widget.themeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Entfernen', style: AppTextStyles.body.copyWith(color: Colors.black),),
                      ),
                    ),
                  const SizedBox(width: 4),
                  ],
                ),
                GestureDetector(
                  onTap: () => _updateQuantity(ci, ci.quantity + 1),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: widget.themeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.add, size: 25),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}