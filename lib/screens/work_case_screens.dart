import 'package:flutter/material.dart';

import '../app/app_composition_root.dart';
import '../models/attachment.dart';
import '../models/enums.dart';
import '../models/item.dart';
import '../models/schedule.dart';
import '../models/work_case.dart';
import '../models/work_case_closure.dart';
import '../models/work_case_enums.dart';
import '../models/work_case_update.dart';
import '../repositories/repository_constraint_exception.dart';

class WorkCaseListScreen extends StatefulWidget {
  const WorkCaseListScreen({super.key});

  @override
  State<WorkCaseListScreen> createState() => _WorkCaseListScreenState();
}

class _WorkCaseListScreenState extends State<WorkCaseListScreen> {
  List<_WorkCaseListEntry>? _entries;
  Object? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entries == null && _error == null) _load();
  }

  Future<void> _load() async {
    final root = AppCompositionScope.of(context);
    final runtime = root.workCaseRuntime;
    if (runtime == null) {
      setState(() => _error = StateError('正式案件服務目前無法使用。'));
      return;
    }
    try {
      final items = await root.itemReadRepository.loadItems();
      final entries = <_WorkCaseListEntry>[];
      for (final item in items) {
        final cases = await runtime.listCasesForItem(item.id);
        entries.addAll(
          cases.map((workCase) => _WorkCaseListEntry(workCase, item)),
        );
      }
      entries.sort(
        (left, right) =>
            right.workCase.updatedAt.compareTo(left.workCase.updatedAt),
      );
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _error = null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('案件')),
      body: switch ((_entries, _error)) {
        (null, null) => const Center(child: CircularProgressIndicator()),
        (null, _) => _LoadFailure(onRetry: _retry),
        (final entries?, _) when entries.isEmpty => const _EmptyState(
          icon: Icons.handyman_outlined,
          message: '目前還沒有案件。事情開始處理後，會在這裡持續留下過程。',
        ),
        (final entries?, _) => RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              if (entries.any((entry) => entry.workCase.isOpen)) ...[
                const _SectionTitle('進行中'),
                for (final entry in entries.where(
                  (entry) => entry.workCase.isOpen,
                ))
                  _CaseListCard(entry: entry, onChanged: _load),
              ],
              if (entries.any((entry) => entry.workCase.isClosed)) ...[
                const SizedBox(height: 18),
                const _SectionTitle('已結案件'),
                for (final entry in entries.where(
                  (entry) => entry.workCase.isClosed,
                ))
                  _CaseListCard(entry: entry, onChanged: _load),
              ],
            ],
          ),
        ),
      },
    );
  }

  void _retry() {
    setState(() => _error = null);
    _load();
  }
}

class WorkCaseDetailScreen extends StatefulWidget {
  const WorkCaseDetailScreen({
    super.key,
    required this.workCaseId,
    required this.itemName,
  });

  final String workCaseId;
  final String itemName;

  @override
  State<WorkCaseDetailScreen> createState() => _WorkCaseDetailScreenState();
}

