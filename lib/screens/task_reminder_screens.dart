import 'package:flutter/material.dart';

import '../app/app_composition_root.dart';
import '../app/ui_tokens.dart';
import '../models/enums.dart';
import '../models/work_case.dart';
import '../models/work_case_enums.dart';
import '../repositories/repository_constraint_exception.dart';
import '../repositories/task_reminder_runtime.dart';
import '../widgets/ui_v2_components.dart';

class TaskReminderListScreen extends StatefulWidget {
  const TaskReminderListScreen({super.key});

  @override
  State<TaskReminderListScreen> createState() => _TaskReminderListScreenState();
}

class _TaskReminderListScreenState extends State<TaskReminderListScreen> {
  TaskReminderRuntime? _runtime;
  List<TaskReminderDetail>? _reminders;
  Object? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_runtime == null && _error == null) {
      _runtime = AppCompositionScope.of(context).taskReminderRuntime;
      _load();
    }
  }

  Future<void> _load() async {
    final runtime = _runtime;
    if (runtime == null) {
      setState(() => _error = StateError('正式提醒服務目前無法使用。'));
      return;
    }
    try {
      final values = await runtime.loadReminders();
      final reminders = values
          .where(
            (value) =>
                value.task.status != TaskStatus.completed &&
                value.task.status != TaskStatus.canceled,
          )
          .toList(growable: false);
      if (!mounted) return;
      setState(() {
        _reminders = reminders;
        _error = null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('提醒事項')),
      body: switch ((_reminders, _error)) {
        (null, null) => const Center(child: CircularProgressIndicator()),
        (null, _) => _LoadFailure(onRetry: _retry),
        (final reminders?, _) when reminders.isEmpty => const _EmptyState(),
        (final reminders?, _) => RefreshIndicator(
          onRefresh: _load,
          child: ListView.separated(
            padding: UiInsets.page,
            itemCount: reminders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final reminder = reminders[index];
              return _ReminderCard(
                detail: reminder,
                onTap: () => _openDetail(reminder),
              );
            },
          ),
        ),
      },
    );
  }

  void _retry() {
    setState(() => _error = null);
    _load();
  }

  Future<void> _openDetail(TaskReminderDetail detail) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TaskReminderDetailScreen(initialDetail: detail),
      ),
    );
    if (changed == true) await _load();
  }
}

class TaskReminderDetailScreen extends StatefulWidget {
  const TaskReminderDetailScreen({super.key, required this.initialDetail});

  final TaskReminderDetail initialDetail;

  @override
  State<TaskReminderDetailScreen> createState() =>
      _TaskReminderDetailScreenState();
}

