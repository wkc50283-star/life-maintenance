import 'package:flutter/material.dart';

import '../app/app_composition_root.dart';
import '../diagnostics/runtime_diagnostics.dart';
import '../models/enums.dart';
import '../models/history_projection.dart';
import '../models/item.dart';
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
import '../widgets/task_card.dart';
import '../widgets/today_hero.dart';
import 'task_reminder_screens.dart';
import 'work_case_screens.dart';

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
  Object? _loadError;

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
    try {
      await _loadOverviewData();
    } catch (error, stackTrace) {
      RuntimeDiagnostics.report(
        stage: 'home_overview.load',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      setState(() => _loadError = error);
    }
  }

  Future<void> _loadOverviewData() async {
    final items = await RuntimeDiagnostics.guard(
      'home_overview.items.load',
      _itemRepository.loadItems,
    );
    final schedules = await RuntimeDiagnostics.guard(
      'home_overview.schedules.load',
      _scheduleRepository.loadSchedules,
    );
    final tasks = await RuntimeDiagnostics.guard(
      'home_overview.tasks.load',
      _taskRepository.loadTasks,
    );
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
      _loadError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return _OverviewLoadFailure(onRetry: _retryOverview);
    }
    if (_localItems == null || _localTasks == null) {
      return const Center(child: CircularProgressIndicator());
    }
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
        _OverviewSectionHeader(
          title: '今日提醒',
          description: '今天到期或仍需要留意的提醒。',
          actionLabel: _runtime.taskReminderRuntime == null ? null : '查看全部',
          onAction: _runtime.taskReminderRuntime == null
              ? null
              : () async {
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => const TaskReminderListScreen(),
                    ),
                  );
                  await _loadOverview();
                },
        ),
        const SizedBox(height: 12),
        if (reminders.isEmpty)
          const _OverviewEmptyState(message: '今天沒有需要留意的提醒。')
        else
          for (final task in reminders)
            Semantics(
              button: true,
              focusable: true,
              label: '開啟提醒：${task.title}',
              onTap: () => _openTaskDetail(task.id),
              child: ExcludeSemantics(
                child: InkWell(
                  onTap: () => _openTaskDetail(task.id),
                  child: TaskCard(
                    task: _taskCardDataFor(task, localItems: localItems),
                  ),
                ),
              ),
            ),
        const SizedBox(height: 20),
        _OverviewSectionHeader(
          title: '進行中案件',
          description: '已經開始處理、仍在進行或等待中的事情。',
          actionLabel: _workCaseRuntime == null ? null : '全部案件',
          onAction: _workCaseRuntime == null
              ? null
              : () async {
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => const WorkCaseListScreen(),
                    ),
                  );
                  await _loadOverview();
                },
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
              onTap: () async {
                final changed = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => WorkCaseDetailScreen(
                      workCaseId: entry.workCase.id,
                      itemName: entry.itemName,
                    ),
                  ),
                );
                if (changed == true) await _loadOverview();
              },
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

  Future<void> _openTaskDetail(String taskId) async {
    final detail = await _runtime.taskReminderRuntime?.findReminder(taskId);
    if (!mounted || detail == null) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TaskReminderDetailScreen(initialDetail: detail),
      ),
    );
    await _loadOverview();
  }

  void _retryOverview() {
    setState(() => _loadError = null);
    _loadOverview();
  }
}

class _OverviewLoadFailure extends StatelessWidget {
  const _OverviewLoadFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.refresh_outlined, size: 40),
            const SizedBox(height: 12),
            Text(
              '暫時無法讀取生活總覽。',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('重新讀取')),
          ],
        ),
      ),
    );
  }
}

TaskCardData _taskCardDataFor(
  maintenance_task.Task task, {
  required List<Item> localItems,
}) {
  final item = _itemForTask(task, localItems: localItems);
  final isManualExpiryReminder = _isManualExpiryReminderTask(task);

  return TaskCardData(
    itemName: item?.name ?? '未命名生活項目',
    taskName: task.title,
    cycle: '原定 ${_formatDate(task.dueDate)}',
    estimatedTime: isManualExpiryReminder ? '請確認' : '提醒事項',
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

String _labelForStatus(TaskStatus status) {
  return switch (status) {
    TaskStatus.pending => '已安排',
    TaskStatus.completed => '已完成',
    TaskStatus.overdue => '日期已過',
    TaskStatus.postponed => '稍後提醒',
    TaskStatus.canceled => '已取消',
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
      task.status == TaskStatus.canceled ||
      task.status == TaskStatus.postponed) {
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
    MilestoneStatus.pending => '條件未到',
    MilestoneStatus.reached => '條件已到',
    MilestoneStatus.acknowledged => '已確認',
    MilestoneStatus.inProgress => '處理中',
    MilestoneStatus.completed => '已完成',
    MilestoneStatus.canceled => '已取消',
    MilestoneStatus.archived => '已封存',
  };
}

String _milestoneTriggerLabel(Milestone milestone) {
  if (milestone.triggerDate case final date?) {
    return '預定日期 ${_formatDate(date)}';
  }
  if (milestone.thresholdValue case final value?) {
    final formatted = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
    return '條件 $formatted ${milestone.thresholdUnit ?? ''}'.trim();
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
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF263746),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (actionLabel != null && onAction != null)
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
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
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String detail;
  final String status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
      ),
    );
  }
}
