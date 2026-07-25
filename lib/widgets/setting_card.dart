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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(UiRadius.control),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: UiSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(title, style: UiType.cardTitle)),
                    if (highlighted) const _SafetyBadge(),
                  ],
                ),
                const SizedBox(height: 5),
                Text(content, style: UiType.body),
              ],
            ),
          ),
          const SizedBox(width: UiSpace.xs),
          const Icon(Icons.chevron_right_rounded, color: UiColors.iconMuted),
        ],
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