class _WorkCaseDetailScreenState extends State<WorkCaseDetailScreen> {
  _WorkCaseSnapshot? _snapshot;
  Object? _error;
  bool _changed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_snapshot == null && _error == null) _load();
  }

  Future<void> _load() async {
    final root = AppCompositionScope.of(context);
    final runtime = root.workCaseRuntime;
    if (runtime == null) {
      setState(() => _error = StateError('正式案件服務目前無法使用。'));
      return;
    }
    try {
      final workCase = await runtime.findCaseById(widget.workCaseId);
      if (workCase == null) throw StateError('案件不存在。');
      final updates = await runtime.listUpdatesForCase(workCase.id);
      final closure = await runtime.findClosureForCase(workCase.id);
      final attachments = <String, List<Attachment>>{};
      final attachmentRuntime = root.attachmentRuntime;
      if (attachmentRuntime != null) {
        for (final update in updates) {
          attachments[update.id] = await attachmentRuntime.listForOwner(
            AttachmentOwnerType.workCaseUpdate,
            update.id,
          );
        }
        if (closure != null) {
          attachments[closure.id] = await attachmentRuntime.listForOwner(
            AttachmentOwnerType.workCaseClosure,
            closure.id,
          );
        }
      }
      if (!mounted) return;
      setState(() {
        _snapshot = _WorkCaseSnapshot(
          workCase: workCase,
          updates: updates,
          closure: closure,
          attachments: attachments,
        );
        _error = null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('案件詳情')),
        body: switch ((_snapshot, _error)) {
          (null, null) => const Center(child: CircularProgressIndicator()),
          (null, _) => _LoadFailure(onRetry: _retry),
          (final snapshot?, _) => _WorkCaseBody(
            snapshot: snapshot,
            itemName: widget.itemName,
            onAddUpdate: () => _openUpdate(snapshot),
            onClose: () => _openClosure(snapshot),
            onCancel: () => _openCancel(snapshot),
          ),
        },
      ),
    );
  }

  void _retry() {
    setState(() => _error = null);
    _load();
  }

  Future<void> _openUpdate(_WorkCaseSnapshot snapshot) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => WorkCaseUpdateFormScreen(workCase: snapshot.workCase),
      ),
    );
    await _refreshIfChanged(changed);
  }

  Future<void> _openClosure(_WorkCaseSnapshot snapshot) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => WorkCaseClosureFormScreen(
          workCase: snapshot.workCase,
          suggestedTotalCost: snapshot.totalUpdateCost,
        ),
      ),
    );
    await _refreshIfChanged(changed);
  }

  Future<void> _openCancel(_WorkCaseSnapshot snapshot) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => WorkCaseCancelFormScreen(
          workCase: snapshot.workCase,
          totalCost: snapshot.totalUpdateCost,
        ),
      ),
    );
    await _refreshIfChanged(changed);
  }

  Future<void> _refreshIfChanged(bool? changed) async {
    if (changed != true) return;
    _changed = true;
    setState(() => _snapshot = null);
    await _load();
  }
}

class WorkCaseUpdateFormScreen extends StatefulWidget {
  const WorkCaseUpdateFormScreen({super.key, required this.workCase});

  final WorkCase workCase;

  @override
  State<WorkCaseUpdateFormScreen> createState() =>
      _WorkCaseUpdateFormScreenState();
}

