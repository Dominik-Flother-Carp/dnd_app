// lib/screens/character_sheet/tabs/inventory_tab.dart

import 'package:flutter/material.dart';
import 'package:dnd_app/models/character.dart';
import 'package:dnd_app/models/item.dart';
import 'package:dnd_app/models/character_items.dart';
import 'package:dnd_app/models/quick_item.dart';
import 'package:dnd_app/repositories/item_repository.dart';
import 'package:dnd_app/repositories/quick_item_repository.dart';
import 'package:dnd_app/repositories/character_repository.dart';
import 'package:dnd_app/services/compendium_service.dart';
import 'package:dnd_app/screens/compendium/compendium_detail_sheet.dart';
import 'package:dnd_app/theme/app_text_styles.dart';

const _equippableCategories = {
  ItemCategory.weapon,
  ItemCategory.armor,
  ItemCategory.shield,
};

// ── Münz-Umrechnung ───────────────────────────────────────────────────────────

const _cpPerPP = 1000;
const _cpPerGP = 100;
const _cpPerEP = 50;
const _cpPerSP = 10;

int _coinToCopper(int amount, String coin) {
  switch (coin) {
    case 'PP': return amount * _cpPerPP;
    case 'GM': return amount * _cpPerGP;
    case 'EM': return amount * _cpPerEP;
    case 'SM': return amount * _cpPerSP;
    default:   return amount;
  }
}

Map<String, int> _breakdownCopper(int cp) {
  var rem = cp;
  final pp = rem ~/ _cpPerPP; rem -= pp * _cpPerPP;
  final gp = rem ~/ _cpPerGP; rem -= gp * _cpPerGP;
  final ep = rem ~/ _cpPerEP; rem -= ep * _cpPerEP;
  final sp = rem ~/ _cpPerSP; rem -= sp * _cpPerSP;
  return {'PP': pp, 'GM': gp, 'EM': ep, 'SM': sp, 'KM': rem};
}

String _formatWallet(int totalCp) {
  if (totalCp <= 0) return '0 GM';
  final b = _breakdownCopper(totalCp);
  final parts = <String>[];
  for (final coin in ['PP', 'GM', 'EM', 'SM', 'KM']) {
    if (b[coin]! > 0) parts.add('${b[coin]} $coin');
  }
  return parts.join(' ');
}

String _formatGP(int totalCp) {
  final gp = totalCp / _cpPerGP;
  if (gp == gp.truncateToDouble()) return '${gp.toInt()} GM';
  return '${gp.toStringAsFixed(2)} GM';
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
  late final TextEditingController _ppCtrl;
  late final TextEditingController _gpCtrl;
  late final TextEditingController _epCtrl;
  late final TextEditingController _spCtrl;
  late final TextEditingController _cpCtrl;

  bool _isAdding = true;

  @override
  void initState() {
    super.initState();
    final b = _breakdownCopper(widget.walletCp);
    _ppCtrl = TextEditingController(text: b['PP']!.toString());
    _gpCtrl = TextEditingController(text: b['GM']!.toString());
    _epCtrl = TextEditingController(text: b['EM']!.toString());
    _spCtrl = TextEditingController(text: b['SM']!.toString());
    _cpCtrl = TextEditingController(text: b['KM']!.toString());
  }

  @override
  void dispose() {
    _ppCtrl.dispose();
    _gpCtrl.dispose();
    _epCtrl.dispose();
    _spCtrl.dispose();
    _cpCtrl.dispose();
    super.dispose();
  }

  int get _enteredCp =>
      _coinToCopper(int.tryParse(_ppCtrl.text) ?? 0, 'PP') +
      _coinToCopper(int.tryParse(_gpCtrl.text) ?? 0, 'GM') +
      _coinToCopper(int.tryParse(_epCtrl.text) ?? 0, 'EM') +
      _coinToCopper(int.tryParse(_spCtrl.text) ?? 0, 'SM') +
      (int.tryParse(_cpCtrl.text) ?? 0);

  void _onSave() {
    final delta  = _enteredCp;
    final newVal = _isAdding
        ? widget.walletCp + delta
        : (widget.walletCp - delta).clamp(0, 999999999);
    Navigator.pop(context, _WalletDialogResult(newVal));
  }

  Widget _coinField(String label, TextEditingController ctrl) {
    return Expanded(
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: AppTextStyles.body,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Geldbeutel', style: AppTextStyles.sectionTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true,  label: Text('Hinzufügen')),
                    ButtonSegment(value: false, label: Text('Ausgeben')),
                  ],
                  selected: {_isAdding},
                  onSelectionChanged: (s) =>
                      setState(() => _isAdding = s.first),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return widget.themeColor;
                      }
                      return null;
                    }),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _coinField('PP', _ppCtrl),
              const SizedBox(width: 8),
              _coinField('GM', _gpCtrl),
              const SizedBox(width: 8),
              _coinField('EM', _epCtrl),
              const SizedBox(width: 8),
              _coinField('SM', _spCtrl),
              const SizedBox(width: 8),
              _coinField('KM', _cpCtrl),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Aktuell: ${_formatWallet(widget.walletCp)}',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Abbrechen', style: AppTextStyles.body),
            ),
            const SizedBox(width: 10),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: widget.themeColor),
              onPressed: _onSave,
              child: Text('OK', style: AppTextStyles.body),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Schnellitem-Dialog ────────────────────────────────────────────────────────

