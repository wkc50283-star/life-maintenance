import 'package:flutter/material.dart';

import '../app/app_composition_root.dart';
import '../data/maintenance_card_catalog.dart';
import '../models/enums.dart';
import '../models/history_projection.dart';
import '../models/item.dart';
import '../models/maintenance_card.dart';
import '../models/milestone.dart';
import '../models/milestone_enums.dart';
import '../models/task.dart' as maintenance_task;
import '../models/work_case.dart';
import '../models/work_case_enums.dart';
import '../models/work_case_update.dart';
import '../repositories/history_projection_repository.dart';
import '../repositories/item_read_repository.dart';
import '../repositories/schedule_repository.dart';
import '../repositories/task_repository.dart';
import '../repositories/work_case_runtime.dart';
import '../services/maintenance_task_service.dart';
import '../widgets/maintenance_card_preview_sheet.dart';
import '../widgets/task_card.dart';
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
  late AppRuntimeDependencies _runtime;
  late WorkCaseRuntime? _workCaseRuntime;
  late HistoryProjectionRepository? _historyRepository;
  late bool _formalWritesEnabled;
  bool _dependenciesInitialized = false;
  List<Item>? _localItems;
  List<maintenance_task.Task>? _localTasks;
  List<_OpenCaseOverview> _openCases = const [];
  List<Milestone> _activeMilestones = const [];
  List<_RecentCompletion> _recentCompletions = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dependenciesInitialized) {
      return;
    }
    final root = AppCompositionScope.of(context);
    _runtime = root;
    _itemRepository = root.itemReadRepository;
    _scheduleRepository =
        widget._scheduleRepositoryOverride ?? root.scheduleRepository;
    _taskRepository = root.taskRepository;
    _taskService = root.maintenanceTaskService;
    _workCaseRuntime = root.workCaseRuntime;
    _historyRepository = root.historyProjectionRepository;
    _formalWritesEnabled = root.formalWritesEnabled;
    _dependenciesInitialized = true;
    _loadOverview();
  }

  @override
  void activate() {
    super.activate();
    _loadOverview();
  }

  Future<void> _loadOverview() async {
    final items = await _itemRepository.loadItems();
    final schedules = await _scheduleRepository.loadSchedules();
    final tasks = await _taskRepository.loadTasks();
    final generatedTasks = _taskService.generateDueTasks(
      schedules: schedules,
      existingTasks: tasks,
      today: DateTime.now(),
    );
    if (generatedTasks.isNotEmpty && _formalWritesEnabled) {
      await _taskRepository.saveGeneratedTasks(generatedTasks);
    }
    final currentTasks = generatedTasks.isEmpty || !_formalWritesEnabled
        ? tasks
        : await _taskRepository.loadTasks();
    final openCases = <_OpenCaseOverview>[];
    final milestones = <Milestone>[];
    final completions = <_RecentCompletion>[];

    for (final item in items) {
      final caseRuntime = _workCaseRuntime;
      if (caseRuntime != null) {
        final cases = await caseRuntime.listCasesForItem(item.id);
        for (final workCase in cases.where((entry) => entry.isOpen)) {
          final updates = await caseRuntime.listUpdatesForCase(workCase.id);
          updates.sort(
            (left, right) => right.occurredAt.compareTo(left.occurredAt),
          );
          openCases.add(
            _OpenCaseOverview(
              workCase: workCase,
              itemName: item.name,
              latestUpdate: updates.isEmpty ? null : updates.first,
            ),
          );
        }
      }

      final milestoneRepository = _runtime.milestoneRepository;
      if (milestoneRepository != null) {
        milestones.addAll(
          (await milestoneRepository.listForItem(
            item.id,
          )).where((milestone) => !milestone.isClosed),
        );
      }

      final historyRepository = _historyRepository;
      if (historyRepository != null) {
        final projection = await historyRepository.projectForItem(item.id);
        completions.addAll(
          projection.entries
              .where(_isCompletedHistoryEntry)
              .map(
                (entry) => _RecentCompletion(entry: entry, itemName: item.name),
              ),
        );
      }
    }

    openCases.sort(
      (left, right) =>
          right.workCase.updatedAt.compareTo(left.workCase.updatedAt),
    );
    milestones.sort(_compareMilestones);
    completions.sort(
      (left, right) => right.entry.occurredAt.compareTo(left.entry.occurredAt),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _localItems = items;
      _localTasks = currentTasks;
      _openCases = openCases;
      _activeMilestones = milestones;
      _recentCompletions = completions.take(3).toList(growable: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final localItems = _localItems ?? const <Item>[];
    final today = _dateOnly(DateTime.now());
    final reminders = (_localTasks ?? const <maintenance_task.Task>[])
        .where((task) => _needsAttention(task, today))
        .toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        TodayHero(
          reminderCount: reminders.length,
          openCaseCount: _openCases.length,
          milestoneCount: _activeMilestones.length,
        ),
        const SizedBox(height: 20),
        const _OverviewSectionHeader(
          title: '今日提醒',
          description: '今天到期或仍需要留意的提醒。',
        ),
        const SizedBox(height: 12),
        if (reminders.isEmpty)
          const _OverviewEmptyState(message: '今天沒有需要留意的提醒。')
        else
          for (final task in reminders)
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
        const SizedBox(height: 20),
        const _OverviewSectionHeader(
          title: '進行中案件',
          description: '已經開始處理、仍在進行或等待中的事情。',
        ),
        const SizedBox(height: 12),
        if (_openCases.isEmpty)
          const _OverviewEmptyState(message: '目前沒有進行中的案件。')
        else
          for (final entry in _openCases.take(3))
            _OverviewFactCard(
              icon: Icons.handyman_outlined,
              title: entry.workCase.title,
              subtitle: entry.itemName,
              detail: _caseDetail(entry),
              status: _labelForCaseStatus(entry.workCase.status),
            ),
        const SizedBox(height: 20),
        const _OverviewSectionHeader(
          title: '階段性重點',
          description: '生活項目正在接近或已達到的重要階段。',
        ),
        const SizedBox(height: 12),
        if (_activeMilestones.isEmpty)
          const _OverviewEmptyState(message: '目前沒有需要留意的階段性重點。')
        else
          for (final milestone in _activeMilestones.take(3))
            _OverviewFactCard(
              icon: Icons.flag_outlined,
              title: milestone.title,
              subtitle: _itemName(milestone.itemId, localItems),
              detail: _milestoneTriggerLabel(milestone),
              status: _labelForMilestoneStatus(milestone.status),
            ),
        const SizedBox(height: 20),
        const _OverviewSectionHeader(
          title: '最近完成',
          description: '近期已處理完成並留在正式史略中的紀錄。',
        ),
        const SizedBox(height: 12),
        if (_recentCompletions.isEmpty)
          const _OverviewEmptyState(message: '目前還沒有完成紀錄。')
        else
          for (final completion in _recentCompletions)
            _OverviewFactCard(
              icon: Icons.check_circle_outline,
              title: _historyEntryTitle(completion.entry),
              subtitle: completion.itemName,
              detail: _formatDate(completion.entry.occurredAt),
              status: '已完成',
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

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

bool _needsAttention(maintenance_task.Task task, DateTime today) {
  if (task.status == TaskStatus.completed ||
      task.status == TaskStatus.canceled) {
    return false;
  }
  return !_dateOnly(task.dueDate).isAfter(today);
}

bool _isCompletedHistoryEntry(HistoryEntry entry) {
  return switch (entry) {
    WorkCaseHistoryEntry(:final workCase) =>
      workCase.status == WorkCaseStatus.completed,
    MaintenanceRecordHistoryEntry() => true,
    TaskHistoryEntry(:final task) => task.status == TaskStatus.completed.name,
    MilestoneHistoryEntry(:final milestone) =>
      milestone.status == MilestoneStatus.completed,
  };
}

int _compareMilestones(Milestone left, Milestone right) {
  final byStatus = _milestonePriority(
    left.status,
  ).compareTo(_milestonePriority(right.status));
  if (byStatus != 0) return byStatus;
  final leftDate = left.triggerDate ?? left.updatedAt;
  final rightDate = right.triggerDate ?? right.updatedAt;
  return leftDate.compareTo(rightDate);
}

int _milestonePriority(MilestoneStatus status) {
  return switch (status) {
    MilestoneStatus.inProgress => 0,
    MilestoneStatus.reached => 1,
    MilestoneStatus.acknowledged => 2,
    MilestoneStatus.pending => 3,
    MilestoneStatus.completed ||
    MilestoneStatus.canceled ||
    MilestoneStatus.archived => 4,
  };
}

String _caseDetail(_OpenCaseOverview overview) {
  final update = overview.latestUpdate;
  final nextAction = _nonEmpty(update?.nextAction);
  if (nextAction != null) return '下一步：$nextAction';
  final waitingReason = _nonEmpty(update?.waitingReason);
  if (waitingReason != null) return '等待：$waitingReason';
  final description = _nonEmpty(update?.description);
  if (description != null) return description;
  return '最後更新 ${_formatDate(overview.workCase.updatedAt)}';
}

String _labelForCaseStatus(WorkCaseStatus status) {
  return switch (status) {
    WorkCaseStatus.notStarted => '尚未開始',
    WorkCaseStatus.inProgress => '處理中',
    WorkCaseStatus.waiting => '等待中',
    WorkCaseStatus.completed => '已完成',
    WorkCaseStatus.canceled => '已取消',
  };
}

String _labelForMilestoneStatus(MilestoneStatus status) {
  return switch (status) {
    MilestoneStatus.pending => '尚未達標',
    MilestoneStatus.reached => '已達標',
    MilestoneStatus.acknowledged => '已確認',
    MilestoneStatus.inProgress => '處理中',
    MilestoneStatus.completed => '已完成',
    MilestoneStatus.canceled => '已取消',
    MilestoneStatus.archived => '已封存',
  };
}

String _milestoneTriggerLabel(Milestone milestone) {
  if (milestone.triggerDate case final date?) {
    return '目標日期 ${_formatDate(date)}';
  }
  if (milestone.thresholdValue case final value?) {
    final formatted = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
    return '目標 $formatted ${milestone.thresholdUnit ?? ''}'.trim();
  }
  if (_nonEmpty(milestone.lifeStageCode) case final stage?) {
    return '人生階段：$stage';
  }
  return _nonEmpty(milestone.description) ?? '手動建立的階段性重點';
}

String _historyEntryTitle(HistoryEntry entry) {
  return switch (entry) {
    WorkCaseHistoryEntry(:final workCase) => workCase.title,
    MaintenanceRecordHistoryEntry(:final record) => record.title,
    TaskHistoryEntry(:final task) => task.title,
    MilestoneHistoryEntry(:final milestone) => milestone.title,
  };
}

String _itemName(String itemId, List<Item> items) {
  for (final item in items) {
    if (item.id == itemId) return item.name;
  }
  return '未命名生活項目';
}

String? _nonEmpty(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

class _OpenCaseOverview {
  const _OpenCaseOverview({
    required this.workCase,
    required this.itemName,
    required this.latestUpdate,
  });

  final WorkCase workCase;
  final String itemName;
  final WorkCaseUpdate? latestUpdate;
}

class _RecentCompletion {
  const _RecentCompletion({required this.entry, required this.itemName});

  final HistoryEntry entry;
  final String itemName;
}

class _OverviewSectionHeader extends StatelessWidget {
  const _OverviewSectionHeader({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: const Color(0xFF263746),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF687887)),
        ),
      ],
    );
  }
}

class _OverviewEmptyState extends StatelessWidget {
  const _OverviewEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E0D8)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF687887),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _OverviewFactCard extends StatelessWidget {
  const _OverviewFactCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.status,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String detail;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0F6),
                borderRadius: BorderRadius.circular(15),
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF263746),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF5D7893),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    detail,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF687887),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              status,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: const Color(0xFF4D5D6B),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