class _WorkCaseUpdateFormScreenState extends State<WorkCaseUpdateFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _vendor = TextEditingController();
  final _result = TextEditingController();
  final _cost = TextEditingController();
  final _parts = TextEditingController();
  final _waitingReason = TextEditingController();
  final _note = TextEditingController();
  final _nextAction = TextEditingController();
  DateTime _occurredAt = DateTime.now();
  late WorkCaseStatus _status = widget.workCase.status == WorkCaseStatus.waiting
      ? WorkCaseStatus.waiting
      : WorkCaseStatus.inProgress;
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in [
      _description,
      _vendor,
      _result,
      _cost,
      _parts,
      _waitingReason,
      _note,
      _nextAction,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新增案件進度')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            const _FormIntro(
              title: '留下這次處理過程',
              description: '每一筆進度都會保留，不會覆蓋前面的紀錄。',
            ),
            _DateField(label: '發生日期', value: _occurredAt, onTap: _pickDate),
            TextFormField(
              controller: _description,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: '這次做了什麼',
                alignLabelWithHint: true,
              ),
              validator: (value) => _text(value) == null ? '請填寫處理內容' : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<WorkCaseStatus>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: '案件現在的狀態'),
              items: const [
                DropdownMenuItem(
                  value: WorkCaseStatus.inProgress,
                  child: Text('處理中'),
                ),
                DropdownMenuItem(
                  value: WorkCaseStatus.waiting,
                  child: Text('等待中'),
                ),
              ],
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value != null) setState(() => _status = value);
                    },
            ),
            const SizedBox(height: 14),
            _field(_vendor, '聯絡人或廠商'),
            _field(_result, '這次處理結果'),
            TextFormField(
              controller: _cost,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '這次費用'),
              validator: _validateNonNegativeCost,
            ),
            const SizedBox(height: 14),
            _field(_parts, '零件或品項（可用逗號分開）'),
            _field(_waitingReason, '等待原因'),
            _field(_nextAction, '下一步'),
            _field(_note, '補充備註', lines: 3),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? '保存中…' : '保存這筆進度'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      minLines: lines,
      maxLines: lines == 1 ? 1 : lines + 2,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: lines > 1,
      ),
    ),
  );

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: widget.workCase.createdAt,
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: '選擇進度日期',
    );
    if (selected != null) {
      setState(() {
        _occurredAt = DateTime(
          selected.year,
          selected.month,
          selected.day,
          _occurredAt.hour,
          _occurredAt.minute,
        );
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final runtime = AppCompositionScope.of(context).workCaseRuntime;
    if (runtime == null) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final update = WorkCaseUpdate(
      id: 'update-${now.microsecondsSinceEpoch}',
      workCaseId: widget.workCase.id,
      occurredAt: _occurredAt,
      description: _description.text.trim(),
      contactOrVendor: _text(_vendor.text),
      result: _text(_result.text),
      cost: _integer(_cost.text),
      partsOrItems: _partsList(_parts.text),
      waitingReason: _text(_waitingReason.text),
      note: _text(_note.text),
      nextAction: _text(_nextAction.text),
      createdAt: now,
    );
    try {
      await runtime.appendUpdate(update, status: _status, statusUpdatedAt: now);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class WorkCaseClosureFormScreen extends StatefulWidget {
  const WorkCaseClosureFormScreen({
    super.key,
    required this.workCase,
    required this.suggestedTotalCost,
  });

  final WorkCase workCase;
  final int suggestedTotalCost;

  @override
  State<WorkCaseClosureFormScreen> createState() =>
      _WorkCaseClosureFormScreenState();
}

class _WorkCaseClosureFormScreenState extends State<WorkCaseClosureFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _result = TextEditingController();
  final _summary = TextEditingController();
  late final TextEditingController _cost = TextEditingController(
    text: widget.suggestedTotalCost.toString(),
  );
  final _followUp = TextEditingController();
  DateTime _completedAt = DateTime.now();
  DateTime _reminderDueDate = DateTime.now().add(const Duration(days: 30));
  List<Schedule>? _schedules;
  String? _nextScheduleId;
  bool _createReminder = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_schedules == null) _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    final values = await AppCompositionScope.of(
      context,
    ).scheduleRepository.loadSchedules();
    if (!mounted) return;
    setState(() {
      _schedules = values
          .where(
            (schedule) =>
                schedule.itemId == widget.workCase.itemId &&
                schedule.status != ScheduleStatus.ended,
          )
          .toList(growable: false);
    });
  }

  @override
  void dispose() {
    _result.dispose();
    _summary.dispose();
    _cost.dispose();
    _followUp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('正式結案')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            const _FormIntro(
              title: '留下完整結果',
              description: '結案後案件與進度會保持唯讀，並由正式資料投影進入史略。',
            ),
            _DateField(
              label: '完成日期',
              value: _completedAt,
              onTap: _pickCompletionDate,
            ),
            TextFormField(
              controller: _result,
              decoration: const InputDecoration(labelText: '完成結果'),
              validator: (value) => _text(value) == null ? '請填寫完成結果' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _summary,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: '完修或結案摘要',
                alignLabelWithHint: true,
              ),
              validator: (value) => _text(value) == null ? '請填寫結案摘要' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _cost,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '總費用'),
              validator: _validateRequiredNonNegativeCost,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _followUp,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: '後續注意事項（選填）',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              '後續安排（選填）',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              '可以保留既有正式排程，或另外建立一則單次提醒。結案與後續提醒會一起保存。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF687887),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String?>(
              initialValue: _nextScheduleId,
              decoration: const InputDecoration(labelText: '保留後續排程'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('這次不指定'),
                ),
                for (final schedule in _schedules ?? const <Schedule>[])
                  DropdownMenuItem<String?>(
                    value: schedule.id,
                    child: Text(_scheduleChoiceLabel(schedule)),
                  ),
              ],
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _nextScheduleId = value),
            ),
            if (_schedules?.isEmpty ?? false) ...[
              const SizedBox(height: 8),
              const Text('這個生活項目目前沒有可保留的正式排程。'),
            ],
            const SizedBox(height: 10),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('建立下一次提醒'),
              subtitle: const Text('建立一則單次提醒，不會改動原本的 Task。'),
              value: _createReminder,
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _createReminder = value),
            ),
            if (_createReminder)
              _DateField(
                label: '提醒日期',
                value: _reminderDueDate,
                onTap: _pickReminderDate,
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? '結案中…' : '確認正式結案'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final runtime = AppCompositionScope.of(context).workCaseRuntime;
    if (runtime == null) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final followUp = _text(_followUp.text);
    final reminderId = _createReminder
        ? 'task-follow-up-${now.microsecondsSinceEpoch}'
        : null;
    final followUpType = switch ((_nextScheduleId != null, _createReminder)) {
      (true, true) => WorkCaseFollowUpType.scheduleAndReminder,
      (true, false) => WorkCaseFollowUpType.schedule,
      (false, true) => WorkCaseFollowUpType.reminder,
      (false, false) when followUp != null => WorkCaseFollowUpType.manual,
      _ => WorkCaseFollowUpType.none,
    };
    final closure = WorkCaseClosure(
      id: 'closure-${now.microsecondsSinceEpoch}',
      workCaseId: widget.workCase.id,
      completedAt: _completedAt,
      finalResult: _result.text.trim(),
      completionSummary: _summary.text.trim(),
      totalCost: _integer(_cost.text)!,
      followUpNotes: followUp,
      followUpType: followUpType,
      nextScheduleId: _nextScheduleId,
      nextReminderTaskId: reminderId,
      createdAt: now,
    );
    try {
      await runtime.closeWithFollowUp(
        closure,
        nextReminderDueDate: _createReminder ? _reminderDueDate : null,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickCompletionDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _completedAt,
      firstDate: widget.workCase.createdAt,
      lastDate: DateTime.now(),
      helpText: '選擇完成日期',
    );
    if (selected != null) {
      setState(() => _completedAt = _withExistingTime(selected, _completedAt));
    }
  }

  Future<void> _pickReminderDate() async {
    final firstDate = DateTime(
      _completedAt.year,
      _completedAt.month,
      _completedAt.day,
    ).add(const Duration(days: 1));
    final initialDate = _reminderDueDate.isBefore(firstDate)
        ? firstDate
        : _reminderDueDate;
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(firstDate.year + 20),
      helpText: '選擇提醒日期',
    );
    if (selected != null) {
      setState(
        () => _reminderDueDate = _withExistingTime(selected, _reminderDueDate),
      );
    }
  }
}

