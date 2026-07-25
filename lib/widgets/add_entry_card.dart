import 'package:flutter/material.dart';

import '../app/ui_tokens.dart';
import 'ui_v2_components.dart';

class AddEntryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final bool emphasized;

  const AddEntryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return UiActionCard(
      semanticLabel: '$title。$description',
      onTap:
          onTap ??
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('此功能下一版開放'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: emphasized ? UiColors.accent : UiColors.iconSurface,
                borderRadius: BorderRadius.circular(UiRadius.control),
              ),
              child: Icon(
                icon,
                color: emphasized ? Colors.white : UiColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: UiSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: UiType.cardTitle),
                  const SizedBox(height: UiSpace.xxs),
                  Text(description, style: UiType.body),
                ],
              ),
            ),
            const SizedBox(width: UiSpace.xs),
            Icon(
              Icons.chevron_right,
              color: emphasized ? UiColors.accent : UiColors.iconMuted,
            ),
          ],
        ),
      ),
    );
  }
}
