import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/enums.dart';
import '../models/item.dart';
import '../models/maintenance_card.dart';
import '../models/task.dart' as maintenance_task;
import '../widgets/task_card.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tasks = MockData.tasks;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _TodayHero(taskCount: tasks.length),
        const SizedBox(height: 20),
        const _TaskSectionHeader(),
        const SizedBox(height: 12),
        if (tasks.isEmpty)
          const _EmptyTasksState()
        else
          for (final task in tasks) TaskCard(task: _taskCardDataFor(task)),
      ],
    );
  }
}

class _TodayHero extends StatelessWidget {
  final int taskCount;

  const _TodayHero({required this.taskCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5D7893), Color(0xFF8FA4B8)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A263746),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.24),
                  ),
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'v0.1',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          const Text(
            '生活維護管家',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '軍規邏輯，民用保養',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.86),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.today_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  '今日 $taskCount 件待處理',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTasksState extends StatelessWidget {
  const _EmptyTasksState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4E0D8)),
      ),
      child: Text(
        '目前沒有待處理任務。',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF687887),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

TaskCardData _taskCardDataFor(maintenance_task.Task task) {
  final item = _itemForTask(task);
  final card = _cardForTask(task);

  return TaskCardData(
    itemName: item?.name ?? '未命名物品',
    taskName: task.title,
    cycle: '到期 ${_formatDate(task.dueDate)}',
    estimatedTime: '${card?.estimatedMinutes ?? 0} 分鐘',
    riskLabel: _labelForStatus(task.status),
  );
}

Item? _itemForTask(maintenance_task.Task task) {
  for (final item in MockData.items) {
    if (item.id == task.itemId) {
      return item;
    }
  }

  return null;
}

MaintenanceCard? _cardForTask(maintenance_task.Task task) {
  for (final card in MockData.maintenanceCards) {
    if (card.id == task.cardId) {
      return card;
    }
  }

  return null;
}

String _labelForStatus(TaskStatus status) {
  return switch (status) {
    TaskStatus.pending => '待處理',
    TaskStatus.completed => '已完成',
    TaskStatus.overdue => '已逾期',
    TaskStatus.postponed => '稍後提醒',
    TaskStatus.canceled => '已取消',
  };
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}/$month/$day';
}

class _TaskSectionHeader extends StatelessWidget {
  const _TaskSectionHeader();

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