class WorkCaseCancelFormScreen extends StatefulWidget {
  const WorkCaseCancelFormScreen({
    super.key,
    required this.workCase,
    required this.totalCost,
  });

  final WorkCase workCase;
  final int totalCost;

  @override
  State<WorkCaseCancelFormScreen> createState() =>
      _WorkCaseCancelFormScreenState();
}

class _WorkCaseCancelFormScreenState extends State<WorkCaseCancelFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('取消案件')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            const _FormIntro(
              title: '說明為什麼停止處理',
              description: '取消也是正式終止，原因與既有進度都會被保留。',
            ),
            TextFormField(
              controller: _reason,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: '取消原因',
                alignLabelWithHint: true,
              ),
              validator: (value) => _text(value) == null ? '請填寫取消原因' : null,
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? '保存中…' : '確認取消案件'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final runtime = AppCompositionScope.of(context).workCaseRuntime;
    if (runtime == null) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final reason = _reason.text.trim();
    final closure = WorkCaseClosure(
      id: 'closure-${now.microsecondsSinceEpoch}',
      workCaseId: widget.workCase.id,
      completedAt: now,
      finalResult: '案件已取消',
      completionSummary: reason,
      totalCost: widget.totalCost,
      followUpType: WorkCaseFollowUpType.none,
      createdAt: now,
    );
    try {
      await runtime.cancel(closure, cancellationReason: reason);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _WorkCaseBody extends StatelessWidget {
  const _WorkCaseBody({
    required this.snapshot,
    required this.itemName,
    required this.onAddUpdate,
    required this.onClose,
    required this.onCancel,
  });

  final _WorkCaseSnapshot snapshot;
  final String itemName;
  final VoidCallback onAddUpdate;
  final VoidCallback onClose;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final workCase = snapshot.workCase;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _CaseHero(workCase: workCase, itemName: itemName),
        const SizedBox(height: 16),
        _InformationCard(
          title: '主資訊',
          rows: [
            ('事情類型', _caseTypeLabel(workCase.caseType)),
            ('案件來源', _sourceLabel(workCase.sourceType)),
            ('開始日期', _formatDate(workCase.startedAt ?? workCase.createdAt)),
            ('最後更新', _formatDate(workCase.updatedAt)),
            if (_text(workCase.description) case final description?)
              ('目前狀況', description),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Expanded(child: _SectionTitle('案件時間軸')),
            Text('累計費用 ${_money(snapshot.totalUpdateCost)}'),
          ],
        ),
        const SizedBox(height: 10),
        if (snapshot.updates.isEmpty)
          const _EmptyState(
            icon: Icons.timeline_outlined,
            message: '還沒有案件進度。可以先留下目前處理到哪裡。',
          )
        else
          for (var index = 0; index < snapshot.updates.length; index++)
            _TimelineEntry(
              update: snapshot.updates[index],
              attachments:
                  snapshot.attachments[snapshot.updates[index].id] ?? const [],
              isLast: index == snapshot.updates.length - 1,
            ),
        if (snapshot.closure case final closure?) ...[
          const SizedBox(height: 18),
          _ClosureCard(
            closure: closure,
            canceled: workCase.status == WorkCaseStatus.canceled,
            cancellationReason: workCase.cancellationReason,
            attachments: snapshot.attachments[closure.id] ?? const [],
          ),
        ],
        const SizedBox(height: 18),
        const _SectionTitle('附件'),
        const SizedBox(height: 8),
        if (snapshot.allAttachments.isEmpty)
          const _EmptyState(
            icon: Icons.attach_file_outlined,
            message: '目前沒有已保存的照片、文件或收據。',
          )
        else
          for (final attachment in snapshot.allAttachments)
            _AttachmentTile(attachment: attachment),
        if (workCase.isOpen) ...[
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: onAddUpdate,
            icon: const Icon(Icons.add_comment_outlined),
            label: const Text('新增案件進度'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onClose,
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('進入正式結案'),
          ),
          TextButton(onPressed: onCancel, child: const Text('取消案件')),
        ] else ...[
          const SizedBox(height: 18),
          const _ReadOnlyNotice(),
        ],
      ],
    );
  }
}

