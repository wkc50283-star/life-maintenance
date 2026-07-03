import 'package:flutter/material.dart';

class TaskSectionHeader extends StatelessWidget {
  const TaskSectionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '今天要處理',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF263746),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '先把重要的保養事項接住，不讓它漏掉。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF687887),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
