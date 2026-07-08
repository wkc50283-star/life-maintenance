import 'package:flutter/material.dart';

class MaintenanceStepChecklistTile extends StatelessWidget {
  final int order;
  final String title;
  final String description;
  final bool checked;
  final ValueChanged<bool> onChanged;

  const MaintenanceStepChecklistTile({
    super.key,
    required this.order,
    required this.title,
    required this.description,
    required this.checked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: checked ? const Color(0xFFE8F0F6) : const Color(0xFFFFFCF6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: checked ? const Color(0xFFB8CBDC) : const Color(0xFFE4E0D8),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          onChanged(!checked);
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: checked,
              onChanged: (value) {
                onChanged(value ?? false);
              },
              activeColor: const Color(0xFF5D7893),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$order. $title',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF263746),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF687887),
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MaintenanceStepPreviewTile extends StatelessWidget {
  final int order;
  final String title;
  final String description;

  const MaintenanceStepPreviewTile({
    super.key,
    required this.order,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E0D8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              order.toString(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: const Color(0xFF5D7893),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF263746),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF687887),
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
