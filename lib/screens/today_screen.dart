import 'package:flutter/material.dart';

import '../app/app_composition_root.dart';
import '../data/maintenance_card_catalog.dart';
import '../models/enums.dart';
import '../models/item.dart';
import '../models/maintenance_card.dart';
import '../models/task.dart' as maintenance_task;
import '../repositories/item_read_repository.dart';
import '../repositories/schedule_repository.dart';
import '../repositories/task_repository.dart';
import '../services/maintenance_task_service.dart';
import '../widgets/empty_tasks_state.dart';
import '../widgets/maintenance_card_preview_sheet.dart';
import '../widgets/task_card.dart';
import '../widgets/task_section_header.dart';
import '../widgets/today_hero.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key, ScheduleRepository? scheduleRepository})
    : _scheduleRepositoryOverride = scheduleRepository;

  final ScheduleRepository? _scheduleRepositoryOverride;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  late ItemReadRepository _itemRepository;
  late ScheduleRepository _scheduleRepository;
  late TaskRepository _taskRepository;
  late MaintenanceTaskService _taskService;
  bool _dependenciesInitialized = false;
  List<Item>? _localItems;
  List<maintenance_task.Task>? _localTasks;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dependenciesInitialized) {
      return;
    }
    final root = AppCompositionScope.of(context);
    _itemRepository = root.itemReadRepository;
    _scheduleRepository =
        widget._scheduleRepositoryOverride ?? root.scheduleRepository;
    _taskRepository = root.taskRepository;
    _taskService = root.maintenanceTaskService;
    _dependenciesInitialized = true;
    _loadTasks();
  }

  @override
  void activate() {
    super.activate();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final items = await _itemRepository.loadItems();
    final schedules = await _scheduleRepository.loadSchedules();
    final tasks = await _taskRepository.loadTasks();
    final generatedTasks = _taskService.generateDueTasks(
      schedules: schedules,
      existingTasks: tasks,
      today: DateTime.now(),
    );
    if (generatedTasks.isNotEmpty) {
      await _taskRepository.saveGeneratedTasks(generatedTasks);
    }
    final currentTasks = generatedTasks.isEmpty
        ? tasks
        : await _taskRepository.loadTasks();

    if (!mounted) {
      return;
    }

    setState(() {
      _localItems = items;
      _localTasks = currentTasks;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localItems = _localItems ?? const <Item>[];
    final tasks = _localTasks ?? const <maintenance_task.Task>[];

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
                if (_isManualExpiryReminderTask(task)) {
                  final item = _itemForTask(task, localItems: localItems);
                  _showManualExpiryReminderDetailSheet(
                    context,
                    task: task,
                    item: item,
                  );
                  return;
                }

                final item = _itemForTask(task, localItems: localItems);
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
              child: TaskCard(
                task: _taskCardDataFor(task, localItems: localItems),
              ),
            ),
      ],
    );
  }
}

void _showManualExpiryReminderDetailSheet(
  BuildContext context, {
  required maintenance_task.Task task,
  required Item? item,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFF7F3EA),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                '提醒事項',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF263746),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              _ManualExpiryReminderDetailRow(label: '事項名稱', value: task.title),
              _ManualExpiryReminderDetailRow(
                label: '所屬項目',
                value: item?.name ?? '未命名生活項目',
              ),
              _ManualExpiryReminderDetailRow(
                label: '提醒日期',
                value: _formatDate(task.dueDate),
              ),
              _ManualExpiryReminderDetailRow(
                label: '狀態',
                value: _labelForStatus(task.status),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ManualExpiryReminderDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _ManualExpiryReminderDetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E0D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFF5D7893),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF263746),
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

TaskCardData _taskCardDataFor(
  maintenance_task.Task task, {
  required List<Item> localItems,
}) {
  final item = _itemForTask(task, localItems: localItems);
  final card = _cardForTask(task);
  final isManualExpiryReminder = _isManualExpiryReminderTask(task);

  return TaskCardData(
    itemName: item?.name ?? '未命名生活項目',
    taskName: task.title,
    cycle: '到期 ${_formatDate(task.dueDate)}',
    estimatedTime: isManualExpiryReminder
        ? '請確認'
        : '${card?.estimatedMinutes ?? 0} 分鐘',
    riskLabel: isManualExpiryReminder ? '到期提醒' : _labelForStatus(task.status),
  );
}

bool _isManualExpiryReminderTask(maintenance_task.Task task) {
  return task.cardId == 'manual-expiry-reminder';
}

Item? _itemForTask(
  maintenance_task.Task task, {
  required List<Item> localItems,
}) {
  for (final item in localItems) {
    if (item.id == task.itemId) {
      return item;
    }
  }

  return null;
}

MaintenanceCard? _cardForTask(maintenance_task.Task task) {
  return MaintenanceCardCatalog.resolve(
    cardId: task.cardId,
    itemId: task.itemId,
  );
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
