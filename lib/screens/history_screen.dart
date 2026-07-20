import 'package:flutter/material.dart';

import '../app/app_composition_root.dart';
import '../models/enums.dart';
import '../models/history_projection.dart';
import '../models/item.dart';
import '../models/maintenance_record.dart';
import '../models/milestone_enums.dart';
import '../models/work_case_enums.dart';
import '../repositories/history_projection_repository.dart';
import '../repositories/item_read_repository.dart';
import '../widgets/empty_history_state.dart';
import '../widgets/history_header.dart';
import '../widgets/history_month_section.dart';
import '../widgets/history_record_card.dart';
import '../widgets/maintenance_record_detail_sheet.dart';
import 'work_case_screens.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late HistoryProjectionRepository _historyRepository;
  late ItemReadRepository _itemRepository;
  bool _dependenciesInitialized = false;
  List<HistoryProjection>? _projections;
  List<Item>? _localItems;
  Object? _loadError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dependenciesInitialized) {
      return;
    }
    final root = AppCompositionScope.of(context);
    final historyRepository = root.historyProjectionRepository;
    _dependenciesInitialized = true;
    if (historyRepository == null) {
      _loadError = StateError('正式史略服務目前無法使用。');
      return;
    }
    _historyRepository = historyRepository;
    _itemRepository = root.itemReadRepository;
    _loadLocalData();
  }

  @override
  void activate() {
    super.activate();
    _loadLocalData();
  }

  Future<void> _loadLocalData() async {
    try {
      final items = await _itemRepository.loadItems();
      final projections = await Future.wait([
        for (final item in items) _historyRepository.projectForItem(item.id),
      ]);
      if (!mounted) return;
      setState(() {
        _projections = projections;
        _localItems = items;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return _HistoryLoadFailure(onRetry: _retry);
    }
    if (_projections == null || _localItems == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final projections = _projections ?? const <HistoryProjection>[];
    final items = _localItems ?? const <Item>[];
    final sections = _historySectionsFrom(projections, items);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const HistoryHeader(),
        const SizedBox(height: 20),
        if (sections.isEmpty)
          const EmptyHistoryState()
        else
          for (final section in sections)
            HistoryMonthSection(
              month: section.month,
              children: [
                for (final record in section.records)
                  HistoryRecordCard(
                    date: record.date,
                    title: record.title,
                    itemName: record.itemName,
                    recordType: record.recordType,
                    description: record.description,
                    detailLines: record.detailLines,
                    result: record.result,
                    costLabel: record.costLabel,
                    photoLabel: record.photoLabel,
                    icon: record.icon,
                    onTap: record.workCaseId != null || record.detail != null
                        ? () => _openEntry(record)
                        : null,
                  ),
              ],
            ),
      ],
    );
  }

  void _retry() {
    setState(() => _loadError = null);
    _loadLocalData();
  }

  Future<void> _openEntry(_HistoryEntryData entry) async {
    if (entry.workCaseId case final workCaseId?) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => WorkCaseDetailScreen(
            workCaseId: workCaseId,
            itemName: entry.itemName,
          ),
        ),
      );
      return;
    }
    if (entry.detail case final detail?) {
      showMaintenanceRecordDetailSheet(context, data: detail);
    }
  }
}

