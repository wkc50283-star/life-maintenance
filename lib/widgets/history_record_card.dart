import 'package:flutter/material.dart';

class HistoryRecordCard extends StatelessWidget {
  final String date;
  final String title;
  final String itemName;
  final String recordType;
  final String description;
  final String result;
  final String costLabel;
  final String? photoLabel;
  final IconData icon;

  const HistoryRecordCard({
    super.key,
    required this.date,
    required this.title,
    required this.itemName,
    required this.recordType,
    required this.description,
    required this.result,
    required this.costLabel,
    required this.photoLabel,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
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
                    color: const Color(0xFFE8F0F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: const Color(0xFF5D7893)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: const Color(0xFF263746),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
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
                _ResultTag(label: result),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF4D5D6B),
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaTag(
                  icon: Icons.payments_outlined,
                  label: costLabel,
                ),
                if (photoLabel != null)
                  _MetaTag(
                    icon: Icons.photo_library_outlined,
                    label: photoLabel!,
                  ),
              ],
            ),
          ],
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
        color: const Color(0xFFF0F5F8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: const Color(0xFF5D7893),
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
        color: const Color(0xFFEAF4EA),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFC9DEC9)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: const Color(0xFF456A4A),
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
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFEAD9B8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF7A6338)),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFF7A6338),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
