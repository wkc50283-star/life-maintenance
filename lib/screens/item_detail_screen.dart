import 'package:flutter/material.dart';

import '../app/app_composition_root.dart';
import '../app/ui_tokens.dart';
import '../models/attachment.dart';
import '../models/enums.dart';
import '../models/history_projection.dart';
import '../models/item.dart';
import '../models/maintenance_plan.dart';
import '../models/maintenance_plan_enums.dart';
import '../models/milestone.dart';
import '../models/milestone_enums.dart';
import '../models/schedule.dart';
import '../models/work_case.dart';
import '../models/work_case_enums.dart';
import '../models/work_case_update.dart';
import '../widgets/ui_v2_components.dart';
import 'formal_planning_screens.dart';
import 'work_case_screens.dart';

class ItemDetailScreen extends StatefulWidget {
  const ItemDetailScreen({super.key, required this.item});

  final Item item;

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  _ItemDetailSnapshot? _snapshot;
  Object? _loadError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_snapshot == null && _loadError == null) {
      _load();
    }
  }

  Future<void> _load() async {
    final root = AppCompositionScope.of(context);
    try {
      final plans =
          await root.maintenancePlanRepository?.listForItem(widget.item.id) ??
          const <MaintenancePlan>[];
      final reminderRows = await root.generalReminderRepository?.listForItem(
        widget.item.id,
      );
      final reminders = [
        for (final reminder in reminderRows ?? const [])
          _ReminderSummary(
            title: reminder.title,
            description: reminder.description,
            reminderType: reminder.reminderType,
            status: reminder.status,
            updatedAt: reminder.updatedAt,
          ),
      ];
      final milestones =
          await root.milestoneRepository?.listForItem(widget.item.id) ??
          const <Milestone>[];
      final schedules = (await root.scheduleRepository.loadSchedules())
          .where((schedule) => schedule.itemId == widget.item.id)
          .toList(growable: false);

      final cases =
          await root.workCaseRuntime?.listCasesForItem(widget.item.id) ??
          const <WorkCase>[];
      final caseSummaries = <_CaseSummary>[];
      for (final workCase in cases) {
        final updates =
            await root.workCaseRuntime?.listUpdatesForCase(workCase.id) ??
            const <WorkCaseUpdate>[];
        final sortedUpdates = [...updates]
          ..sort((left, right) => right.occurredAt.compareTo(left.occurredAt));
        caseSummaries.add(
          _CaseSummary(
            workCase: workCase,
            latestUpdate: sortedUpdates.isEmpty ? null : sortedUpdates.first,
          ),
        );
      }
      caseSummaries.sort(
        (left, right) =>
            right.workCase.updatedAt.compareTo(left.workCase.updatedAt),
      );

      final history = await root.historyProjectionRepository?.projectForItem(
        widget.item.id,
      );
      final attachments = _attachmentsFrom(history);
      if (history == null && root.attachmentRuntime != null) {
        attachments.addAll(
          await root.attachmentRuntime!.listForOwner(
            AttachmentOwnerType.item,
            widget.item.id,
          ),
        );
      }

      plans.sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
      reminders.sort(
        (left, right) => right.updatedAt.compareTo(left.updatedAt),
      );
      schedules.sort(
        (left, right) => left.nextDueDate.compareTo(right.nextDueDate),
      );
      milestones.sort(
        (left, right) => right.updatedAt.compareTo(left.updatedAt),
      );
      final historyEntries = [...?history?.entries]
        ..sort((left, right) => right.occurredAt.compareTo(left.occurredAt));
      final uniqueAttachments =
          <String, Attachment>{
              for (final attachment in attachments) attachment.id: attachment,
            }.values.toList()
            ..sort((left, right) => right.createdAt.compareTo(left.createdAt));

      if (!mounted) return;
      setState(() {
        _snapshot = _ItemDetailSnapshot(
          plans: plans,
          reminders: reminders,
          schedules: schedules,
          milestones: milestones,
          cases: caseSummaries,
          historyEntries: historyEntries,
          attachments: uniqueAttachments,
        );
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('生活項目詳情'),
        actions: [
          if (formalPlanningEditor(context) != null)
            IconButton(
              tooltip: '編輯生活項目',
              onPressed: _editItem,
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: switch ((_snapshot, _loadError)) {
        (null, null) => const Center(child: CircularProgressIndicator()),
        (null, _) => _LoadFailure(onRetry: _retry),
        (final snapshot?, _) => _ItemDetailBody(
          item: widget.item,
          snapshot: snapshot,
          onCaseChanged: _reload,
        ),
      },
    );
  }

  void _retry() {
    setState(() => _loadError = null);
    _load();
  }

  Future<void> _reload() async {
    setState(() {
      _snapshot = null;
      _loadError = null;
    });
    await _load();
  }

  Future<void> _editItem() async {
    final editor = formalPlanningEditor(context);
    final value = await editor?.findItem(widget.item.id);
    if (!mounted || value == null) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ItemFormScreen(value: value)),
    );
    if (changed == true && mounted) Navigator.pop(context, true);
  }
}

class _ItemDetailBody extends StatelessWidget {
  const _ItemDetailBody({
    required this.item,
    required this.snapshot,
    required this.onCaseChanged,
  });

  final Item item;
  final _ItemDetailSnapshot snapshot;
  final Future<void> Function() onCaseChanged;

  @override
  Widget build(BuildContext context) {
    final openCases = snapshot.cases
        .where((entry) => entry.workCase.isOpen)
        .toList(growable: false);
    final closedCases = snapshot.cases
        .where((entry) => entry.workCase.isClosed)
        .toList(growable: false);

    return ListView(
      padding: UiInsets.pageCompact,
      children: [
        _ItemHero(item: item, openCaseCount: openCases.length),
        const SizedBox(height: UiSpace.sm),
        _DetailSection(
          title: '主資訊',
          icon: Icons.info_outline_rounded,
          child: _MainInformation(item: item),
        ),
        _DetailSection(
          title: '保養項目',
          icon: Icons.home_repair_service_outlined,
          onManage: () => _openPlanning(
            context,
            PlanningContentKind.maintenancePlan,
            item.id,
          ),
          child: snapshot.plans.isEmpty
              ? const _EmptyMessage('目前沒有保養項目。')
              : Column(
                  children: [
                    for (final plan in snapshot.plans)
                      _FactCard(
                        title: plan.title,
                        subtitle: _maintenancePlanTypeLabel(plan.planType),
                        detail: _planDetail(plan, snapshot.schedules),
                        status: _maintenancePlanStatusLabel(plan.status),
                      ),
                  ],
                ),
        ),
        _DetailSection(
          title: '一般提醒',
          icon: Icons.notifications_none_rounded,
          onManage: () =>
              _openPlanning(context, PlanningContentKind.reminder, item.id),
          child: snapshot.reminders.isEmpty
              ? const _EmptyMessage('目前沒有一般提醒。')
              : Column(
                  children: [
                    for (final reminder in snapshot.reminders)
                      _FactCard(
                        title: reminder.title,
                        subtitle: _reminderTypeLabel(reminder.reminderType),
                        detail:
                            _nullableText(reminder.description) ?? '已納入生活項目管理',
                        status: _genericStatusLabel(reminder.status),
                      ),
                  ],
                ),
        ),
        _DetailSection(
          title: '提醒與排程',
          icon: Icons.event_repeat_outlined,
          onManage: () =>
              _openPlanning(context, PlanningContentKind.schedule, item.id),
          child: snapshot.schedules.isEmpty
              ? const _EmptyMessage('目前沒有排程。')
              : Column(
                  children: [
                    for (final schedule in snapshot.schedules)
                      _FactCard(
                        title: _nullableText(schedule.title) ?? '排程',
                        subtitle: _cycleLabel(schedule),
                        detail: '下次日期 ${_formatDate(schedule.nextDueDate)}',
                        status: _scheduleStatusLabel(schedule.status),
                      ),
                  ],
                ),
        ),
        _DetailSection(
          title: '階段性重點／大修',
          icon: Icons.flag_outlined,
          onManage: () =>
              _openPlanning(context, PlanningContentKind.milestone, item.id),
          child: snapshot.milestones.isEmpty
              ? const _EmptyMessage('目前沒有階段性重點或大修。')
              : Column(
                  children: [
                    for (final milestone in snapshot.milestones)
                      _FactCard(
                        title: milestone.title,
                        subtitle: _milestoneKindLabel(milestone.kind),
                        detail: _milestoneTriggerLabel(milestone),
                        status: _milestoneStatusLabel(milestone.status),
                      ),
                  ],
                ),
        ),
        _DetailSection(
          title: '進行中案件',
          icon: Icons.handyman_outlined,
          child: openCases.isEmpty
              ? const _EmptyMessage('目前沒有進行中的案件。')
              : Column(
                  children: [
                    for (final entry in openCases)
                      _FactCard(
                        title: entry.workCase.title,
                        subtitle: _workCaseTypeLabel(entry.workCase.caseType),
                        detail: _caseDetail(entry),
                        status: _workCaseStatusLabel(entry.workCase.status),
                        onTap: () => _openCase(context, entry.workCase),
                      ),
                  ],
                ),
        ),
        _DetailSection(
          title: '已結案件',
          icon: Icons.inventory_2_outlined,
          child: closedCases.isEmpty
              ? const _EmptyMessage('目前沒有已結案件。')
              : Column(
                  children: [
                    for (final entry in closedCases)
                      _FactCard(
                        title: entry.workCase.title,
                        subtitle: _workCaseTypeLabel(entry.workCase.caseType),
                        detail:
                            '結束於 ${_formatDate(entry.workCase.closedAt ?? entry.workCase.updatedAt)}',
                        status: _workCaseStatusLabel(entry.workCase.status),
                        onTap: () => _openCase(context, entry.workCase),
                      ),
                  ],
                ),
        ),
        _DetailSection(
          title: '史略',
          icon: Icons.history_rounded,
          child: snapshot.historyEntries.isEmpty
              ? const _EmptyMessage('目前還沒有史略。')
              : Column(
                  children: [
                    for (final entry in snapshot.historyEntries)
                      _FactCard(
                        title: _historyTitle(entry),
                        subtitle: _historyTypeLabel(entry),
                        detail: _historyDetail(entry),
                        status: _formatDate(entry.occurredAt),
                      ),
                  ],
                ),
        ),
        _DetailSection(
          title: '附件',
          icon: Icons.attach_file_rounded,
          child: snapshot.attachments.isEmpty
              ? const _EmptyMessage('目前沒有附件。')
              : Column(
                  children: [
                    for (final attachment in snapshot.attachments)
                      _FactCard(
                        title: _attachmentName(attachment),
                        subtitle: _attachmentKindLabel(attachment.kind),
                        detail: _attachmentDetail(attachment),
                        status: _attachmentStateLabel(attachment.state),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _openCase(BuildContext context, WorkCase workCase) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            WorkCaseDetailScreen(workCaseId: workCase.id, itemName: item.name),
      ),
    );
    if (changed == true) await onCaseChanged();
  }
}

class _ItemHero extends StatelessWidget {
  const _ItemHero({required this.item, required this.openCaseCount});

  final Item item;
  final int openCaseCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(UiSpace.md),
      decoration: BoxDecoration(
        color: UiColors.surface,
        borderRadius: BorderRadius.circular(UiRadius.hero),
        border: Border.all(color: UiColors.border),
        boxShadow: UiShadow.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: UiColors.iconSurface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _iconForCategory(item.category),
              color: UiColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: UiSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: UiType.pageTitle),
                const SizedBox(height: 4),
                Text(
                  '${_categoryLabel(item.category)} · ${_itemStatusLabel(item.status)}',
                  style: UiType.caption.copyWith(color: UiColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: UiSpace.xs),
          UiStatusTag(
            label: openCaseCount == 0 ? '無進行案件' : '案件 $openCaseCount',
            tone: openCaseCount == 0
                ? UiStatusTone.neutral
                : UiStatusTone.warning,
          ),
        ],
      ),
    );
  }
}

class _MainInformation extends StatelessWidget {
  const _MainInformation({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InformationRow(label: '分類', value: _categoryLabel(item.category)),
        _InformationRow(label: '狀態', value: _itemStatusLabel(item.status)),
        _InformationRow(
          label: '位置',
          value: _nullableText(item.location) ?? '未設定',
        ),
        _InformationRow(label: '建立日期', value: _formatDate(item.createdAt)),
        _InformationRow(
          label: '購買日期',
          value: item.purchaseDate == null
              ? '未設定'
              : _formatDate(item.purchaseDate!),
        ),
        _InformationRow(
          label: '保固到期',
          value: item.warrantyEndDate == null
              ? '未設定'
              : _formatDate(item.warrantyEndDate!),
        ),
        _InformationRow(
          label: '管理年限',
          value: item.expectedLifeYears == null
              ? '未設定'
              : '${item.expectedLifeYears} 年',
        ),
        _InformationRow(label: '備註', value: _nullableText(item.note) ?? '未設定'),
      ],
    );
  }
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return UiInformationRow(label: label, value: value);
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.icon,
    required this.child,
    this.onManage,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: UiSpace.sm),
      child: UiSurfaceCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UiSectionHeader(
              title: title,
              icon: icon,
              actionLabel: onManage == null ? null : '管理',
              onAction: onManage,
            ),
            const SizedBox(height: UiSpace.sm),
            child,
          ],
        ),
      ),
    );
  }
}

