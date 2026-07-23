import 'package:flutter/material.dart';

import '../app/ui_tokens.dart';
import 'ui_v2_components.dart';

class HistoryRecordCard extends StatelessWidget {
  final String date;
  final String title;
  final String itemName;
  final String recordType;
  final String description;
  final List<String> detailLines;
  final String result;
  final String? costLabel;
  final String? photoLabel;
  final IconData icon;
  final VoidCallback? onTap;

  const HistoryRecordCard({
    super.key,
    required this.date,
    required this.title,
    required this.itemName,
    required this.recordType,
    required this.description,
    this.detailLines = const [],
    required this.result,
    required this.costLabel,
    required this.photoLabel,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return UiActionCard(
      onTap: onTap,
      semanticLabel: onTap == null ? null : '開啟史略：$title',
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
                        Text(title, style: UiType.cardTitle),
                        const SizedBox(height: 7),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _SoftTag(label: date),
                            _SoftTag(label: recordType),
                            _SoftTag(label: itemName),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Flexible(child: _ResultTag(label: result)),
                ],
              ),
              const SizedBox(height: UiSpace.md),
              Text(
                description,
                style: UiType.body.copyWith(color: UiColors.textPrimary),
              ),
              if (detailLines.isNotEmpty) ...[
                const SizedBox(height: 12),
                for (final line in detailLines) _DetailLine(text: line),
              ],
              if (costLabel != null || photoLabel != null) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (costLabel != null)
                      _MetaTag(
                        icon: Icons.payments_outlined,
                        label: costLabel!,
                      ),
                    if (photoLabel != null)
                      _MetaTag(
                        icon: Icons.photo_library_outlined,
                        label: photoLabel!,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  final String text;

  const _DetailLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: UiColors.textSecondary,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SoftTag extends StatelessWidget {
  final String label;

  const _SoftTag({required this.label});

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

class _ResultTag extends StatelessWidget {
  final String label;

  const _ResultTag({required this.label});

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

class _MetaTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: UiColors.warningSurface,
        borderRadius: BorderRadius.circular(UiRadius.pill),
        border: Border.all(color: UiColors.warning.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: UiColors.warning),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: UiColors.warning,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
