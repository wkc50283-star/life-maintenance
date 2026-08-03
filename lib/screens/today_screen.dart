import 'package:flutter/material.dart';

import '../app/app_composition_root.dart';
import '../app/ui_tokens.dart';
import '../diagnostics/runtime_diagnostics.dart';
import '../models/enums.dart';
import '../models/history_projection.dart';
import '../models/item.dart';
import '../models/milestone_enums.dart';
import '../models/task.dart' as maintenance_task;
import '../models/work_case_enums.dart';
import '../repositories/history_projection_repository.dart';
import '../repositories/item_read_repository.dart';
import '../repositories/schedule_repository.dart';
import '../repositories/task_repository.dart';
import '../services/maintenance_task_service.dart';
import '../widgets/ui_v2_components.dart';
import 'task_reminder_screens.dart';

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
  late HistoryProjectionRepository? _historyRepository;
  late bool _formalWritesEnabled;
  bool _dependenciesInitialized = false;
  List<Item>? _localItems;
  List<maintenance_task.Task>? _localTasks;
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
    final completions = <_RecentCompletion>[];

    for (final item in items) {
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

    completions.sort(
      (left, right) => right.entry.occurredAt.compareTo(left.entry.occurredAt),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _localItems = items;
      _localTasks = currentTasks;
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
    final upcomingFocusItems = _upcomingFocusItems(
      _localTasks ?? const <maintenance_task.Task>[],
      localItems,
      today,
    );

    final hasItems = localItems.isNotEmpty;

    return Stack(
      children: [
        CustomScrollView(
          key: const ValueKey('overview-scroll'),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                UiSpace.md,
                UiSpace.xs,
                UiSpace.md,
                UiSpace.md,
              ),
              sliver: SliverList.list(
                children: [
                  UiMotionEntrance(
                    duration: UiMotion.standard,
                    child: _OverviewHeader(
                      onViewReminders: _runtime.taskReminderRuntime == null
                          ? null
                          : _openReminderList,
                    ),
                  ),
                  if (!hasItems)
                    Padding(
                      padding: const EdgeInsets.only(bottom: UiSpace.lg),
                      child: UiEmptyState(
                        key: const ValueKey('overview-empty-items'),
                        icon: Icons.inventory_2_outlined,
                        title: '還沒有生活項目',
                        description: '拍一張、用語音或輸入名稱開始',
                        action: widget.onQuickAdd == null
                            ? null
                            : UiPrimaryButton(
                                onPressed: widget.onQuickAdd,
                                label: '新增生活項目',
                                icon: Icons.add_rounded,
                              ),
                      ),
                    ),
                  if (reminders.isNotEmpty)
                    UiMotionEntrance(
                      key: const ValueKey('overview-section-reminders'),
                      duration: UiMotion.standard,
                      child: _TodayTasksSection(
                        tasks: reminders,
                        items: localItems,
                        onViewAll: _runtime.taskReminderRuntime == null
                            ? null
                            : _openReminderList,
                        onOpenTask: _openTaskDetail,
                      ),
                    ),
                  if (_recentCompletions.isNotEmpty)
                    UiMotionEntrance(
                      key: const ValueKey('overview-section-completions'),
                      duration: UiMotion.emphasized,
                      child: _RecentCompletionsSection(
                        completions: _recentCompletions,
                      ),
                    ),
                  const _AiSuggestionsSection(),
                  _UpcomingFocusSection(
                    items: upcomingFocusItems,
                    today: today,
                  ),
                ],
              ),
            ),
          ],
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

String _formatHomeDate(DateTime date) {
  const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
  return '${date.month}月${date.day}日 星期${weekdays[date.weekday - 1]}';
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

List<_UpcomingFocusItem> _upcomingFocusItems(
  List<maintenance_task.Task> tasks,
  List<Item> items,
  DateTime today,
) {
  final lastDay = today.add(const Duration(days: 7));
  final itemNames = {for (final item in items) item.id: item.name};
  final upcoming = tasks
      .where(
        (task) =>
            task.status == TaskStatus.pending &&
            !_dateOnly(task.dueDate).isBefore(today) &&
            !_dateOnly(task.dueDate).isAfter(lastDay),
      )
      .map(
        (task) => _UpcomingFocusItem(
          id: task.id,
          dueDate: _dateOnly(task.dueDate),
          itemName: itemNames[task.itemId] ?? '未命名生活項目',
        ),
      )
      .toList();
  upcoming.sort((left, right) {
    final byDate = left.dueDate.compareTo(right.dueDate);
    return byDate != 0 ? byDate : left.id.compareTo(right.id);
  });
  return upcoming.take(4).toList(growable: false);
}

String _relativeFocusDate(DateTime dueDate, DateTime today) {
  final difference = _dateOnly(dueDate).difference(today).inDays;
  if (difference == 0) return '今天';
  if (difference == 1) return '明天';
  final endOfWeek = today.add(Duration(days: 7 - today.weekday));
  if (!dueDate.isAfter(endOfWeek)) return '這週';
  return '${dueDate.month}月${dueDate.day}日';
}

class _UpcomingFocusItem {
  const _UpcomingFocusItem({
    required this.id,
    required this.dueDate,
    required this.itemName,
  });

  final String id;
  final DateTime dueDate;
  final String itemName;
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

class _RecentCompletion {
  const _RecentCompletion({required this.entry, required this.itemName});

  final HistoryEntry entry;
  final String itemName;
}

class _OverviewHeader extends StatelessWidget {
  const _OverviewHeader({this.onViewReminders});

  final VoidCallback? onViewReminders;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? '早安'
        : now.hour < 18
        ? '午安'
        : '晚安';
    return Padding(
      padding: const EdgeInsets.only(top: UiSpace.xxs, bottom: UiSpace.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text('$greeting，國政', style: UiType.pageTitle),
                    ),
                    const SizedBox(width: UiSpace.xs),
                    const Icon(
                      Icons.wb_sunny_outlined,
                      size: 22,
                      color: UiColors.warning,
                    ),
                  ],
                ),
                const SizedBox(height: UiSpace.xxs),
                Text(_formatHomeDate(now), style: UiType.pageIntro),
              ],
            ),
          ),
          if (onViewReminders != null)
            IconButton(
              key: const ValueKey('overview-all-reminders'),
              tooltip: '查看全部提醒',
              onPressed: onViewReminders,
              icon: const Icon(Icons.notifications_none_rounded),
            ),
        ],
      ),
    );
  }
}