class _FactCard extends StatelessWidget {
  const _FactCard({
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.status,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String detail;
  final String status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: UiColors.surfaceBlue,
        borderRadius: BorderRadius.circular(UiRadius.control),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(title, style: UiType.cardTitle)),
                    const SizedBox(width: 10),
                    UiStatusTag(label: status, tone: UiStatusTone.info),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: UiColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
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
        ),
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: UiColors.surfaceBlue,
        borderRadius: BorderRadius.circular(UiRadius.control),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.inbox_outlined, color: UiColors.iconMuted),
            const SizedBox(width: UiSpace.sm),
            Expanded(child: Text(message, style: UiType.body)),
          ],
        ),
      ),
    );
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: Color(0xFF687887),
            ),
            const SizedBox(height: 14),
            const Text('暫時無法讀取這個生活項目。'),
            const SizedBox(height: 14),
            OutlinedButton(onPressed: onRetry, child: const Text('重新讀取')),
          ],
        ),
      ),
    );
  }
}

class _ItemDetailSnapshot {
  const _ItemDetailSnapshot({
    required this.plans,
    required this.reminders,
    required this.schedules,
    required this.milestones,
    required this.cases,
    required this.historyEntries,
    required this.attachments,
  });

  final List<MaintenancePlan> plans;
  final List<_ReminderSummary> reminders;
  final List<Schedule> schedules;
  final List<Milestone> milestones;
  final List<_CaseSummary> cases;
  final List<HistoryEntry> historyEntries;
  final List<Attachment> attachments;
}

