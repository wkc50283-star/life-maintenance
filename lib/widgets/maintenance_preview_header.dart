import 'package:flutter/material.dart';

class MaintenancePreviewHeader extends StatelessWidget {
  final String title;
  final String? itemName;

  const MaintenancePreviewHeader({
    super.key,
    required this.title,
    required this.itemName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFB8CBDC),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: const Color(0xFF263746),
            fontWeight: FontWeight.w800,
          ),
        ),
        if (itemName != null) ...[
          const SizedBox(height: 6),
          Text(
            itemName!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF687887),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