class _TaskReminderDetailScreenState extends State<TaskReminderDetailScreen> {
  late TaskReminderDetail _detail = widget.initialDetail;
  TaskReminderRuntime? _runtime;
  bool _saving = false;
  bool _changed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _runtime ??= AppCompositionScope.of(context).taskReminderRuntime;
  }

  @override
  Widget build(BuildContext context) {
    final task = _detail.task;
    final paused = task.status == TaskStatus.postponed;
    final terminal =
        task.status == TaskStatus.completed ||
        task.status == TaskStatus.canceled;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('提醒詳情')),
        body: ListView(
          padding: UiInsets.pageCompact,
          children: [
            _ReminderHero(detail: _detail),
            const SizedBox(height: 18),
            _InformationCard(
              title: '提醒內容',
              rows: [
                ('所屬生活項目', _detail.itemName),
                ('提醒日期', _formatDate(task.dueDate)),
                ('目前狀態', _statusLabel(task.status)),
              ],
            ),
            const SizedBox(height: 14),
            _InformationCard(
              title: '提醒來源',
              rows: [
                ('來源類型', _sourceKindLabel(_detail.sourceKind)),
                ('來源項目', _detail.sourceTitle),
                if (_text(_detail.sourceDescription) case final value?)
                  ('說明', value),
                if (_detail.scheduleCycleType case final cycle?)
                  (
                    '排程規則',
                    _scheduleLabel(cycle, _detail.scheduleInterval ?? 1),
                  ),
                if (_detail.scheduleAnchorPolicy case final anchor?)
                  ('週期基準', _anchorLabel(anchor)),
              ],
            ),
            if (!terminal) ...[
              const SizedBox(height: 20),
              Text(
                '安排這次提醒',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _reschedule,
                      icon: const Icon(Icons.event_repeat_outlined),
                      label: const Text('重新安排'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : (paused ? _resume : _pause),
                      icon: Icon(
                        paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      ),
                      label: Text(paused ? '恢復提醒' : '暫停提醒'),
                    ),
                  ),
                ],
              ),
              if (_detail.canStartWorkCase) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _saving ? null : _startWorkCase,
                  icon: const Icon(Icons.handyman_outlined),
                  label: const Text('開始處理'),
                ),
                const SizedBox(height: 8),
                Text(
                  '開始後會建立一筆進行中案件；這則提醒仍會保留，不會直接結案。',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF687887),
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pause() => _runMutation(
    (runtime) => runtime.pause(_detail.task.id, DateTime.now()),
    successMessage: '提醒已暫停，事情仍被保留。',
  );

  Future<void> _resume() => _runMutation(
    (runtime) => runtime.resume(_detail.task.id, DateTime.now()),
    successMessage: '提醒已恢復。',
  );

  Future<void> _reschedule() async {
    final task = _detail.task;
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(
      task.dueDate.year,
      task.dueDate.month,
      task.dueDate.day,
    );
    final selected = await showDatePicker(
      context: context,
      initialDate: taskDate.isBefore(firstDate) ? firstDate : taskDate,
      firstDate: firstDate,
      lastDate: DateTime(2200),
      helpText: '選擇新的提醒日期',
    );
    if (selected == null) return;
    await _runMutation(
      (runtime) => runtime.reschedule(task.id, selected, DateTime.now()),
      successMessage: '這次提醒已重新安排。',
    );
  }

  Future<void> _startWorkCase() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => StartTaskWorkCaseScreen(detail: _detail),
      ),
    );
    if (!mounted || created != true) return;
    _changed = true;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已建立進行中案件，提醒資料保持不變。')));
  }

  Future<void> _runMutation(
    Future<void> Function(TaskReminderRuntime runtime) action, {
    required String successMessage,
  }) async {
    final runtime = _runtime;
    if (runtime == null) return;
    setState(() => _saving = true);
    try {
      await action(runtime);
      final refreshed = await runtime.findReminder(_detail.task.id);
      if (!mounted || refreshed == null) return;
      setState(() {
        _detail = refreshed;
        _changed = true;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class StartTaskWorkCaseScreen extends StatefulWidget {
  const StartTaskWorkCaseScreen({super.key, required this.detail});

  final TaskReminderDetail detail;

  @override
  State<StartTaskWorkCaseScreen> createState() =>
      _StartTaskWorkCaseScreenState();
}

class _StartTaskWorkCaseScreenState extends State<StartTaskWorkCaseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  final _descriptionController = TextEditingController();
  late WorkCaseType _caseType = _defaultCaseType(widget.detail.sourceKind);
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.detail.task.title);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('開始處理')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: UiInsets.page,
          children: [
            Text(
              '把事情接成一筆案件',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              '案件會承接後續過程；原提醒不會被完成或消失。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF687887),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '案件名稱'),
              validator: (value) => _text(value) == null ? '請輸入案件名稱' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<WorkCaseType>(
              initialValue: _caseType,
              decoration: const InputDecoration(labelText: '事情類型'),
              items: [
                for (final value in WorkCaseType.values)
                  DropdownMenuItem(
                    value: value,
                    child: Text(_caseTypeLabel(value)),
                  ),
              ],
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value != null) setState(() => _caseType = value);
                    },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: '目前狀況（可稍後補充）',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? '建立中…' : '建立進行中案件'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final runtime = AppCompositionScope.of(context).taskReminderRuntime;
    if (runtime == null) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final workCase = WorkCase(
      id: 'case-${now.microsecondsSinceEpoch}',
      itemId: widget.detail.task.itemId,
      sourceType: WorkCaseSourceType.manual,
      caseType: _caseType,
      title: _titleController.text.trim(),
      description: _text(_descriptionController.text),
      occurredAt: now,
      startedAt: now,
      status: WorkCaseStatus.inProgress,
      createdAt: now,
      updatedAt: now,
    );
    try {
      await runtime.startWorkCase(
        taskId: widget.detail.task.id,
        workCase: workCase,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.detail, required this.onTap});

  final TaskReminderDetail detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return UiActionCard(
      onTap: onTap,
      semanticLabel: '開啟提醒：${detail.task.title}',
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        onTap: onTap,
        leading: const CircleAvatar(
          backgroundColor: UiColors.iconSurface,
          child: Icon(Icons.notifications_none, color: UiColors.primary),
        ),
        title: Text(
          detail.task.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${detail.itemName} · ${_formatDate(detail.task.dueDate)}',
        ),
        trailing: UiStatusTag(
          label: _statusLabel(detail.task.status),
          tone: detail.task.status == TaskStatus.overdue
              ? UiStatusTone.warning
              : UiStatusTone.info,
        ),
      ),
    );
  }
}

class _ReminderHero extends StatelessWidget {
  const _ReminderHero({required this.detail});

  final TaskReminderDetail detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(UiSpace.lg),
      decoration: BoxDecoration(
        color: UiColors.surfaceBlue,
        borderRadius: BorderRadius.circular(UiRadius.card),
        border: Border.all(color: UiColors.border),
        boxShadow: UiShadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.notifications_active_outlined,
            color: UiColors.primary,
          ),
          const SizedBox(height: 14),
          Text(detail.task.title, style: UiType.pageTitle),
          const SizedBox(height: 8),
          Text(
            '這是一則提醒；開始處理後，案件會另外承接過程與結果。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: UiColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({required this.title, required this.rows});

  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return UiSurfaceCard(
      padding: const EdgeInsets.all(UiSpace.md),
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: UiType.sectionTitle),
            const SizedBox(height: 12),
            for (final row in rows) ...[
              Text(
                row.$1,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: UiColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                row.$2,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(UiSpace.md),
    child: UiEmptyState(
      icon: Icons.notifications_none_rounded,
      title: '目前沒有提醒',
      description: '需要留意的日期或事項出現時，會整理在這裡。',
    ),
  );
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('提醒資料暫時無法讀取。'),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRetry, child: const Text('再試一次')),
      ],
    ),
  );
}