class _CaseSummary {
  const _CaseSummary({required this.workCase, this.latestUpdate});

  final WorkCase workCase;
  final WorkCaseUpdate? latestUpdate;
}

class _ReminderSummary {
  const _ReminderSummary({
    required this.title,
    required this.reminderType,
    required this.status,
    required this.updatedAt,
    this.description,
  });

  final String title;
  final String? description;
  final String reminderType;
  final String status;
  final DateTime updatedAt;
}

List<Attachment> _attachmentsFrom(HistoryProjection? history) {
  if (history == null) return <Attachment>[];
  final attachments = [...history.itemAttachments];
  for (final entry in history.entries) {
    switch (entry) {
      case WorkCaseHistoryEntry(attachments: final entryAttachments):
      case MaintenanceRecordHistoryEntry(attachments: final entryAttachments):
      case MilestoneHistoryEntry(attachments: final entryAttachments):
        attachments.addAll(entryAttachments);
      case TaskHistoryEntry():
        break;
    }
  }
  return attachments;
}

Future<void> _openPlanning(
  BuildContext context,
  PlanningContentKind kind,
  String itemId,
) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PlanningContentScreen(kind: kind, initialItemId: itemId),
    ),
  );
}

String _planDetail(MaintenancePlan plan, List<Schedule> schedules) {
  Schedule? matching;
  for (final schedule in schedules) {
    if (schedule.cardId == plan.id ||
        schedule.cardId == plan.templateCardId ||
        schedule.title == plan.title) {
      matching = schedule;
      break;
    }
  }
  final risk = _riskLabel(plan.riskLevel);
  if (matching == null) return '風險層級：$risk · 尚未建立排程';
  return '風險層級：$risk · 下次 ${_formatDate(matching.nextDueDate)}';
}

