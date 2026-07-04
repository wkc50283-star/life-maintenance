import 'package:flutter/material.dart';

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
    final iconColor = highlighted
        ? const Color(0xFF7A6338)
        : const Color(0xFF5D7893);
    final iconBackground = highlighted
        ? const Color(0xFFFFF7E6)
        : const Color(0xFFE8F0F6);
    final borderColor = highlighted
        ? const Color(0xFFEAD9B8)
        : const Color(0xFFE4E0D8);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 14),
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
                                color: const Color(0xFF263746),
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      if (highlighted) const _SafetyBadge(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF4D5D6B),
                      height: 1.4,
                      fontWeight: FontWeight.w600,
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
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFEAD9B8)),
      ),
      child: Text(
        '重要',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xFF7A6338),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