class _QuickItemDialog extends StatefulWidget {
  final String characterId;
  final Color themeColor;
  final QuickItem? existing;

  const _QuickItemDialog({
    required this.characterId,
    required this.themeColor,
    this.existing,
  });

  @override
  State<_QuickItemDialog> createState() => _QuickItemDialogState();
}

class _QuickItemDialogState extends State<_QuickItemDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _quantityCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _valueCtrl;
  late ItemCategory _category;

  bool get _isNew => widget.existing == null;

  static const _allowedCategories = [
    ItemCategory.treasure,
    ItemCategory.misc,
  ];

  @override
  void initState() {
    super.initState();
    final q = widget.existing;
    _nameCtrl     = TextEditingController(text: q?.name ?? '');
    _notesCtrl    = TextEditingController(text: q?.notes ?? '');
    _quantityCtrl = TextEditingController(text: '${q?.quantity ?? 1}');
    _weightCtrl   = TextEditingController(
        text: q != null ? '${q.weight}' : '0');
    _valueCtrl    = TextEditingController(
        text: q != null ? '${q.valueInCopper}' : '0');
    _category = q?.category ?? ItemCategory.misc;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    _quantityCtrl.dispose();
    _weightCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_nameCtrl.text.trim().isEmpty) return;
    final q = QuickItem(
      id:            widget.existing?.id,
      characterId:   widget.characterId,
      name:          _nameCtrl.text.trim(),
      category:      _category,
      notes:         _notesCtrl.text.trim(),
      quantity:      int.tryParse(_quantityCtrl.text) ?? 1,
      weight:        double.tryParse(_weightCtrl.text) ?? 0,
      valueInCopper: int.tryParse(_valueCtrl.text) ?? 0,
    );
    Navigator.pop(context, q);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isNew ? 'Schnellitem hinzufügen' : 'Schnellitem bearbeiten',
        style: AppTextStyles.sectionTitle,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              style: AppTextStyles.body,
              autofocus: _isNew,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ItemCategory>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Kategorie',
                border: OutlineInputBorder(),
              ),
              items: _allowedCategories
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.label, style: AppTextStyles.body),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantityCtrl,
                    keyboardType: TextInputType.number,
                    style: AppTextStyles.body,
                    decoration: const InputDecoration(
                      labelText: 'Menge',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _weightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
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
                    controller: _valueCtrl,
                    keyboardType: TextInputType.number,
                    style: AppTextStyles.body,
                    decoration: const InputDecoration(
                      labelText: 'Wert (KM)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              style: AppTextStyles.body,
              maxLines: 2,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                labelText: 'Notizen',
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
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Abbrechen', style: AppTextStyles.body),
            ),
            const SizedBox(width: 10),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: widget.themeColor),
              onPressed: _onSave,
              child: Text('Speichern', style: AppTextStyles.body),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Kompendium-Picker (Bottom Sheet) ──────────────────────────────────────────