String _caseDetail(_CaseSummary summary) {
  final update = summary.latestUpdate;
  if (_nullableText(update?.nextAction) case final nextAction?) {
    return '下一步：$nextAction';
  }
  if (_nullableText(update?.waitingReason) case final waitingReason?) {
    return '等待：$waitingReason';
  }
  return _nullableText(update?.description) ??
      _nullableText(summary.workCase.description) ??
      '最後更新 ${_formatDate(summary.workCase.updatedAt)}';
}

String _historyTitle(HistoryEntry entry) => switch (entry) {
  WorkCaseHistoryEntry(:final workCase) => workCase.title,
  MaintenanceRecordHistoryEntry(:final record) => record.title,
  TaskHistoryEntry(:final task) => task.title,
  MilestoneHistoryEntry(:final milestone) => milestone.title,
};

String _historyTypeLabel(HistoryEntry entry) => switch (entry) {
  WorkCaseHistoryEntry() => '案件史略',
  MaintenanceRecordHistoryEntry() => '保養／處理紀錄',
  TaskHistoryEntry() => '提醒紀錄',
  MilestoneHistoryEntry() => '階段性重點',
};

String _historyDetail(HistoryEntry entry) => switch (entry) {
  WorkCaseHistoryEntry(:final closure, :final updates) =>
    closure?.completionSummary ??
        (updates.isEmpty ? '案件已留下正式紀錄' : '共有 ${updates.length} 筆案件過程'),
  MaintenanceRecordHistoryEntry(:final record) =>
    _nullableText(record.result) ?? '已完成並留下紀錄',
  TaskHistoryEntry(:final task) => _genericStatusLabel(task.status),
  MilestoneHistoryEntry(:final milestone) =>
    _nullableText(milestone.description) ??
        _milestoneStatusLabel(milestone.status),
};