class _TodayTasksSection extends StatelessWidget {
  const _TodayTasksSection({
    required this.tasks,
    required this.items,
    required this.onViewAll,
    required this.onOpenTask,
  });

  final List<maintenance_task.Task> tasks;
  final List<Item> items;
  final VoidCallback? onViewAll;
  final ValueChanged<String> onOpenTask;

  @override
  Widget build(BuildContext context) => _HomeListSection(
    title: '今天需要處理（${tasks.length}）',
    actionLabel: '查看全部',
    onAction: onViewAll,
    children: [
      for (var index = 0; index < tasks.length; index++) ...[
        InkWell(
          onTap: () => onOpenTask(tasks[index].id),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: UiSpace.sm),
            child: Row(
              children: [
                const _HomeListIcon(icon: Icons.notifications_none_rounded),
                const SizedBox(width: UiSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tasks[index].title, style: UiType.cardTitle),
                      const SizedBox(height: UiSpace.xxs),
                      Text(
                        _itemName(tasks[index].itemId, items),
                        style: UiType.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: UiSpace.xs),
                Text(
                  _labelForStatus(tasks[index].status),
                  style: UiType.caption,
                ),
                const SizedBox(width: UiSpace.xs),
                const Icon(
                  Icons.check_box_outline_blank_rounded,
                  color: UiColors.iconMuted,
                  semanticLabel: '完成狀態不可在首頁變更',
                ),
              ],
            ),
          ),
        ),
        if (index != tasks.length - 1) const Divider(height: 1),
      ],
    ],
  );
}

class _RecentCompletionsSection extends StatelessWidget {
  const _RecentCompletionsSection({required this.completions});

  final List<_RecentCompletion> completions;

  @override
  Widget build(BuildContext context) => _HomeListSection(
    title: '最近完成',
    actionLabel: '查看全部',
    children: [
      for (var index = 0; index < completions.length; index++) ...[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: UiSpace.sm),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: UiColors.success,
                size: 22,
              ),
              const SizedBox(width: UiSpace.xs),
              const _HomeListIcon(icon: Icons.history_rounded),
              const SizedBox(width: UiSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _historyEntryTitle(completions[index].entry),
                      style: UiType.cardTitle,
                    ),
                    const SizedBox(height: UiSpace.xxs),
                    Text(
                      '${completions[index].itemName} · ${_formatDate(completions[index].entry.occurredAt)}',
                      style: UiType.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (index != completions.length - 1) const Divider(height: 1),
      ],
    ],
  );
}

