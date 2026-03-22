// lib/widgets/widget_utils.dart
//
// Gemeinsam genutzte kleine Widgets.
// Verhindert doppelte Definitionen von _badge/_chip und _buildMarkdownText.

import 'package:flutter/material.dart';
import 'package:dnd_app/theme/app_text_styles.dart';

// ── Badge / Chip ──────────────────────────────────────────────────────────────

/// Einfaches farbiges Label ohne Rahmen.
/// Ersetzt die identischen _badge()-Methoden in inventory_tab und spell_tab.
///
/// Beispiel: AppBadge(label: 'Ritual', color: Colors.teal)
class AppBadge extends StatelessWidget {
  final String label;
  final Color color;

  const AppBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
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
}

/// Farbiges Label mit Rahmen und fettem Text.
/// Ersetzt die nahezu identischen _chip()/_buildChip()-Methoden in
/// features_tab (_FeatureDetailSheet) und compendium_detail_sheet.
///
/// Beispiel: AppChip(label: 'Unterklasse', color: themeColor)
class AppChip extends StatelessWidget {
  final String label;
  final Color? color;

  const AppChip({super.key, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelXs.copyWith(
          color: color ?? Colors.grey[700],
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ── Markdown-Text ─────────────────────────────────────────────────────────────

/// Rendert Text mit einfachem **Fettdruck**-Markdown.
/// Ersetzt die byte-identischen _buildFluffText() in character_sheet_screen
/// (_IdentitySheet) und _buildDescription() in features_tab (_FeatureDetailSheet).
///
/// Unterstützt nur `**fett**` – kein volles Markdown.
///
/// Beispiel: MarkdownText('Das ist **wichtig**.')
class MarkdownText extends StatelessWidget {
  final String text;

  const MarkdownText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final baseStyle = AppTextStyles.body.copyWith(color: Colors.grey[700]);
    final boldStyle = baseStyle.copyWith(
      fontWeight: FontWeight.bold,
      color: Colors.grey[900],
    );

    final spans = <TextSpan>[];
    final re = RegExp(r'\*\*(.+?)\*\*');
    int last = 0;

    for (final match in re.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(text: text.substring(last, match.start)));
      }
      spans.add(TextSpan(text: match.group(1), style: boldStyle));
      last = match.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }

    return RichText(text: TextSpan(style: baseStyle, children: spans));
  }
}

// ── Detail-Sheet Sektion ──────────────────────────────────────────────────────

/// Abschnitt mit uppercase-Label und Inhalt.
/// Ersetzt die nahezu identischen _buildSection() in compendium_detail_sheet
/// und _section() in features_tab (_FeatureDetailSheet).
/// Der Titel wird automatisch in Großbuchstaben umgewandelt.
///
/// Beispiel:
/// DetailSection(title: 'Beschreibung', child: MarkdownText(text))
class DetailSection extends StatelessWidget {
  final String title;
  final Widget child;

  const DetailSection({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          title.toUpperCase(),
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[500],
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}