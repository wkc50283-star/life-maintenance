import 'package:flutter/material.dart';

class TaskCardData {
  final String itemName;
  final String taskName;
  final String cycle;
  final String estimatedTime;
  final String riskLabel;

  const TaskCardData({
    required this.itemName,
    required this.taskName,
    required this.cycle,
    required this.estimatedTime,
    required this.riskLabel,
  });
}

class TaskCard extends StatelessWidget {
  final TaskCardData task;

  const TaskCard({super.key, required this.task});

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
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.build_circle_outlined,
                    color: Color(0xFF5D7893),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.itemName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: const Color(0xFF263746),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        task.taskName,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF4D5D6B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TaskTag(icon: Icons.repeat_outlined, label: task.cycle),
                _TaskTag(
                  icon: Icons.health_and_safety_outlined,
                  label: task.riskLabel,
                ),
                _TaskTag(
                  icon: Icons.schedule_outlined,
                  label: '預估 ${task.estimatedTime}',
                ),
              ],
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('完成'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TaskTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5F8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDDE8EF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF5D7893)),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFF4D5D6B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