class _AiSuggestionsSection extends StatelessWidget {
  const _AiSuggestionsSection();

  @override
  Widget build(BuildContext context) => const _HomeListSection(
    title: '告訴我你想記住或處理什麼',
    actionLabel: '查看全部',
    children: [
      Padding(
        padding: EdgeInsets.symmetric(vertical: UiSpace.md),
        child: Row(
          children: [
            _HomeListIcon(icon: Icons.auto_awesome_outlined),
            SizedBox(width: UiSpace.sm),
            Expanded(child: Text('AI 功能尚未啟用', style: UiType.body)),
          ],
        ),
      ),
    ],
  );
}

class _UpcomingFocusSection extends StatelessWidget {
  const _UpcomingFocusSection({required this.items, required this.today});

  final List<_UpcomingFocusItem> items;
  final DateTime today;

  @override
  Widget build(BuildContext context) => _HomeListSection(
    sectionKey: const ValueKey('overview-upcoming-focus'),
    title: '近期需要注意',
    children: items.isEmpty
        ? const [
            Padding(
              padding: EdgeInsets.symmetric(vertical: UiSpace.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HomeListIcon(icon: Icons.center_focus_strong_outlined),
                  SizedBox(width: UiSpace.sm),
                  Expanded(child: Text('近期沒有需要注意的事情', style: UiType.body)),
                ],
              ),
            ),
          ]
        : [
            for (var index = 0; index < items.length; index++) ...[
              _UpcomingFocusRow(item: items[index], today: today),
              if (index != items.length - 1) const Divider(height: 1),
            ],
          ],
  );
}

class _UpcomingFocusRow extends StatelessWidget {
  const _UpcomingFocusRow({required this.item, required this.today});

  final _UpcomingFocusItem item;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final date = _FocusTag(label: _relativeFocusDate(item.dueDate, today));
    const type = _FocusTag(label: '提醒');
    final name = Text(item.itemName, style: UiType.cardTitle);
    final largeText = MediaQuery.textScalerOf(context).scale(14) >= 21;
    return Padding(
      key: ValueKey('overview-focus-${item.id}'),
      padding: const EdgeInsets.symmetric(vertical: UiSpace.sm),
      child: largeText
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                date,
                const SizedBox(height: UiSpace.xs),
                name,
                const SizedBox(height: UiSpace.xs),
                type,
              ],
            )
          : Row(
              children: [
                date,
                const SizedBox(width: UiSpace.sm),
                Expanded(child: name),
                const SizedBox(width: UiSpace.xs),
                type,
              ],
            ),
    );
  }
}

class _FocusTag extends StatelessWidget {
  const _FocusTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: UiSpace.xs,
      vertical: UiSpace.xxs,
    ),
    decoration: BoxDecoration(
      color: UiColors.iconSurface,
      borderRadius: BorderRadius.circular(UiRadius.pill),
    ),
    child: Text(label, style: UiType.caption),
  );
}

class _HomeListSection extends StatelessWidget {
  const _HomeListSection({
    this.sectionKey,
    required this.title,
    required this.children,
    this.actionLabel,
    this.onAction,
  });

  final Key? sectionKey;
  final String title;
  final List<Widget> children;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    key: sectionKey,
    padding: const EdgeInsets.only(bottom: UiSpace.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: UiType.sectionTitle)),
            if (actionLabel != null)
              onAction == null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: UiSpace.xs,
                      ),
                      child: Text(actionLabel!, style: UiType.caption),
                    )
                  : TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ),
        const SizedBox(height: UiSpace.xs),
        UiSurfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: UiSpace.md),
          child: Column(children: children),
        ),
      ],
    ),
  );
}

class _HomeListIcon extends StatelessWidget {
  const _HomeListIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: UiColors.iconSurface,
      borderRadius: BorderRadius.circular(UiRadius.control),
    ),
    child: Icon(icon, color: UiColors.primary, size: 20),
  );
}
