import 'package:dnd_app/screens/character_create/character_create_screen.dart';
import 'package:flutter/material.dart';
import 'package:dnd_app/models/character.dart';
import 'package:dnd_app/repositories/character_repository.dart';
import 'package:dnd_app/screens/character_list/character_card.dart';
import 'package:dnd_app/screens/character_sheet/character_sheet_screen.dart';

class CharacterListScreen extends StatefulWidget {
  const CharacterListScreen({super.key});

  @override
  State<CharacterListScreen> createState() => _CharacterListScreenState();
}

class _CharacterListScreenState extends State<CharacterListScreen> {

  final CharacterRepository _repository = CharacterRepository();
  List<Character> _characters = [];
  bool _isLoading = true;

  // initState wird einmal aufgerufen wenn der Screen das erste Mal gebaut wird
  @override
  void initState() {
    super.initState();
    _loadCharacters();
  }

  // Charaktere aus der Datenbank laden und UI aktualisieren
  Future<void> _loadCharacters() async {
    setState(() => _isLoading = true);

    final characters = await _repository.getAllCharacters();

    setState(() {
      _characters = characters;
      _isLoading = false;
    });
  }

  // Charakter löschen mit Bestätigungsdialog
  Future<void> _deleteCharacter(Character character) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Charakter löschen'),
        content: Text(
          '${character.name} wirklich löschen? '
          'Diese Aktion kann nicht rückgängig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _repository.deleteCharacter(character.id);
      _loadCharacters(); // Liste neu laden
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚔️ Meine Charaktere'),
      ),

      // Haupt-Inhalt
      body: _isLoading
          // Ladeindikator solange Daten geladen werden
          ? const Center(child: CircularProgressIndicator())
          // Leerer Zustand – noch keine Charaktere vorhanden
          : _characters.isEmpty
              ? _buildEmptyState()
              // Liste der Charaktere
              : _buildCharacterList(),

      // Floating Action Button zum Erstellen eines neuen Charakters
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
        label: const Text('Neuer Charakter'),
        backgroundColor: const Color(0xFF8B0000),
        foregroundColor: Colors.white,
      ),
    );
  }

  // Widget für den leeren Zustand
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_add_alt_1,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Noch keine Charaktere',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tippe auf "Neuer Charakter" um loszulegen',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // Widget für die Charakterliste
  Widget _buildCharacterList() {
    return RefreshIndicator(
      // Runterziehen zum Neu-Laden
      onRefresh: _loadCharacters,
      child: ListView.builder(
        // Anzahl der Elemente
        itemCount: _characters.length,
        // Baut nur die Karten die gerade sichtbar sind – effizient bei langen Listen
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