// lib/screens/character_sheet/tabs/inventory_tab.dart

import 'package:flutter/material.dart';
import 'package:dnd_app/models/character.dart';
import 'package:dnd_app/models/item.dart';
import 'package:dnd_app/models/character_items.dart';
import 'package:dnd_app/repositories/item_repository.dart';
import 'package:dnd_app/repositories/character_repository.dart';
import 'package:dnd_app/theme/app_text_styles.dart';

const _equippableCategories = {
  ItemCategory.weapon,
  ItemCategory.armor,
  ItemCategory.shield,
};

// ── Münz-Umrechnung ───────────────────────────────────────────────────────────
// Interner Speicher: Kupfermünzen (int), verlustfrei
// 1 PP = 1000 CP | 1 GP = 100 CP | 1 EP = 50 CP | 1 SP = 10 CP | 1 CP = 1 CP

const _cpPerPP = 1000;
const _cpPerGP = 100;
const _cpPerEP = 50;
const _cpPerSP = 10;
const _cpPerCP = 1;

int _coinToCopper(int amount, String coin) {
  switch (coin) {
    case 'PP': return amount * _cpPerPP;
    case 'GP': return amount * _cpPerGP;
    case 'EP': return amount * _cpPerEP;
    case 'SP': return amount * _cpPerSP;
    default:   return amount * _cpPerCP;
  }
}

/// Zerlegt einen CP-Wert in die größtmöglichen Münzen (PP→GP→EP→SP→CP).
Map<String, int> _breakdownCopper(int cp) {
  var rem = cp;
  final pp = rem ~/ _cpPerPP; rem -= pp * _cpPerPP;
  final gp = rem ~/ _cpPerGP; rem -= gp * _cpPerGP;
  final ep = rem ~/ _cpPerEP; rem -= ep * _cpPerEP;
  final sp = rem ~/ _cpPerSP; rem -= sp * _cpPerSP;
  return {'PP': pp, 'GP': gp, 'EP': ep, 'SP': sp, 'CP': rem};
}

/// Lesbare Münzkombination, lässt Null-Werte weg.
String _formatWallet(int totalCp) {
  if (totalCp <= 0) return '0 GP';
  final b = _breakdownCopper(totalCp);
  final parts = <String>[];
  for (final coin in ['PP', 'GP', 'EP', 'SP', 'CP']) {
    if (b[coin]! > 0) parts.add('${b[coin]} $coin');
  }
  return parts.join(' ');
}

/// GP-Wert mit zwei Nachkommastellen.
String _formatGP(int totalCp) {
  final gp = totalCp / _cpPerGP;
  if (gp == gp.truncateToDouble()) return '${gp.toInt()} GP';
  return '${gp.toStringAsFixed(2)} GP';
}

// ── Geldbeutel-Dialog ─────────────────────────────────────────────────────────

class _WalletDialogResult {
  final int newWalletCp;
  const _WalletDialogResult(this.newWalletCp);
}

class _WalletDialog extends StatefulWidget {
  final int walletCp;
  final Color themeColor;

  const _WalletDialog({required this.walletCp, required this.themeColor});

  @override
  State<_WalletDialog> createState() => _WalletDialogState();
}

class _WalletDialogState extends State<_WalletDialog> {
  final _controller = TextEditingController();
  String _selectedCoin = 'GP';
  bool _isIncome = true; // true = Einnahme, false = Ausgabe
  String? _errorText;