class _CaseListCard extends StatelessWidget {
  const _CaseListCard({required this.entry, required this.onChanged});

  final _WorkCaseListEntry entry;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE8F0F6),
          child: Icon(Icons.handyman_outlined, color: Color(0xFF5D7893)),
        ),
        title: Text(
          entry.workCase.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${entry.item.name} · ${_caseTypeLabel(entry.workCase.caseType)}',
        ),
        trailing: Text(_statusLabel(entry.workCase.status)),
        onTap: () async {
          final changed = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => WorkCaseDetailScreen(
                workCaseId: entry.workCase.id,
                itemName: entry.item.name,
              ),
            ),
          );
          if (changed == true) await onChanged();
        },
      ),
    );
  }
}

class _CaseHero extends StatelessWidget {
  const _CaseHero({required this.workCase, required this.itemName});

  final WorkCase workCase;
  final String itemName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0F6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.handyman_outlined, color: Color(0xFF5D7893)),
              const Spacer(),
              _StatusPill(label: _statusLabel(workCase.status)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            workCase.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: const Color(0xFF263746),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            itemName,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF516778),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.update,
    required this.attachments,
    required this.isLast,
  });

  final WorkCaseUpdate update;
  final List<Attachment> attachments;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final facts = <String>[
      if (_text(update.contactOrVendor) case final value?) '廠商／聯絡：$value',
      if (_text(update.result) case final value?) '結果：$value',
      if (update.cost case final value?) '費用：${_money(value)}',
      if (update.partsOrItems.isNotEmpty)
        '零件／品項：${update.partsOrItems.join('、')}',
      if (_text(update.waitingReason) case final value?) '等待原因：$value',
      if (_text(update.nextAction) case final value?) '下一步：$value',
      if (_text(update.note) case final value?) '備註：$value',
    ];
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5D7893),
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: const Color(0xFFD5E0E9)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDateTime(update.occurredAt),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: const Color(0xFF5D7893),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      update.description,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    for (final fact in facts) ...[
                      const SizedBox(height: 7),
                      Text(fact),
                    ],
                    if (attachments.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text('附件 ${attachments.length} 份'),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClosureCard extends StatelessWidget {
  const _ClosureCard({
    required this.closure,
    required this.canceled,
    required this.cancellationReason,
    required this.attachments,
  });

  final WorkCaseClosure closure;
  final bool canceled;
  final String? cancellationReason;
  final List<Attachment> attachments;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFF0F4EC),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              canceled ? '案件已取消' : '正式結案',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(
              canceled
                  ? cancellationReason ?? closure.finalResult
                  : closure.finalResult,
            ),
            const SizedBox(height: 7),
            Text(closure.completionSummary),
            const SizedBox(height: 7),
            Text('總費用 ${_money(closure.totalCost)}'),
            if (_text(closure.followUpNotes) case final value?) ...[
              const SizedBox(height: 7),
              Text('後續注意：$value'),
            ],
            if (closure.createsSchedule) ...[
              const SizedBox(height: 7),
              const Text('已連結後續排程'),
            ],
            if (closure.createsReminder) ...[
              const SizedBox(height: 7),
              const Text('已建立下一次提醒'),
            ],
            if (attachments.isNotEmpty) ...[
              const SizedBox(height: 7),
              Text('附件 ${attachments.length} 份'),
            ],
          ],
        ),
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.attachment});

  final Attachment attachment;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(_attachmentIcon(attachment.kind)),
        title: Text(
          attachment.originalFileName ?? _attachmentKindLabel(attachment.kind),
        ),
        subtitle: Text(_attachmentStateLabel(attachment.state)),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            for (final row in rows) ...[
              Text(
                row.$1,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF5D7893),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(row.$2),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.75),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
  );
}

