import 'package:flutter/material.dart';

import '../app/ui_tokens.dart';

class SettingCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final bool highlighted;

  const SettingCard({
    super.key,
    required this.title,
    required this.content,
    required this.icon,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = highlighted ? UiColors.warning : UiColors.primary;
    final iconBackground = highlighted
        ? UiColors.warningSurface
        : UiColors.iconSurface;
    final borderColor = highlighted
        ? UiColors.warning.withValues(alpha: 0.22)
        : UiColors.border;

    return Card(
      margin: const EdgeInsets.only(bottom: UiSpace.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UiRadius.card),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(UiSpace.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(UiRadius.control),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: UiSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: UiColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      if (highlighted) const _SafetyBadge(),
                    ],
                  ),
                  const SizedBox(height: UiSpace.xs),
                  Text(
                    content,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: UiColors.textSecondary,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SafetyBadge extends StatelessWidget {
  const _SafetyBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: UiColors.warningSurface,
        borderRadius: BorderRadius.circular(UiRadius.pill),
        border: Border.all(color: UiColors.warning.withValues(alpha: 0.22)),
      ),
      child: Text(
        '重要',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: UiColors.warning,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