  static const _coins = ['PP', 'GP', 'EP', 'SP', 'CP'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onConfirm() {
    final amount = int.tryParse(_controller.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _errorText = 'Bitte eine gültige Zahl eingeben.');
      return;
    }
    final delta = _coinToCopper(amount, _selectedCoin);
    final newCp = _isIncome
        ? widget.walletCp + delta
        : widget.walletCp - delta;

    if (newCp < 0) {
      setState(() => _errorText =
          'Nicht genug Geld! Verfügbar: ${_formatWallet(widget.walletCp)}');
      return;
    }
    Navigator.pop(context, _WalletDialogResult(newCp));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Geldbeutel', style: AppTextStyles.sectionTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Aktueller Kontostand
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.themeColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kontostand',
                      style: AppTextStyles.labelXs
                          .copyWith(color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(
                    _formatGP(widget.walletCp),
                    style: AppTextStyles.statMedium
                        .copyWith(color: widget.themeColor),
                  ),
                  Text(
                    _formatWallet(widget.walletCp),
                    style: AppTextStyles.bodySmall
                        .copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Einnahme / Ausgabe Toggle
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _isIncome = true;
                      _errorText = null;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _isIncome
                            ? Colors.green.withValues(alpha: 0.15)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isIncome
                              ? Colors.green
                              : Colors.transparent,
                        ),
                      ),
                      child: Center(
                        child: Text('Einnahme',
                            style: AppTextStyles.body.copyWith(
                              color: _isIncome
                                  ? Colors.green
                                  : Colors.grey,
                              fontWeight: _isIncome
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            )),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _isIncome = false;
                      _errorText = null;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !_isIncome
                            ? Colors.red.withValues(alpha: 0.15)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: !_isIncome
                              ? Colors.red
                              : Colors.transparent,
                        ),
                      ),
                      child: Center(
                        child: Text('Ausgabe',
                            style: AppTextStyles.body.copyWith(
                              color: !_isIncome
                                  ? Colors.red
                                  : Colors.grey,
                              fontWeight: !_isIncome
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            )),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Betrag + Münzsorte
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    style: AppTextStyles.body,
                    onChanged: (_) =>
                        setState(() => _errorText = null),
                    decoration: InputDecoration(
                      labelText: 'Betrag',
                      border: const OutlineInputBorder(),
                      errorText: _errorText,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCoin,
                    decoration: const InputDecoration(
                      labelText: 'Sorte',
                      border: OutlineInputBorder(),
                    ),
                    items: _coins
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c, style: AppTextStyles.body),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _selectedCoin = v!;
                      _errorText = null;
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Abbrechen', style: AppTextStyles.body),
        ),
        FilledButton(
          onPressed: _onConfirm,
          style: FilledButton.styleFrom(
            backgroundColor: _isIncome ? Colors.green : Colors.red,
          ),
          child: Text(
            _isIncome ? 'Einnahme' : 'Ausgabe',
            style: AppTextStyles.body.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

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
    _damageDiceController = TextEditingController(text: item is WeaponItem ? (item).damageDice : '');

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
        ? (_selectedCategory == ItemCategory.weapon
            ? WeaponItem(
                name: _nameController.text.trim(),
                description: _descController.text.trim(),
                rarity: _selectedRarity,
                weight: double.tryParse(_weightController.text) ?? 0,
                valueInCopper: int.tryParse(_valueController.text) ?? 0,
                requiresAttunement: _requiresAttunement,
                damageDice: _damageDiceController.text.trim().isNotEmpty
                    ? _damageDiceController.text.trim() : '1W4',
                damageType: 'Hieb',
              )
            : Item(
                name: _nameController.text.trim(),
                description: _descController.text.trim(),
                category: _selectedCategory,
                rarity: _selectedRarity,
                weight: double.tryParse(_weightController.text) ?? 0,
                valueInCopper: int.tryParse(_valueController.text) ?? 0,
                requiresAttunement: _requiresAttunement,
              ))
        : widget.characterItem!.item
      ..name = _nameController.text.trim()
      ..description = _descController.text.trim()
      ..category = _selectedCategory
      ..rarity = _selectedRarity
      ..weight = double.tryParse(_weightController.text) ?? 0
      ..valueInCopper = int.tryParse(_valueController.text) ?? 0
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

  Future<void> _showWalletDialog() async {
    final result = await showDialog<_WalletDialogResult>(
      context: context,
      builder: (_) => _WalletDialog(
        walletCp: widget.character.walletInCopper,
        themeColor: widget.themeColor,
      ),
    );
    if (result == null || !mounted) return;
    setState(() => widget.character.walletInCopper = result.newWalletCp);
    final repo = CharacterRepository();
    await repo.updateCharacter(widget.character);
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        _buildSummaryCard(),
        const SizedBox(height: 32),
        Column(
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
      ],
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
    final walletCp = widget.character.walletInCopper;
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
            GestureDetector(
              onTap: _showWalletDialog,
              child: Expanded(
                child: Column(
                  children: [
                    Icon(Icons.toll, color: const Color(0xFFB8860B), size: 20),
                    const SizedBox(height: 4),
                    Text(
                      _formatGP(walletCp),
                      style: AppTextStyles.statMedium
                          .copyWith(color: const Color(0xFFB8860B)),
                    ),
                    Text(
                      _formatWallet(walletCp),
                      style: AppTextStyles.labelXs
                          .copyWith(color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text('Geldbeutel', style: AppTextStyles.labelXs),
                  ],
                ),
              ),
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
                        if (ci.quantity > 1) '×${ci.quantity}',
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
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.remove, size: 16),
                      ),
                    ),
                    if (ci.quantity == 1)
                     GestureDetector(
                      onTap: () => _updateQuantity(ci, ci.quantity - 1),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: widget.themeColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Entfernen', style: AppTextStyles.body.copyWith(color: Colors.white),),
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
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.add, size: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}