class _ReadOnlyNotice extends StatelessWidget {
  const _ReadOnlyNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFECE8DF),
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Text('案件已終止，主資訊、過程與正式結案資料保持唯讀。'),
  );
}

class _FormIntro extends StatelessWidget {
  const _FormIntro({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 7),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF687887),
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(_formatDate(value)),
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFCF6),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE4E0D8)),
    ),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFF5D7893)),
        const SizedBox(width: 12),
        Expanded(child: Text(message)),
      ],
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
        const Text('案件資料暫時無法讀取。'),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRetry, child: const Text('再試一次')),
      ],
    ),
  );
}

class _WorkCaseListEntry {
  const _WorkCaseListEntry(this.workCase, this.item);

  final WorkCase workCase;
  final Item item;
}

class _WorkCaseSnapshot {
  const _WorkCaseSnapshot({
    required this.workCase,
    required this.updates,
    required this.closure,
    required this.attachments,
  });

  final WorkCase workCase;
  final List<WorkCaseUpdate> updates;
  final WorkCaseClosure? closure;
  final Map<String, List<Attachment>> attachments;

  int get totalUpdateCost =>
      updates.fold(0, (sum, value) => sum + (value.cost ?? 0));

  List<Attachment> get allAttachments => [
    for (final values in attachments.values) ...values,
  ];
}

