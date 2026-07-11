import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/enums.dart';
import '../models/item.dart';
import '../models/maintenance_card.dart';
import '../models/maintenance_record.dart';
import '../models/task.dart' as maintenance_task;
import '../repositories/item_local_repository.dart';
import '../repositories/maintenance_record_local_repository.dart';
import '../repositories/schedule_local_repository.dart';
import '../repositories/task_local_repository.dart';
import '../services/local_storage_service.dart';
import '../services/maintenance_task_service.dart';
import '../widgets/completion_record_sheet.dart';
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
  late final ItemLocalRepository _itemRepository = ItemLocalRepository(
    _storageService,
  );
  late final MaintenanceRecordLocalRepository _recordRepository =
      MaintenanceRecordLocalRepository(_storageService);
  late final ScheduleLocalRepository _scheduleRepository =
      ScheduleLocalRepository(_storageService);
  late final TaskLocalRepository _taskRepository = TaskLocalRepository(
    _storageService,
  );
  final MaintenanceTaskService _taskService = MaintenanceTaskService();
  final Set<String> _completingTaskIds = <String>{};
  List<Item>? _localItems;
  List<maintenance_task.Task>? _localTasks;
  bool _hasLocalScheduleOrTaskData = false;

  @override
  void initState() {
    super.initState();
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
      _localItems = items;
      _localTasks = updatedTasks;
      _hasLocalScheduleOrTaskData =
          schedules.isNotEmpty || updatedTasks.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localItems = _localItems ?? const <Item>[];
    final localTasks = _localTasks;
    final isUsingMockTasks =
        localTasks == null ||
        (!_hasLocalScheduleOrTaskData && localTasks.isEmpty);
    final tasks = isUsingMockTasks ? MockData.tasks : localTasks;

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
                  onCompleteSteps: () {
                    Future<void>.delayed(Duration.zero, () {
                      if (!mounted) {
                        return;
                      }

                      _showCompleteRecordSheet(
                        task,
                        isUsingMockTasks: isUsingMockTasks,
                      );
                    });
                  },
                );
              },
              child: TaskCard(
                task: _taskCardDataFor(task, localItems: localItems),
                onComplete: () {
                  _showCompleteRecordSheet(
                    task,
                    isUsingMockTasks: isUsingMockTasks,
                  );
                },
              ),
            ),
      ],
    );
  }

  Future<void> _showCompleteRecordSheet(
    maintenance_task.Task task, {
    required bool isUsingMockTasks,
  }) async {
    if (isUsingMockTasks) {
      await _completeTask(task, isUsingMockTasks: true);
      return;
    }

    final recordData = await showCompletionRecordSheet(context);

    if (recordData == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    await _completeTask(
      task,
      isUsingMockTasks: isUsingMockTasks,
      workDescription: recordData.workDescription,
      cost: recordData.cost,
      vendorName: recordData.vendorName,
      partsChanged: recordData.partsChanged,
      note: recordData.note,
      result: recordData.result,
    );
  }

  Future<void> _completeTask(
    maintenance_task.Task task, {
    required bool isUsingMockTasks,
    String? workDescription,
    int? cost,
    String? vendorName,
    List<String> partsChanged = const [],
    String? note,
    String? result,
  }) async {
    if (isUsingMockTasks) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('展示任務無法完成')));
      return;
    }

    if (_completingTaskIds.contains(task.id)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('此任務正在完成')));
      return;
    }

    _completingTaskIds.add(task.id);

    try {
      final localTasks = _localTasks;
      if (localTasks == null) {
        return;
      }

      final taskIndex = localTasks.indexWhere(
        (localTask) => localTask.id == task.id,
      );
      if (taskIndex == -1) {
        return;
      }

      final currentTask = localTasks[taskIndex];
      if (currentTask.status == TaskStatus.completed) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('此任務已完成')));
        return;
      }

      final now = DateTime.now();
      final updatedTasks = <maintenance_task.Task>[...localTasks];
      updatedTasks[taskIndex] = currentTask.copyWith(
        status: TaskStatus.completed,
        completedAt: now,
        overdue: false,
      );

      await _taskRepository.saveTasks(updatedTasks);
      final records = await _recordRepository.loadRecords();
      final hasExistingRecord = records.any(
        (record) => record.taskId == task.id,
      );
      if (hasExistingRecord) {
        if (!mounted) {
          return;
        }

        setState(() {
          _localTasks = updatedTasks;
          _hasLocalScheduleOrTaskData = true;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('此任務已完成')));
        return;
      }

      final updatedRecords = <MaintenanceRecord>[
        ...records,
        MaintenanceRecord(
          id: now.millisecondsSinceEpoch.toString(),
          itemId: task.itemId,
          taskId: task.id,
          recordType: _recordTypeForTask(task),
          date: now,
          title: task.title,
          createdAt: now,
          workDescription: workDescription,
          partsChanged: partsChanged,
          cost: cost,
          vendorName: vendorName,
          result: result ?? '已完成',
          note: note ?? _recordNoteForTask(task),
        ),
      ];
      await _recordRepository.saveRecords(updatedRecords);

      if (!mounted) {
        return;
      }

      setState(() {
        _localTasks = updatedTasks;
        _hasLocalScheduleOrTaskData = true;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已完成任務並建立紀錄')));
    } finally {
      _completingTaskIds.remove(task.id);
    }
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
                '需要你記住的事',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF263746),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              _ManualExpiryReminderDetailRow(label: '事項名稱', value: task.title),
              _ManualExpiryReminderDetailRow(
                label: '所屬項目',
                value: item?.name ?? '未命名物品',
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
    itemName: item?.name ?? '未命名物品',
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

RecordType _recordTypeForTask(maintenance_task.Task task) {
  return _isManualExpiryReminderTask(task)
      ? RecordType.expiryHandled
      : RecordType.regularMaintenance;
}

String _recordNoteForTask(maintenance_task.Task task) {
  return _isManualExpiryReminderTask(task) ? '由到期提醒任務完成後自動建立' : '由保養任務完成後自動建立';
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
