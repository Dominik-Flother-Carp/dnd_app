// lib/screens/character_sheet/tabs/inventory_tab.dart

import 'package:flutter/material.dart';
import 'package:dnd_app/models/character.dart';
import 'package:dnd_app/models/item.dart';
import 'package:dnd_app/models/character_items.dart';
import 'package:dnd_app/models/quick_item.dart';
import 'package:dnd_app/repositories/item_repository.dart';
import 'package:dnd_app/repositories/quick_item_repository.dart';
import 'package:dnd_app/repositories/character_repository.dart';
import 'package:dnd_app/screens/compendium/compendium_detail_sheet.dart';
import 'package:dnd_app/screens/character_sheet/tabs/dialogs/wallet_dialog.dart';
import 'package:dnd_app/screens/character_sheet/tabs/dialogs/notes_dialog.dart';
import 'package:dnd_app/screens/character_sheet/tabs/dialogs/quick_item_dialog.dart';
import 'package:dnd_app/screens/character_sheet/tabs/dialogs/compendium_picker_sheet.dart';
import 'package:dnd_app/theme/app_text_styles.dart';
import 'package:dnd_app/utils/coin_utils.dart';
import 'package:dnd_app/widgets/widget_utils.dart';

const _equippableCategories = {
  ItemCategory.weapon,
  ItemCategory.armor,
  ItemCategory.shield,
};

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
  // Gecacht – wird nur in _load() neu berechnet, nicht bei jedem build()
  List<MapEntry<ItemCategory, List<_InventoryEntry>>> _groupedEntries = [];

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
      _groupedEntries = _buildGroupedEntries(items, qItems);
    });
  }

  // ── Berechnungen ─────────────────────────────────────────────────────────

  double get _totalWeight {
    final fromItems = _items.fold(0.0, (s, ci) => s + ci.totalWeight);
    final fromQuick =
        _quickItems.fold(0.0, (s, qi) => s + qi.weight * qi.quantity);
    return fromItems + fromQuick;
  }

  /// Gesamtkapazität aller Behälter (addiert).
  /// null wenn kein Behälter im Inventar.
  double? get _totalContainerCapacity {
    final containers = _items.where((ci) => ci.item.isContainer);
    if (containers.isEmpty) return null;
    return containers.fold(0.0, (s, ci) => s! + ci.item.capacity! * ci.quantity);
  }

  /// Gewicht aller Items die in einem Behälter liegen
  /// (weder ausgerüstet noch am Körper getragen).
  double get _containerLoad {
    return _items
        .where((ci) => !ci.isEquipped && !ci.isOnBody)
        .fold(0.0, (s, ci) => s + ci.totalWeight);
  }

  int get _attuneCount => _items.where((ci) => ci.isAttuned).length;

  bool get _isEmpty => _items.isEmpty && _quickItems.isEmpty;

  /// Berechnet die nach Enum-Reihenfolge sortierten Kategorie-Gruppen.
  /// Ergebnis wird in _groupedEntries gecacht und nur bei _load() neu berechnet.
  List<MapEntry<ItemCategory, List<_InventoryEntry>>> _buildGroupedEntries(
      List<CharacterItem> items, List<QuickItem> quickItems) {
    final map = <ItemCategory, List<_InventoryEntry>>{};
    for (final ci in items) {
      map.putIfAbsent(ci.item.category, () => []).add(_CiEntry(ci));
    }
    for (final qi in quickItems) {
      map.putIfAbsent(qi.category, () => []).add(_QiEntry(qi));
    }
    return [
      for (final cat in ItemCategory.values)
        if (map.containsKey(cat)) MapEntry(cat, map[cat]!),
    ];
  }

  // ── Aktionen ─────────────────────────────────────────────────────────────

  Future<void> _showWalletDialog() async {
    final result = await showDialog<WalletDialogResult>(
      context: context,
      builder: (_) => WalletDialog(
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
          CompendiumPickerSheet(themeColor: widget.themeColor),
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
      builder: (_) => QuickItemDialog(
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
    if (ci.isEquipped && ci.isOnBody) ci.isOnBody = false;
    await _itemRepo.updateCharacterItem(ci);
    await _load();
  }

  Future<void> _toggleAttuned(CharacterItem ci) async {
    if (!ci.isAttuned && _attuneCount >= 3) return;
    ci.isAttuned = !ci.isAttuned;
    await _itemRepo.updateCharacterItem(ci);
    await _load();
  }

  Future<void> _toggleOnBody(CharacterItem ci) async {
    ci.isOnBody = !ci.isOnBody;
    // Am Körper und ausgerüstet schließen sich aus
    if (ci.isOnBody && ci.isEquipped) ci.isEquipped = false;
    await _itemRepo.updateCharacterItem(ci);
    await _load();
  }

  Future<void> _showCiNotes(CharacterItem ci) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => NotesDialog(
        itemName:     ci.item.name,
        currentNotes: ci.notes,
        themeColor:   widget.themeColor,
      ),
    );
    if (result == null || !mounted) return;
    ci.notes = result;
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: _buildSummaryCard(),
        ),
        Expanded(
          child: Stack(
            children: [
              CustomScrollView(
                primary: false,
                physics: const ClampingScrollPhysics(),
                slivers: [
                  if (_isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildScrollableEmpty(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => _buildCategorySection(
                            _groupedEntries[i].key,
                            _groupedEntries[i].value,
                          ),
                          childCount: _groupedEntries.length,
                        ),
                      ),
                    ),
                ],
              ),
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
          ),
        ),
      ],
    );
  }

  Widget _buildScrollableEmpty() {
    return Center(
      child: Column(
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
    );
  }



  Widget _buildSummaryCard() {
    final walletCp    = widget.character.walletInCopper;
    final carryLimit  = widget.character.strength * 15;
    final overloaded  = _totalWeight > carryLimit;
    final capacity    = _totalContainerCapacity;
    final containerOverloaded = capacity != null && _containerLoad > capacity;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _buildSummaryStat(
                  label: 'Gewicht (lb)',
                  value: '${_totalWeight.toStringAsFixed(1)} / $carryLimit',
                  icon: Icons.scale,
                  color: overloaded ? Colors.red : null,
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _showWalletDialog,
                    child: Column(
                      children: [
                        const Icon(Icons.toll,
                            color: Color(0xFFB8860B), size: 20),
                        const SizedBox(height: 4),
                        Text(
                          formatGP(walletCp),
                          style: AppTextStyles.statMedium
                              .copyWith(color: const Color(0xFFB8860B)),
                        ),
                        Text(
                          formatWallet(walletCp),
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
            if (capacity != null) ...[
              const SizedBox(height: 12),
              Divider(height: 1, color: Colors.grey[200]),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.backpack_outlined,
                      size: 16,
                      color: containerOverloaded
                          ? Colors.red
                          : Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text(
                    'Behälter',
                    style: AppTextStyles.labelXs
                        .copyWith(color: Colors.grey[500]),
                  ),
                  const Spacer(),
                  Text(
                    '${_containerLoad.toStringAsFixed(1)} / ${capacity.toStringAsFixed(1)} lb',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: containerOverloaded ? Colors.red : Colors.grey[700],
                      fontWeight: containerOverloaded
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_containerLoad / capacity).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(
                    containerOverloaded ? Colors.red : widget.themeColor,
                  ),
                ),
              ),
            ],
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
        onTap: () => showItemDetailSheet(context, item, notes: ci.notes),
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
                          AppBadge(label: 'Ausgerüstet', color: widget.themeColor),
                        if (ci.isOnBody)
                          AppBadge(label: 'Am Körper', color: Colors.teal),
                        if (ci.isAttuned)
                          AppBadge(label: 'Eingestimmt', color: Colors.purple),
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
            ListTile(
              leading: Icon(
                ci.isOnBody
                    ? Icons.accessibility_new
                    : Icons.accessibility_new_outlined,
                color: ci.isOnBody ? Colors.teal : null,
              ),
              title: Text(
                ci.isOnBody ? 'Nicht mehr am Körper' : 'Am Körper tragen',
                style: AppTextStyles.body,
              ),
              onTap: () {
                Navigator.pop(context);
                _toggleOnBody(ci);
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
              leading: Icon(Icons.notes_outlined, color: widget.themeColor),
              title: Text(
                ci.notes.isEmpty ? 'Notiz hinzufügen' : 'Notiz bearbeiten',
                style: AppTextStyles.body,
              ),
              onTap: () {
                Navigator.pop(context);
                _showCiNotes(ci);
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
              color: qty <= 1 ? Colors.red : themeColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: qty <= 1
                ? Text(
                    'Entf.',
                    style: AppTextStyles.labelXs
                        .copyWith(color: Colors.white),
                  )
                : const Icon(Icons.remove, size: 16, color: Colors.white),
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
              color: themeColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.add, size: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }
}