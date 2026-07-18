import 'package:flutter/material.dart';

import '../app/app_composition_root.dart';
import '../models/enums.dart';
import '../models/item.dart';
import '../models/maintenance_record.dart';
import '../repositories/item_local_repository.dart';
import '../repositories/maintenance_record_local_repository.dart';
import '../widgets/empty_history_state.dart';
import '../widgets/history_header.dart';
import '../widgets/history_month_section.dart';
import '../widgets/history_record_card.dart';
import '../widgets/maintenance_record_detail_sheet.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late MaintenanceRecordLocalRepository _recordRepository;
  late ItemLocalRepository _itemRepository;
  bool _dependenciesInitialized = false;
  List<MaintenanceRecord>? _localRecords;
  List<Item>? _localItems;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dependenciesInitialized) {
      return;
    }
    final root = AppCompositionScope.of(context);
    _recordRepository = root.maintenanceRecordRepository;
    _itemRepository = root.itemRepository;
    _dependenciesInitialized = true;
    _loadLocalData();
  }

  @override
  void activate() {
    super.activate();
    _loadLocalData();
  }

  Future<void> _loadLocalData() async {
    final records = await _recordRepository.loadRecords();
    final items = await _itemRepository.loadItems();
    if (!mounted) {
      return;
    }

    setState(() {
      _localRecords = records;
      _localItems = items;
    });
  }

  @override
  Widget build(BuildContext context) {
    final records = _localRecords ?? const <MaintenanceRecord>[];
    final items = _localItems ?? const <Item>[];
    final sections = _historySectionsFrom(records, items);

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
                    onTap: () {
                      showMaintenanceRecordDetailSheet(
                        context,
                        data: record.detail,
                      );
                    },
                  ),
              ],
            ),
      ],
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
  final MaintenanceRecordDetailData detail;

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
    required this.detail,
  });
}

List<_HistoryMonthSection> _historySectionsFrom(
  List<MaintenanceRecord> records,
  List<Item> items,
) {
  final groupedRecords = <String, List<_HistoryEntryData>>{};
  final sortedRecords = [...records]..sort((a, b) => b.date.compareTo(a.date));

  for (final record in sortedRecords) {
    final month = '${record.date.year} 年 ${record.date.month} 月';
    groupedRecords.putIfAbsent(month, () => []);
    groupedRecords[month]!.add(_historyEntryFor(record, items));
  }

  return [
    for (final entry in groupedRecords.entries)
      _HistoryMonthSection(month: entry.key, records: entry.value),
  ];
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
  for (final item in items) {
    if (item.id == record.itemId) {
      return item;
    }
  }

  return null;
}

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