class _HistoryLoadFailure extends StatelessWidget {
  const _HistoryLoadFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_toggle_off_outlined, size: 40),
            const SizedBox(height: 12),
            Text(
              '暫時無法讀取史略。',
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

class _HistoryMonthSection {
  final String month;
  final List<_HistoryEntryData> records;

  const _HistoryMonthSection({required this.month, required this.records});
}

class _HistoryEntryData {
  final String date;
  final String title;
  final String itemName;
  final String recordType;
  final String description;
  final List<String> detailLines;
  final String result;
  final String? costLabel;
  final String? photoLabel;
  final IconData icon;
  final MaintenanceRecordDetailData? detail;
  final String? workCaseId;

  const _HistoryEntryData({
    required this.date,
    required this.title,
    required this.itemName,
    required this.recordType,
    required this.description,
    required this.detailLines,
    required this.result,
    required this.costLabel,
    required this.photoLabel,
    required this.icon,
    this.detail,
    this.workCaseId,
  });
}

List<_HistoryMonthSection> _historySectionsFrom(
  List<HistoryProjection> projections,
  List<Item> items,
) {
  final groupedRecords = <String, List<_HistoryEntryData>>{};
  final entries = [
    for (final projection in projections)
      for (final entry in projection.entries) entry,
  ]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

  for (final entry in entries) {
    final month = '${entry.occurredAt.year} 年 ${entry.occurredAt.month} 月';
    groupedRecords.putIfAbsent(month, () => []);
    groupedRecords[month]!.add(_historyEntryForProjection(entry, items));
  }

  return [
    for (final entry in groupedRecords.entries)
      _HistoryMonthSection(month: entry.key, records: entry.value),
  ];
}

_HistoryEntryData _historyEntryForProjection(
  HistoryEntry entry,
  List<Item> items,
) => switch (entry) {
  WorkCaseHistoryEntry() => _historyEntryForWorkCase(entry, items),
  MaintenanceRecordHistoryEntry(:final record) => _historyEntryFor(
    record,
    items,
  ),
  TaskHistoryEntry(:final task) => _HistoryEntryData(
    date: _formatShortDate(entry.occurredAt),
    title: task.title,
    itemName: _itemName(task.itemId, items),
    recordType: '提醒紀錄',
    description: '提醒日期 ${_formatDate(task.dueDate)}',
    detailLines: const [],
    result: task.status == 'completed' ? '已完成' : '已取消',
    costLabel: null,
    photoLabel: null,
    icon: _iconForItem(_itemById(task.itemId, items)),
  ),
  MilestoneHistoryEntry(:final milestone, :final attachments) =>
    _HistoryEntryData(
      date: _formatShortDate(entry.occurredAt),
      title: milestone.title,
      itemName: _itemName(milestone.itemId, items),
      recordType: '階段性重點',
      description: _nullableText(milestone.description) ?? '已留下階段性重點紀錄。',
      detailLines: const [],
      result: _milestoneStatusLabel(milestone.status),
      costLabel: null,
      photoLabel: attachments.isEmpty ? null : '附件 ${attachments.length} 份',
      icon: _iconForItem(_itemById(milestone.itemId, items)),
    ),
};

_HistoryEntryData _historyEntryForWorkCase(
  WorkCaseHistoryEntry entry,
  List<Item> items,
) {
  final workCase = entry.workCase;
  final closure = entry.closure;
  final latestUpdate = entry.updates.isEmpty ? null : entry.updates.last;
  return _HistoryEntryData(
    date: _formatShortDate(entry.occurredAt),
    title: workCase.title,
    itemName: _itemName(workCase.itemId, items),
    recordType: '案件史略',
    description:
        _nullableText(closure?.completionSummary) ??
        _nullableText(latestUpdate?.description) ??
        '案件已正式終止並保留完整過程。',
    detailLines: [
      '處理進度：${entry.updates.length} 筆',
      if (_nullableText(closure?.followUpNotes) case final notes?)
        '後續注意：$notes',
    ],
    result:
        _nullableText(closure?.finalResult) ??
        (workCase.status == WorkCaseStatus.canceled ? '已取消' : '已完成'),
    costLabel: closure == null ? null : '總費用：${closure.totalCost}',
    photoLabel: entry.attachments.isEmpty
        ? null
        : '附件 ${entry.attachments.length} 份',
    icon: _iconForItem(_itemById(workCase.itemId, items)),
    workCaseId: workCase.id,
  );
}

_HistoryEntryData _historyEntryFor(MaintenanceRecord record, List<Item> items) {
  final item = _itemForRecord(record, items);
  final result = _nullableText(record.result) ?? '已記錄';
  final workDescription = _nullableText(record.workDescription);
  final vendorName = _nullableText(record.vendorName);
  final partsChanged = record.partsChanged
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
  final note = _nullableText(record.note);
  final issueDescription = _nullableText(record.issueDescription);
  final description =
      workDescription ?? issueDescription ?? note ?? '已留下保養維修紀錄。';
  final descriptionUsesWorkDescription =
      workDescription != null && description == workDescription;
  final descriptionUsesNote = note != null && description == note;

  return _HistoryEntryData(
    date: _formatShortDate(record.date),
    title: record.title,
    itemName: item?.name ?? '未命名生活項目',
    recordType: _labelForRecordType(record.recordType),
    description: description,
    detailLines: [
      if (workDescription != null && !descriptionUsesWorkDescription)
        '處理內容：$workDescription',
      if (vendorName != null) '店家：$vendorName',
      if (partsChanged.isNotEmpty) '更換零件：${partsChanged.join('、')}',
      if (note != null && !descriptionUsesNote) '備註：$note',
    ],
    result: result,
    costLabel: record.cost == null ? null : '費用：${record.cost}',
    photoLabel: record.photos.isEmpty ? null : '照片 ${record.photos.length} 張',
    icon: _iconForItem(item),
    detail: _detailDataFor(record),
  );
}

MaintenanceRecordDetailData _detailDataFor(MaintenanceRecord record) {
  final result = _nullableText(record.result) ?? '已記錄';
  final partsChanged = record.partsChanged
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();

  return MaintenanceRecordDetailData(
    title: record.title,
    recordType: _labelForRecordType(record.recordType),
    date: _formatDate(record.date),
    result: result,
    rows: [
      if (_nullableText(record.issueDescription) != null)
        MaintenanceRecordDetailRow(
          label: '問題描述',
          value: record.issueDescription!.trim(),
        ),
      if (_nullableText(record.workDescription) != null)
        MaintenanceRecordDetailRow(
          label: '處理內容',
          value: record.workDescription!.trim(),
        ),
      if (partsChanged.isNotEmpty)
        MaintenanceRecordDetailRow(
          label: '更換零件',
          value: partsChanged.join('、'),
        ),
      if (record.cost != null)
        MaintenanceRecordDetailRow(label: '費用', value: record.cost.toString()),
      if (_nullableText(record.vendorName) != null)
        MaintenanceRecordDetailRow(
          label: '店家',
          value: record.vendorName!.trim(),
        ),
      if (record.warrantyUntil != null)
        MaintenanceRecordDetailRow(
          label: '保固到期',
          value: _formatDate(record.warrantyUntil!),
        ),
      if (_nullableText(record.note) != null)
        MaintenanceRecordDetailRow(label: '備註', value: record.note!.trim()),
      MaintenanceRecordDetailRow(
        label: '建立日期',
        value: _formatDate(record.createdAt),
      ),
    ],
  );
}

Item? _itemForRecord(MaintenanceRecord record, List<Item> items) {
  return _itemById(record.itemId, items);
}

Item? _itemById(String itemId, List<Item> items) {
  for (final item in items) {
    if (item.id == itemId) return item;
  }
  return null;
}

String _itemName(String itemId, List<Item> items) =>
    _itemById(itemId, items)?.name ?? '未命名生活項目';

IconData _iconForItem(Item? item) {
  return switch (item?.category) {
    ItemCategory.appliance => Icons.ac_unit_outlined,
    ItemCategory.vehicle => Icons.two_wheeler_outlined,
    ItemCategory.house => Icons.home_work_outlined,
    ItemCategory.warrantyDocument => Icons.description_outlined,
    ItemCategory.other || null => Icons.inventory_2_outlined,
  };
}

String _labelForRecordType(RecordType type) {
  return switch (type) {
    RecordType.regularMaintenance => '保養',
    RecordType.failure => '故障',
    RecordType.repair => '維修',
    RecordType.partsReplacement => '更換',
    RecordType.expiryHandled => '到期提醒',
    RecordType.construction => '施工',
    RecordType.other => '其他',
  };
}

String _milestoneStatusLabel(MilestoneStatus status) => switch (status) {
  MilestoneStatus.completed => '已完成',
  MilestoneStatus.canceled => '已取消',
  MilestoneStatus.archived => '已封存',
  MilestoneStatus.pending => '條件未到',
  MilestoneStatus.reached => '條件已到',
  MilestoneStatus.acknowledged => '已確認',
  MilestoneStatus.inProgress => '處理中',
};

String? _nullableText(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }

  return trimmed;
}

String _formatShortDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$month/$day';
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}/$month/$day';
}
