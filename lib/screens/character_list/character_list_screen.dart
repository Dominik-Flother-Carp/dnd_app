// lib/screens/character_list/character_list_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dnd_app/models/character.dart';
import 'package:dnd_app/repositories/character_repository.dart';
import 'package:dnd_app/screens/character_list/character_card.dart';
import 'package:dnd_app/screens/character_sheet/character_sheet_screen.dart';
import 'package:dnd_app/screens/character_create/character_create_screen.dart';
import 'package:dnd_app/screens/compendium/compendium_screen.dart';
import 'package:dnd_app/models/classes.dart';
import 'package:dnd_app/theme/app_text_styles.dart';
import 'package:dnd_app/screens/initiative/initiative_tracker_screen.dart';

class CharacterListScreen extends StatefulWidget {
  const CharacterListScreen({super.key});

  @override
  State<CharacterListScreen> createState() => _CharacterListScreenState();
}

class _CharacterListScreenState extends State<CharacterListScreen> {
  final CharacterRepository _repository = CharacterRepository();
  List<Character> _characters = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCharacters();
  }

  Future<void> _loadCharacters() async {
    setState(() => _isLoading = true);
    final characters = await _repository.getAllCharacters();
    setState(() {
      _characters = characters;
      _isLoading = false;
    });
  }

  Future<void> _deleteCharacter(Character character) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Charakter löschen', style: AppTextStyles.sectionTitle),
        content: Text(
          '${character.name} wirklich löschen? '
          'Diese Aktion kann nicht rückgängig gemacht werden.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Abbrechen', style: AppTextStyles.body),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Löschen', style: AppTextStyles.body),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _repository.deleteCharacter(character.id);
      _loadCharacters();
    }
  }

  // ── Dev-Shortcut ──────────────────────────────────────────────────────────

  Future<void> _createDevCharacter() async {
    final character = Character(name: 'Testcharakter')
      ..characterClass = 'Magier'
      ..subclass = 'Hervorrufung'
      ..race = 'Mensch'
      ..background = 'Einsiedler'
      ..alignment = 'Neutral Gut'
      ..level = 5
      ..hitDie = 6
      ..strength = 8
      ..dexterity = 14
      ..constitution = 13
      ..intelligence = 17
      ..wisdom = 12
      ..charisma = 10
      ..armorClass = 12
      ..speed = 9
      ..maxHitPoints = 28
      ..currentHitPoints = 20
      ..experiencePoints = 6500
      ..useEdition2024 = false
      ..skillProficiencies = {
        'arcana': true,
        'history': true,
        'investigation': true,
        'insight': true,
      }
      ..savingThrowProficiencies = {
        'intelligence': true,
        'wisdom': true,
      }
      ..spellSlots = calculateSpellSlots('Magier', 5)
      ..walletInCopper = 3500; // 35 GP in Kupfer

    await _repository.insertCharacter(character);
    await _loadCharacters();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dev-Charakter erstellt'),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFF3B1F0A),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Meine Charaktere',
            style: AppTextStyles.cardTitle.copyWith(
              color: const Color(0xFFF5DEB3),
            )),
        // Nur im Debug-Mode sichtbar
        actions: [
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.science_outlined),
              tooltip: 'Dev-Charakter erstellen',
              onPressed: _createDevCharacter,
            ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _characters.isEmpty
              ? _buildEmptyState()
              : _buildCharacterList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const CharacterCreateScreen(),
            ),
          );
          if (created == true) _loadCharacters();
        },
        icon: const Icon(Icons.add),
        label: Text('Neuer Charakter', style: AppTextStyles.body),
        backgroundColor: const Color(0xFF8B0000),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF2C1A0E),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: const Color(0xFF3B1F0A),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.shield,
                    size: 48,
                    color: Color(0xFFF5DEB3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'D&D Companion',
                    style: AppTextStyles.sectionTitle.copyWith(
                      color: const Color(0xFFF5DEB3),
                    ),
                  ),
                  Text(
                    'Dein Begleiter am Spieltisch',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: const Color(0xFFF5DEB3).withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildDrawerItem(
              context,
              icon: Icons.people,
              label: 'Charaktere',
              isActive: true,
              onTap: () => Navigator.pop(context),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.menu_book,
              label: 'Kompendium',
              isActive: false,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CompendiumScreen(),
                  ),
                );
              },
            ),
             _buildDrawerItem(
              context,
              icon: Icons.swap_vert,
              label: 'Initiative',
              isActive: false,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const InitiativeTrackerScreen(),
                  ),
                );
              },
            ),
            const Divider(color: Color(0xFF4A2F1A), height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Version 1.0',
                style: AppTextStyles.labelXs.copyWith(
                  color: const Color(0xFFF5DEB3).withValues(alpha: 0.3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isActive
            ? const Color(0xFFF5DEB3)
            : const Color(0xFFF5DEB3).withValues(alpha: 0.5),
      ),
      title: Text(
        label,
        style: AppTextStyles.body.copyWith(
          color: isActive
              ? const Color(0xFFF5DEB3)
              : const Color(0xFFF5DEB3).withValues(alpha: 0.5),
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      tileColor: isActive
          ? const Color(0xFFF5DEB3).withValues(alpha: 0.08)
          : null,
      onTap: onTap,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_add_alt_1, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Noch keine Charaktere',
            style: AppTextStyles.sectionTitle.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tippe auf "Neuer Charakter" um loszulegen',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterList() {
    return RefreshIndicator(
      onRefresh: _loadCharacters,
      child: ListView.builder(
        itemCount: _characters.length,
        itemBuilder: (context, index) {
          final character = _characters[index];
          return CharacterCard(
            character: character,
            onDelete: () => _deleteCharacter(character),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CharacterSheetScreen(
                    characterId: character.id,
                  ),
                ),
              );
              _loadCharacters();
            },
          );
        },
      ),
    );
  }
}