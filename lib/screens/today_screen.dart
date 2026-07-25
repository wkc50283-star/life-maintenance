import 'package:flutter/material.dart';

import '../app/app_composition_root.dart';
import '../app/ui_tokens.dart';
import '../diagnostics/runtime_diagnostics.dart';
import '../models/enums.dart';
import '../models/history_projection.dart';
import '../models/item.dart';
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
import '../widgets/ui_v2_components.dart';
import 'task_reminder_screens.dart';
import 'work_case_screens.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({
    super.key,
    ScheduleRepository? scheduleRepository,
    this.onQuickAdd,
  }) : _scheduleRepositoryOverride = scheduleRepository;

  final ScheduleRepository? _scheduleRepositoryOverride;
  final VoidCallback? onQuickAdd;

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

    final hasItems = localItems.isNotEmpty;

    return ListView(
      key: const ValueKey('overview-scroll'),
      padding: UiInsets.pageCompact,
      children: [
        UiMotionEntrance(
          duration: UiMotion.standard,
          child: _OverviewHeader(
            onQuickAdd: widget.onQuickAdd,
            onViewReminders: _runtime.taskReminderRuntime == null
                ? null
                : _openReminderList,
          ),
        ),
        if (!hasItems) ...[
          UiMotionEntrance(
            key: const ValueKey('overview-empty-items'),
            duration: UiMotion.standard,
            child: UiEmptyState(
              icon: Icons.inventory_2_outlined,
              title: '還沒有生活項目',
              description: '拍一張、說一句或輸入名稱開始',
              action: widget.onQuickAdd == null
                  ? null
                  : UiPrimaryButton(
                      onPressed: widget.onQuickAdd,
                      label: '新增生活項目',
                      icon: Icons.add_rounded,
                    ),
            ),
          ),
        ] else ...[
          if (reminders.isNotEmpty)
            UiMotionEntrance(
              key: const ValueKey('overview-section-reminders'),
              duration: UiMotion.standard,
              child: _OverviewSection(
                title: '今天需處理',
                icon: Icons.notifications_none_rounded,
                description: '今天到期或仍需要留意的提醒。',
                actionLabel: _runtime.taskReminderRuntime == null
                    ? null
                    : '查看全部',
                onAction: _runtime.taskReminderRuntime == null
                    ? null
                    : _openReminderList,
                children: [
                  for (final task in reminders)
                    _OverviewFactCard(
                      icon: Icons.notifications_none_rounded,
                      title: task.title,
                      subtitle: _itemName(task.itemId, localItems),
                      detail: '原定 ${_formatDate(task.dueDate)}',
                      status: _labelForStatus(task.status),
                      statusTone: task.status == TaskStatus.overdue
                          ? UiStatusTone.warning
                          : UiStatusTone.info,
                      semanticLabel: '開啟提醒：${task.title}',
                      onTap: () => _openTaskDetail(task.id),
                    ),
                ],
              ),
            ),
          if (_openCases.isNotEmpty)
            UiMotionEntrance(
              key: const ValueKey('overview-section-cases'),
              duration: UiMotion.emphasized,
              child: _OverviewSection(
                title: '進行中案件',
                icon: Icons.handyman_outlined,
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
                children: [
                  for (final entry in _openCases.take(3))
                    _OverviewFactCard(
                      icon: Icons.handyman_outlined,
                      title: entry.workCase.title,
                      subtitle: entry.itemName,
                      detail: _caseDetail(entry),
                      status: _labelForCaseStatus(entry.workCase.status),
                      statusTone:
                          entry.workCase.status == WorkCaseStatus.waiting
                          ? UiStatusTone.warning
                          : UiStatusTone.info,
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
                ],
              ),
            ),
          if (_recentCompletions.isNotEmpty)
            UiMotionEntrance(
              key: const ValueKey('overview-section-completions'),
              duration: UiMotion.emphasized,
              child: _OverviewSection(
                title: '最近完成',
                icon: Icons.history_rounded,
                description: '近期已處理完成並留在正式史略中的紀錄。',
                children: [
                  for (final completion in _recentCompletions)
                    _OverviewFactCard(
                      icon: Icons.check_circle_outline,
                      title: _historyEntryTitle(completion.entry),
                      subtitle: completion.itemName,
                      detail: _formatDate(completion.entry.occurredAt),
                      status: '已完成',
                      statusTone: UiStatusTone.success,
                    ),
                ],
              ),
            ),
        ],
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

  Future<void> _openReminderList() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const TaskReminderListScreen()),
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
        padding: const EdgeInsets.all(UiSpace.md),
        child: UiEmptyState(
          icon: Icons.refresh_outlined,
          title: '暫時無法讀取生活總覽。',
          description: '資料仍完整保留，可以稍後再次讀取。',
          action: OutlinedButton(onPressed: onRetry, child: const Text('重新讀取')),
        ),
      ),
    );
  }
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

class _OverviewHeader extends StatelessWidget {
  const _OverviewHeader({this.onQuickAdd, this.onViewReminders});

  final VoidCallback? onQuickAdd;
  final VoidCallback? onViewReminders;

  @override
  Widget build(BuildContext context) => UiCompactPageHeader(
    title: '生活總覽',
    description: '看看現在需要處理與最近完成的生活事項。',
    action: onQuickAdd == null && onViewReminders == null
        ? null
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onViewReminders != null)
                IconButton(
                  key: const ValueKey('overview-all-reminders'),
                  tooltip: '查看全部提醒',
                  onPressed: onViewReminders,
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
              if (onQuickAdd != null)
                IconButton(
                  key: const ValueKey('overview-quick-add'),
                  tooltip: '新增生活項目',
                  onPressed: onQuickAdd,
                  icon: const Icon(Icons.add_circle_rounded),
                ),
            ],
          ),
  );
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({
    required this.title,
    required this.icon,
    required this.description,
    required this.children,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final IconData icon;
  final String description;
  final List<Widget> children;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: UiSpace.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UiSectionHeader(
          title: title,
          icon: icon,
          description: description,
          actionLabel: actionLabel,
          onAction: onAction,
        ),
        const SizedBox(height: UiSpace.sm),
        ...children,
      ],
    ),
  );
}

class _OverviewFactCard extends StatelessWidget {
  const _OverviewFactCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.status,
    this.statusTone = UiStatusTone.info,
    this.onTap,
    this.semanticLabel,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String detail;
  final String status;
  final UiStatusTone statusTone;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return UiActionCard(
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: UiColors.iconSurface,
                borderRadius: BorderRadius.circular(UiRadius.control),
              ),
              child: Icon(icon, color: UiColors.primary, size: 19),
            ),
            const SizedBox(width: UiSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: UiColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: UiColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    detail,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: UiColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            UiStatusTag(label: status, tone: statusTone),
          ],
        ),
      ),
    );
  }
}