String _statusLabel(WorkCaseStatus status) => switch (status) {
  WorkCaseStatus.notStarted => '尚未開始',
  WorkCaseStatus.inProgress => '處理中',
  WorkCaseStatus.waiting => '等待中',
  WorkCaseStatus.completed => '已完成',
  WorkCaseStatus.canceled => '已取消',
};

String _caseTypeLabel(WorkCaseType type) => switch (type) {
  WorkCaseType.maintenance => '保養處理',
  WorkCaseType.repair => '維修處理',
  WorkCaseType.construction => '施工處理',
  WorkCaseType.administrative => '文件或行政',
  WorkCaseType.other => '其他生活事項',
};

String _sourceLabel(WorkCaseSourceType type) => switch (type) {
  WorkCaseSourceType.maintenanceTask => '保養提醒',
  WorkCaseSourceType.generalReminder => '一般提醒',
  WorkCaseSourceType.milestone => '階段性重點',
  WorkCaseSourceType.manual => '手動建立',
  WorkCaseSourceType.unknown => '舊資料來源',
};

String _attachmentKindLabel(AttachmentKind kind) => switch (kind) {
  AttachmentKind.photo => '照片',
  AttachmentKind.document => '文件',
  AttachmentKind.receipt => '收據',
  AttachmentKind.other => '附件',
};

IconData _attachmentIcon(AttachmentKind kind) => switch (kind) {
  AttachmentKind.photo => Icons.photo_outlined,
  AttachmentKind.document => Icons.description_outlined,
  AttachmentKind.receipt => Icons.receipt_long_outlined,
  AttachmentKind.other => Icons.attach_file_outlined,
};

String _attachmentStateLabel(AttachmentState state) => switch (state) {
  AttachmentState.available => '可使用',
  AttachmentState.missing => '檔案遺失',
  AttachmentState.deleted => '已刪除',
  AttachmentState.unknown => '狀態未知',
};

String _formatDate(DateTime value) =>
    '${value.year}/${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')}';

String _formatDateTime(DateTime value) =>
    '${_formatDate(value)} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

String _scheduleChoiceLabel(Schedule schedule) =>
    '${schedule.title ?? _cycleLabel(schedule.cycleType)} · 下次 ${_formatDate(schedule.nextDueDate)}';

String _cycleLabel(CycleType value) => switch (value) {
  CycleType.daily => '每日',
  CycleType.weekly => '每週',
  CycleType.monthly => '每月',
  CycleType.quarterly => '每季',
  CycleType.semiAnnual => '每半年',
  CycleType.yearly => '每年',
  CycleType.custom => '自訂安排',
};

DateTime _withExistingTime(DateTime date, DateTime time) => DateTime(
  date.year,
  date.month,
  date.day,
  time.hour,
  time.minute,
  time.second,
  time.millisecond,
  time.microsecond,
);

String _money(int value) => '\$${value.toString()}';

String? _text(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

int? _integer(String value) => int.tryParse(value.trim());

List<String> _partsList(String value) => value
    .split(RegExp(r'[,，\n]'))
    .map((entry) => entry.trim())
    .where((entry) => entry.isNotEmpty)
    .toList(growable: false);

String? _validateNonNegativeCost(String? value) {
  final normalized = _text(value);
  if (normalized == null) return null;
  final parsed = int.tryParse(normalized);
  return parsed == null || parsed < 0 ? '請輸入 0 以上的整數金額' : null;
}

String? _validateRequiredNonNegativeCost(String? value) {
  if (_text(value) == null) return '請填寫總費用，沒有費用請填 0';
  return _validateNonNegativeCost(value);
}

void _showError(BuildContext context, Object error) {
  final message = error is RepositoryConstraintException
      ? error.message
      : '目前無法完成這個動作，請稍後再試。';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
