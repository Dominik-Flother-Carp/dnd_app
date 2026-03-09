// lib/widgets/collapsible_card.dart

import 'package:flutter/material.dart';
import 'package:dnd_app/theme/app_text_styles.dart';

class CollapsibleCard extends StatefulWidget {
  final String title;
  final Color themeColor;
  final Widget child;
  final bool initiallyExpanded;

  const CollapsibleCard({
    super.key,
    required this.title,
    required this.themeColor,
    required this.child,
    this.initiallyExpanded = true,
  });

  @override
  State<CollapsibleCard> createState() => _CollapsibleCardState();
}

class _CollapsibleCardState extends State<CollapsibleCard>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late AnimationController _controller;
  late Animation<double> _iconTurn;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
      value: _expanded ? 1.0 : 0.0,
    );
    _iconTurn = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      _expanded ? _controller.forward() : _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          InkWell(
            onTap: _toggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: AppTextStyles.sectionTitle.copyWith(
                        color: widget.themeColor,
                      ),
                    ),
                  ),
                  RotationTransition(
                    turns: _iconTurn,
                    child: Icon(
                      Icons.expand_more,
                      color: widget.themeColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: widget.child,
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}