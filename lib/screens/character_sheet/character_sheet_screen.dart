// lib/screens/character_sheet/character_sheet_screen.dart

import 'package:flutter/material.dart';
import 'package:dnd_app/models/character.dart';
import 'package:dnd_app/repositories/character_repository.dart';
import 'package:dnd_app/screens/character_sheet/tabs/overview_tab.dart';
import 'package:dnd_app/screens/character_sheet/tabs/skills_tab.dart';
import 'package:dnd_app/theme/app_text_styles.dart';

class CharacterSheetScreen extends StatefulWidget {
  final String characterId;

  const CharacterSheetScreen({
    super.key,
    required this.characterId,
  });

  @override
  State<CharacterSheetScreen> createState() => _CharacterSheetScreenState();
}

class _CharacterSheetScreenState extends State<CharacterSheetScreen>
    with SingleTickerProviderStateMixin {
  final CharacterRepository _repository = CharacterRepository();

  Character? _character;
  bool _isLoading = true;
  late TabController _tabController;

  Color get _themeColor => _character?.useEdition2024 == true
      ? const Color(0xFF1B4F72)
      : const Color(0xFF3B1F0A);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCharacter();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCharacter() async {
    final character = await _repository.getCharacterById(widget.characterId);
    setState(() {
      _character = character;
      _isLoading = false;
    });
  }

  Future<void> _saveCharacter() async {
    if (_character == null) return;
    await _repository.updateCharacter(_character!);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_character == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Fehler', style: AppTextStyles.cardTitle)),
        body: Center(
          child: Text('Charakter nicht gefunden', style: AppTextStyles.body),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(innerBoxIsScrolled),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            OverviewTab(
              character: _character!,
              themeColor: _themeColor,
              onChanged: () => setState(() {}),
              onSave: _saveCharacter,
            ),
            SkillsTab(
              character: _character!,
              themeColor: _themeColor,
              onSave: _saveCharacter,
            ),
            _buildComingSoon('Ausrüstung'),
            _buildComingSoon('Zauber & Fähigkeiten'),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: _themeColor,
      foregroundColor: const Color(0xFFF5DEB3),
      flexibleSpace: FlexibleSpaceBar(
        background: _buildHeader(),
      ),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFFF5DEB3),
        labelColor: const Color(0xFFF5DEB3),
        unselectedLabelColor: const Color(0xFFF5DEB3).withOpacity(0.5),
        labelStyle: AppTextStyles.label,
        tabs: const [
          Tab(text: 'Übersicht'),
          Tab(text: 'Fertigkeiten'),
          Tab(text: 'Ausrüstung'),
          Tab(text: 'Zauber'),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final character = _character!;
    return Container(
      color: _themeColor,
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFF5DEB3).withOpacity(0.2),
            foregroundColor: const Color(0xFFF5DEB3),
            radius: 36,
            child: Text(
              character.name.isNotEmpty
                  ? character.name[0].toUpperCase()
                  : '?',
              style: AppTextStyles.avatarLarge.copyWith(
                color: const Color(0xFFF5DEB3),
              ),
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
                  style: AppTextStyles.screenTitle.copyWith(
                    color: const Color(0xFFF5DEB3),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _buildSubtitle(),
                  style: AppTextStyles.body.copyWith(
                    color: const Color(0xFFF5DEB3).withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                /*Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5DEB3).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    character.useEdition2024 ? 'D&D 2024' : 'D&D 2014',
                    style: AppTextStyles.badgeSmall.copyWith(
                      color: const Color(0xFFF5DEB3),
                    ),
                  ),
                ),*/
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildSubtitle() {
    final c = _character!;
    final parts = <String>[];
    if (c.characterClass.isNotEmpty) {
      final classEntry = c.subclass.isNotEmpty
          ? '${c.characterClass} (${c.subclass})'
          : c.characterClass;
      parts.add(classEntry);
    }
    if (c.race.isNotEmpty) parts.add(c.race);
    parts.add('Stufe ${c.level}');
    return parts.join(' · ');
  }

  Widget _buildComingSoon(String label) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            '$label ist in Arbeit!',
            style: AppTextStyles.body.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}