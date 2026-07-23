import 'package:flutter/material.dart';

import '../app/ui_tokens.dart';
import 'ui_v2_components.dart';

class ProductItemCard extends StatelessWidget {
  final String title;
  final String categoryLabel;
  final String statusLabel;
  final String location;
  final String dateLine;
  final IconData icon;
  final VoidCallback? onTap;

  const ProductItemCard({
    super.key,
    required this.title,
    required this.categoryLabel,
    required this.statusLabel,
    required this.location,
    required this.dateLine,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return UiActionCard(
      onTap: onTap,
      semanticLabel: '開啟生活項目：$title',
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: UiSpace.sm,
          vertical: 10,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: UiColors.iconSurface,
                borderRadius: BorderRadius.circular(UiRadius.control),
              ),
              child: Icon(icon, color: UiColors.primary, size: 22),
            ),
            const SizedBox(width: UiSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: UiType.cardTitle),
                  const SizedBox(height: 3),
                  Text(
                    '$categoryLabel · $location',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiType.caption,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    dateLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiType.caption.copyWith(
                      color: UiColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: UiSpace.xs),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                UiStatusTag(
                  label: statusLabel,
                  tone: _toneForStatus(statusLabel),
                ),
                const SizedBox(height: UiSpace.xs),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: UiColors.iconMuted,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

UiStatusTone _toneForStatus(String label) => switch (label) {
  '正常追蹤' => UiStatusTone.success,
  '暫停' => UiStatusTone.warning,
  _ => UiStatusTone.neutral,
};
