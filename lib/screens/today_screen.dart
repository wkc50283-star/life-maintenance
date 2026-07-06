import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/enums.dart';
import '../models/item.dart';
import '../models/maintenance_card.dart';
import '../models/task.dart' as maintenance_task;
import '../repositories/schedule_local_repository.dart';
import '../repositories/task_local_repository.dart';
import '../services/local_storage_service.dart';
import '../services/maintenance_task_service.dart';
import '../widgets/empty_tasks_state.dart';
import '../widgets/maintenance_card_preview_sheet.dart';
import '../widgets/task_card.dart';
import '../widgets/task_section_header.dart';
import '../widgets/today_hero.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  late final ScheduleLocalRepository _scheduleRepository =
      ScheduleLocalRepository(_storageService);
  late final TaskLocalRepository _taskRepository = TaskLocalRepository(
    _storageService,
  );
  final MaintenanceTaskService _taskService = MaintenanceTaskService();
  List<maintenance_task.Task>? _localTasks;
  bool _hasLocalScheduleOrTaskData = false;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final schedules = await _scheduleRepository.loadSchedules();
    final tasks = await _taskRepository.loadTasks();
    final generatedTasks = _taskService.generateDueTasks(
      schedules: schedules,
      existingTasks: tasks,
      today: DateTime.now(),
    );
    final updatedTasks = generatedTasks.isEmpty
        ? tasks
        : <maintenance_task.Task>[...tasks, ...generatedTasks];

    if (generatedTasks.isNotEmpty) {
      await _taskRepository.saveTasks(updatedTasks);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _localTasks = updatedTasks;
      _hasLocalScheduleOrTaskData =
          schedules.isNotEmpty || updatedTasks.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localTasks = _localTasks;
    final tasks =
        localTasks == null ||
            (!_hasLocalScheduleOrTaskData && localTasks.isEmpty)
        ? MockData.tasks
        : localTasks;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        TodayHero(taskCount: tasks.length),
        const SizedBox(height: 20),
        const TaskSectionHeader(),
        const SizedBox(height: 12),
        if (tasks.isEmpty)
          const EmptyTasksState()
        else
          for (final task in tasks)
            GestureDetector(
              onTap: () {
                final item = _itemForTask(task);
                final card = _cardForTask(task);

                showMaintenanceCardPreview(
                  context,
                  card: card,
                  item: item,
                  maintenanceTypeLabel: card == null
                      ? ''
                      : _labelForMaintenanceType(card.type),
                  riskLevelLabel: card == null
                      ? ''
                      : _labelForRiskLevel(card.riskLevel),
                );
              },
              child: TaskCard(task: _taskCardDataFor(task)),
            ),
      ],
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

String _labelForMaintenanceType(MaintenanceType type) {
  return switch (type) {
    MaintenanceType.cleaning => '清潔',
    MaintenanceType.inspection => '檢查',
    MaintenanceType.replacement => '更換',
    MaintenanceType.repairRecord => '維修紀錄',
    MaintenanceType.expiryReminder => '到期提醒',
    MaintenanceType.constructionRecord => '施工紀錄',
  };
}

String _labelForRiskLevel(RiskLevel riskLevel) {
  return switch (riskLevel) {
    RiskLevel.low => '低風險',
    RiskLevel.medium => '中風險',
    RiskLevel.high => '高風險',
    RiskLevel.unknown => '未知風險',
  };
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}/$month/$day';
}