void _showError(BuildContext context, Object error) {
  final message = error is RepositoryConstraintException
      ? error.message
      : '目前無法完成這個動作，請稍後再試。';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

String _formatDate(DateTime value) =>
    '${value.year}/${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')}';

String _statusLabel(TaskStatus value) => switch (value) {
  TaskStatus.pending => '已安排',
  TaskStatus.overdue => '需要留意',
  TaskStatus.postponed => '已暫停',
  TaskStatus.completed => '已完成',
  TaskStatus.canceled => '已取消',
};

String _sourceKindLabel(TaskReminderSourceKind value) => switch (value) {
  TaskReminderSourceKind.maintenancePlan => '保養項目',
  TaskReminderSourceKind.generalReminder => '一般提醒',
  TaskReminderSourceKind.milestone => '階段性重點',
  TaskReminderSourceKind.manual => '手動提醒',
  TaskReminderSourceKind.legacy => '舊資料來源',
};

String _scheduleLabel(String cycle, int interval) {
  final unit = switch (cycle) {
    'daily' => '天',
    'weekly' => '週',
    'monthly' => '個月',
    'quarterly' => '季',
    'semiAnnual' => '半年',
    'yearly' => '年',
    'once' => '單次',
    _ => '自訂週期',
  };
  if (cycle == 'once' || cycle == 'custom') return unit;
  return '每 $interval $unit';
}

String _anchorLabel(String value) => switch (value) {
  'fixedCalendarPeriod' => '依固定曆法週期',
  'completionBased' => '完成後重新計算',
  'userDefined' => '使用自訂日期',
  _ => '沿用原排程設定',
};

WorkCaseType _defaultCaseType(TaskReminderSourceKind source) =>
    switch (source) {
      TaskReminderSourceKind.maintenancePlan => WorkCaseType.maintenance,
      TaskReminderSourceKind.generalReminder => WorkCaseType.administrative,
      _ => WorkCaseType.other,
    };

String _caseTypeLabel(WorkCaseType value) => switch (value) {
  WorkCaseType.maintenance => '保養處理',
  WorkCaseType.repair => '維修處理',
  WorkCaseType.construction => '施工處理',
  WorkCaseType.administrative => '文件或行政',
  WorkCaseType.other => '其他生活事項',
};

String? _text(String? value) {
  final result = value?.trim();
  return result == null || result.isEmpty ? null : result;
}
