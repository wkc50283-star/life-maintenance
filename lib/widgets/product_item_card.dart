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
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(UiSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: UiColors.iconSurface,
                      borderRadius: BorderRadius.circular(UiRadius.control),
                    ),
                    child: Icon(icon, color: UiColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: UiColors.textPrimary),
                        ),
                        const SizedBox(height: 7),
                        _InfoPill(label: categoryLabel),
                      ],
                    ),
                  ),
                  _StatusTag(label: statusLabel),
                ],
              ),
              const SizedBox(height: UiSpace.md),
              _ItemInfoRow(icon: Icons.place_outlined, text: '位置：$location'),
              const SizedBox(height: 10),
              _ItemInfoRow(
                icon: Icons.event_available_outlined,
                text: dateLine,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;

  const _InfoPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: UiColors.surfaceBlue,
        borderRadius: BorderRadius.circular(UiRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: UiColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  final String label;

  const _StatusTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: UiColors.successSurface,
        borderRadius: BorderRadius.circular(UiRadius.pill),
        border: Border.all(color: UiColors.success.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: UiColors.success,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ItemInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ItemInfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: UiColors.iconMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: UiColors.textSecondary,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