class _CompendiumPickerSheet extends StatefulWidget {
  final Color themeColor;

  const _CompendiumPickerSheet({required this.themeColor});

  @override
  State<_CompendiumPickerSheet> createState() =>
      _CompendiumPickerSheetState();
}

class _CompendiumPickerSheetState extends State<_CompendiumPickerSheet> {
  final _searchCtrl = TextEditingController();
  final _service    = CompendiumService();

  List<Item> _results    = [];
  bool       _loading    = true;
  ItemCategory? _filterCategory;

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
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await _service.load();
    _onSearch();
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
        leading: Icon(item.category.icon,
            color: Colors.grey[600], size: 20),
        title: Text(item.name, style: AppTextStyles.cardTitle),
        subtitle: Text(
          [
            item.category.label,
            if (item is WeaponItem) item.damageDice,
            if (item is ArmorItem)  'RK ${item.armorClassBonus}',
            item.valueDisplay,
          ].join(' · '),
          style:
              AppTextStyles.bodySmall.copyWith(color: Colors.grey[500]),
        ),
        trailing: const Icon(Icons.add_circle_outline, size: 22),
        onTap: () => Navigator.pop(context, item),
      ),
    );
  }
}

// ── Unified Inventory Entry ───────────────────────────────────────────────────

sealed class _InventoryEntry {}

class _CiEntry extends _InventoryEntry {
  final CharacterItem ci;
  _CiEntry(this.ci);
}

class _QiEntry extends _InventoryEntry {
  final QuickItem qi;
  _QiEntry(this.qi);
}

