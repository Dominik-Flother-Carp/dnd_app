// lib/screens/compendium/compendium_screen.dart

import 'package:flutter/material.dart';
import 'package:dnd_app/theme/app_text_styles.dart';

class CompendiumScreen extends StatelessWidget {
  const CompendiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kompendium',
            style: AppTextStyles.cardTitle.copyWith(
              color: const Color(0xFFF5DEB3),
            )),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'Kompendium kommt bald',
              style: AppTextStyles.body.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}