String _attachmentName(Attachment attachment) =>
    _nullableText(attachment.originalFileName) ?? '未命名附件';

String _attachmentDetail(Attachment attachment) {
  final parts = <String>[];
  if (_nullableText(attachment.mimeType) case final mime?) parts.add(mime);
  if (attachment.byteSize case final bytes?) parts.add(_formatBytes(bytes));
  if (_nullableText(attachment.note) case final note?) parts.add(note);
  return parts.isEmpty
      ? '建立於 ${_formatDate(attachment.createdAt)}'
      : parts.join(' · ');
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String _cycleLabel(Schedule schedule) {
  final unit = switch (schedule.cycleType) {
    CycleType.daily => '天',
    CycleType.weekly => '週',
    CycleType.monthly => '月',
    CycleType.quarterly => '季',
    CycleType.semiAnnual => '半年',
    CycleType.yearly => '年',
    CycleType.custom => '自訂日期',
  };
  if (schedule.cycleType == CycleType.custom) {
    return unit;
  }
  return schedule.interval == 1 ? '每$unit' : '每 ${schedule.interval} $unit';
}

String _milestoneTriggerLabel(Milestone milestone) {
  if (milestone.triggerDate case final date?) {
    return '預定日期 ${_formatDate(date)}';
  }
  if (milestone.thresholdValue case final value?) {
    final number = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
    return '條件 $number ${milestone.thresholdUnit ?? ''}'.trim();
  }
  if (_nullableText(milestone.lifeStageCode) case final stage?) {
    return '人生階段：$stage';
  }
  return _nullableText(milestone.description) ?? '手動建立的階段性重點';
}

String _maintenancePlanTypeLabel(MaintenancePlanType type) => switch (type) {
  MaintenancePlanType.cleaning => '清潔保養',
  MaintenancePlanType.inspection => '檢查',
  MaintenancePlanType.replacement => '定期更換',
  MaintenancePlanType.routineService => '例行保養',
  MaintenancePlanType.expiryReview => '期限檢查',
  MaintenancePlanType.custom => '自訂保養',
};

String _maintenancePlanStatusLabel(MaintenancePlanStatus status) =>
    switch (status) {
      MaintenancePlanStatus.active => '進行中',
      MaintenancePlanStatus.paused => '已暫停',
      MaintenancePlanStatus.archived => '已封存',
    };

String _riskLabel(RiskLevel level) => switch (level) {
  RiskLevel.low => '低',
  RiskLevel.medium => '中',
  RiskLevel.high => '高',
  RiskLevel.unknown => '未設定',
};

String _reminderTypeLabel(String type) => switch (type) {
  'expiry' => '到期提醒',
  'payment' => '繳費提醒',
  'renewal' => '續約提醒',
  'health' => '健康提醒',
  _ => '一般提醒',
};

String _scheduleStatusLabel(ScheduleStatus status) => switch (status) {
  ScheduleStatus.active => '進行中',
  ScheduleStatus.paused => '已暫停',
  ScheduleStatus.ended => '已結束',
};

String _milestoneKindLabel(MilestoneKind kind) => switch (kind) {
  MilestoneKind.majorService => '大修／大保養',
  MilestoneKind.deepInspection => '深度檢查',
  MilestoneKind.replacementEvaluation => '汰換評估',
  MilestoneKind.renewal => '續約／換發',
  MilestoneKind.careTransition => '照護階段',
  MilestoneKind.custom => '自訂重點',
};

String _milestoneStatusLabel(MilestoneStatus status) => switch (status) {
  MilestoneStatus.pending => '條件未到',
  MilestoneStatus.reached => '條件已到',
  MilestoneStatus.acknowledged => '已確認',
  MilestoneStatus.inProgress => '處理中',
  MilestoneStatus.completed => '已完成',
  MilestoneStatus.canceled => '已取消',
  MilestoneStatus.archived => '已封存',
};

String _workCaseTypeLabel(WorkCaseType type) => switch (type) {
  WorkCaseType.maintenance => '保養案件',
  WorkCaseType.repair => '修理案件',
  WorkCaseType.construction => '工程案件',
  WorkCaseType.administrative => '辦理案件',
  WorkCaseType.other => '生活案件',
};

String _workCaseStatusLabel(WorkCaseStatus status) => switch (status) {
  WorkCaseStatus.notStarted => '尚未開始',
  WorkCaseStatus.inProgress => '處理中',
  WorkCaseStatus.waiting => '等待中',
  WorkCaseStatus.completed => '已完成',
  WorkCaseStatus.canceled => '已取消',
};

String _attachmentKindLabel(AttachmentKind kind) => switch (kind) {
  AttachmentKind.photo => '照片',
  AttachmentKind.document => '文件',
  AttachmentKind.receipt => '收據',
  AttachmentKind.other => '附件',
};

String _attachmentStateLabel(AttachmentState state) => switch (state) {
  AttachmentState.available => '可使用',
  AttachmentState.missing => '檔案遺失',
  AttachmentState.deleted => '已刪除',
  AttachmentState.unknown => '狀態未知',
};

String _categoryLabel(ItemCategory category) => switch (category) {
  ItemCategory.appliance => '家電',
  ItemCategory.vehicle => '車輛',
  ItemCategory.house => '房屋',
  ItemCategory.warrantyDocument => '文件與保固',
  ItemCategory.other => '其他',
};

IconData _iconForCategory(ItemCategory category) => switch (category) {
  ItemCategory.appliance => Icons.ac_unit_outlined,
  ItemCategory.vehicle => Icons.directions_car_outlined,
  ItemCategory.house => Icons.home_work_outlined,
  ItemCategory.warrantyDocument => Icons.description_outlined,
  ItemCategory.other => Icons.inventory_2_outlined,
};

String _itemStatusLabel(ItemStatus status) => switch (status) {
  ItemStatus.active => '正常管理',
  ItemStatus.paused => '暫停管理',
  ItemStatus.archived => '已封存',
};

String _genericStatusLabel(String status) => switch (status) {
  'active' => '進行中',
  'paused' => '已暫停',
  'completed' => '已完成',
  'canceled' => '已取消',
  'archived' => '已封存',
  'ended' => '已結束',
  'pending' => '等待中',
  _ => '已記錄',
};

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}/$month/$day';
}

String? _nullableText(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