// ── Inventar-Tab ──────────────────────────────────────────────────────────────

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
  final _itemRepo  = ItemRepository();
  final _quickRepo = QuickItemRepository();
  final _charRepo  = CharacterRepository();

  List<CharacterItem> _items      = [];
  List<QuickItem>     _quickItems = [];
  bool _isLoading = true;

  final Map<ItemCategory, bool> _categoryExpanded = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items  = await _itemRepo.getItemsForCharacter(widget.character.id);
    final qItems = await _quickRepo.getQuickItemsForCharacter(widget.character.id);
    if (!mounted) return;
    setState(() {
      _items      = items;
      _quickItems = qItems;
      _isLoading  = false;
      for (final ci in items) {
        _categoryExpanded.putIfAbsent(ci.item.category, () => true);
      }
      for (final qi in qItems) {
        _categoryExpanded.putIfAbsent(qi.category, () => true);
      }
    });
  }

  // ── Berechnungen ─────────────────────────────────────────────────────────

  double get _totalWeight {
    final fromItems = _items.fold(0.0, (s, ci) => s + ci.totalWeight);
    final fromQuick =
        _quickItems.fold(0.0, (s, qi) => s + qi.weight * qi.quantity);
    return fromItems + fromQuick;
  }

  int get _attuneCount => _items.where((ci) => ci.isAttuned).length;

  bool get _isEmpty => _items.isEmpty && _quickItems.isEmpty;

  Map<ItemCategory, List<_InventoryEntry>> get _grouped {
    final map = <ItemCategory, List<_InventoryEntry>>{};
    for (final ci in _items) {
      map.putIfAbsent(ci.item.category, () => []).add(_CiEntry(ci));
    }
    for (final qi in _quickItems) {
      map.putIfAbsent(qi.category, () => []).add(_QiEntry(qi));
    }
    // Reihenfolge laut Enum
    return {
      for (final cat in ItemCategory.values)
        if (map.containsKey(cat)) cat: map[cat]!,
    };
  }

  // ── Aktionen ─────────────────────────────────────────────────────────────

  Future<void> _showWalletDialog() async {
    final result = await showDialog<_WalletDialogResult>(
      context: context,
      builder: (_) => _WalletDialog(
        walletCp:   widget.character.walletInCopper,
        themeColor: widget.themeColor,
      ),
    );
    if (result == null || !mounted) return;
    setState(() => widget.character.walletInCopper = result.newWalletCp);
    await _charRepo.updateCharacter(widget.character);
  }

  Future<void> _showAddMenu() async {
    await showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: Text('Aus Kompendium', style: AppTextStyles.body),
              onTap: () {
                Navigator.pop(context);
                _showCompendiumPicker();
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_box_outlined),
              title: Text('Schnellitem', style: AppTextStyles.body),
              subtitle: Text(
                'Schatz oder sonstiger Gegenstand',
                style: AppTextStyles.bodySmall
                    .copyWith(color: Colors.grey),
              ),
              onTap: () {
                Navigator.pop(context);
                _showQuickItemDialog();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _showCompendiumPicker() async {
    final item = await showModalBottomSheet<Item>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          _CompendiumPickerSheet(themeColor: widget.themeColor),
    );
    if (item == null || !mounted) return;
    final ci = CharacterItem(
      characterId: widget.character.id,
      item:        item,
      quantity:    1,
      isEquipped:  false,
      isAttuned:   false,
    );
    await _itemRepo.addItemToCharacter(ci);
    await _load();
  }

  Future<void> _showQuickItemDialog({QuickItem? existing}) async {
    final result = await showDialog<QuickItem>(
      context: context,
      builder: (_) => _QuickItemDialog(
        characterId: widget.character.id,
        themeColor:  widget.themeColor,
        existing:    existing,
      ),
    );
    if (result == null || !mounted) return;
    if (existing == null) {
      await _quickRepo.insertQuickItem(result);
    } else {
      await _quickRepo.updateQuickItem(result);
    }
    await _load();
  }

  Future<void> _updateCiQuantity(CharacterItem ci, int newQty) async {
    if (newQty <= 0) {
      await _itemRepo.removeItemFromCharacter(ci);
    } else {
      await _itemRepo.updateQuantity(ci, newQty);
    }
    await _load();
  }

  Future<void> _updateQiQuantity(QuickItem qi, int newQty) async {
    if (newQty <= 0) {
      await _quickRepo.deleteQuickItem(qi.id);
    } else {
      await _quickRepo.updateQuickItem(QuickItem(
        id:            qi.id,
        characterId:   qi.characterId,
        name:          qi.name,
        category:      qi.category,
        notes:         qi.notes,
        quantity:      newQty,
        weight:        qi.weight,
        valueInCopper: qi.valueInCopper,
      ));
    }
    await _load();
  }

  Future<void> _toggleEquipped(CharacterItem ci) async {
    ci.isEquipped = !ci.isEquipped;
    await _itemRepo.updateCharacterItem(ci);
    await _load();
  }

  Future<void> _toggleAttuned(CharacterItem ci) async {
    if (!ci.isAttuned && _attuneCount >= 3) return;
    ci.isAttuned = !ci.isAttuned;
    await _itemRepo.updateCharacterItem(ci);
    await _load();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      children: [
        _isEmpty ? _buildEmptyState() : _buildList(),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            backgroundColor: widget.themeColor,
            foregroundColor: const Color(0xFFF5DEB3),
            onPressed: _showAddMenu,
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
        const SizedBox(height: 48),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.backpack_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Kein Inventar',
              style: AppTextStyles.sectionTitle
                  .copyWith(color: Colors.grey[400]),
            ),
            const SizedBox(height: 8),
            Text(
              'Tippe auf + um einen Gegenstand hinzuzufügen.',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
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
        ...grouped.entries
            .map((e) => _buildCategorySection(e.key, e.value)),
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
                    const Icon(Icons.toll,
                        color: Color(0xFFB8860B), size: 20),
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
      ItemCategory category, List<_InventoryEntry> entries) {
    final isExpanded = _categoryExpanded[category] ?? true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(
              () => _categoryExpanded[category] = !isExpanded),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
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
                  '(${entries.length})',
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
          ...entries.map((e) => switch (e) {
                _CiEntry(:final ci) => _buildCiTile(ci),
                _QiEntry(:final qi) => _buildQiTile(qi),
              }),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  // ── CharacterItem-Kachel ─────────────────────────────────────────────────

  Widget _buildCiTile(CharacterItem ci) {
    final item  = ci.item;
    final color = item.isMagical ? Colors.purple[300]! : Colors.grey[300]!;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showItemDetailSheet(context, item),
        onLongPress: () => _showCiOptions(ci),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
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
                          _badge('Ausgerüstet', widget.themeColor),
                        if (ci.isAttuned)
                          _badge('Eingestimmt', Colors.purple),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _ciSubtitle(ci),
                      style: AppTextStyles.bodySmall
                          .copyWith(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              _quantityControls(
                qty:        ci.quantity,
                onMinus:    () => _updateCiQuantity(ci, ci.quantity - 1),
                onPlus:     () => _updateCiQuantity(ci, ci.quantity + 1),
                themeColor: widget.themeColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _ciSubtitle(CharacterItem ci) {
    final item  = ci.item;
    final parts = <String>[];
    if (item is WeaponItem) parts.add(item.damageDice);
    if (item is ArmorItem)  parts.add('RK ${item.armorClassBonus}');
    if (item.weight > 0)    parts.add('${item.weight} lb');
    parts.add(item.valueDisplay);
    return parts.join(' · ');
  }

  Future<void> _showCiOptions(CharacterItem ci) async {
    final isEquippable =
        _equippableCategories.contains(ci.item.category);
    await showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isEquippable)
              ListTile(
                leading: Icon(ci.isEquipped
                    ? Icons.remove_circle_outline
                    : Icons.check_circle_outline),
                title: Text(
                  ci.isEquipped ? 'Ablegen' : 'Ausrüsten',
                  style: AppTextStyles.body,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _toggleEquipped(ci);
                },
              ),
            if (ci.item.requiresAttunement)
              ListTile(
                leading: Icon(
                  ci.isAttuned ? Icons.stars : Icons.star_outline,
                  color: Colors.purple,
                ),
                title: Text(
                  ci.isAttuned
                      ? 'Einstimmung lösen'
                      : 'Einzustimmen',
                  style: AppTextStyles.body,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _toggleAttuned(ci);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(
                'Entfernen',
                style: AppTextStyles.body.copyWith(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _updateCiQuantity(ci, 0);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── QuickItem-Kachel ─────────────────────────────────────────────────────

  Widget _buildQiTile(QuickItem qi) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showQuickItemDialog(existing: qi),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(qi.name, style: AppTextStyles.cardTitle),
                    const SizedBox(height: 2),
                    Text(
                      _qiSubtitle(qi),
                      style: AppTextStyles.bodySmall
                          .copyWith(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              _quantityControls(
                qty:        qi.quantity,
                onMinus:    () => _updateQiQuantity(qi, qi.quantity - 1),
                onPlus:     () => _updateQiQuantity(qi, qi.quantity + 1),
                themeColor: widget.themeColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _qiSubtitle(QuickItem qi) {
    final parts = <String>[];
    if (qi.notes.isNotEmpty) parts.add(qi.notes);
    if (qi.weight > 0) parts.add('${qi.weight} lb');
    if (qi.valueInCopper > 0) {
      final gp = qi.valueInCopper / 100.0;
      parts.add(gp == gp.truncateToDouble()
          ? '${gp.toInt()} GM'
          : '${gp.toStringAsFixed(2)} GM');
    }
    return parts.isEmpty ? 'Schnellitem' : parts.join(' · ');
  }

  // ── Shared Widgets ────────────────────────────────────────────────────────

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelXs.copyWith(color: color),
      ),
    );
  }

  Widget _quantityControls({
    required int qty,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
    required Color themeColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onMinus,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: qty <= 1 ? themeColor : Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: qty <= 1
                ? Text(
                    'Entf.',
                    style: AppTextStyles.labelXs
                        .copyWith(color: Colors.white),
                  )
                : const Icon(Icons.remove, size: 16),
          ),
        ),
        if (qty > 1) ...[
          const SizedBox(width: 4),
          Text('$qty', style: AppTextStyles.body),
        ],
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onPlus,
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
    );
  }
}