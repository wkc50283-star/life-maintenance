import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/enums.dart';
import '../models/item.dart';
import '../models/maintenance_record.dart';
import '../repositories/item_local_repository.dart';
import '../repositories/maintenance_record_local_repository.dart';
import '../services/local_storage_service.dart';
import '../widgets/empty_history_state.dart';
import '../widgets/history_category_chips.dart';
import '../widgets/history_header.dart';
import '../widgets/history_month_section.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  static const _categories = ['全部', '保養', '維修', '更換', '到期提醒'];

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final MaintenanceRecordLocalRepository _recordRepository =
      MaintenanceRecordLocalRepository(LocalStorageService());
  final ItemLocalRepository _itemRepository = ItemLocalRepository(
    LocalStorageService(),
  );
  List<MaintenanceRecord>? _localRecords;
  List<Item>? _localItems;

  @override
  void initState() {
    super.initState();
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
    final localRecords = _localRecords;
    final records = localRecords == null || localRecords.isEmpty
        ? MockData.maintenanceRecords
        : localRecords;
    final localItems = _localItems;
    final items = localItems == null || localItems.isEmpty
        ? MockData.items
        : [...localItems, ...MockData.items];
    final sections = _historySectionsFrom(records, items);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const HistoryHeader(),
        const SizedBox(height: 18),
        const HistoryCategoryChips(categories: HistoryScreen._categories),
        const SizedBox(height: 20),
        if (sections.isEmpty)
          const EmptyHistoryState()
        else
          for (final section in sections)
            HistoryMonthSection(
              month: section.month,
              children: [
                for (final record in section.records)
                  _HistoryRecordCard(
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

  return _HistoryEntryData(
    date: _formatShortDate(record.date),
    title: record.title,
    itemName: item?.name ?? '未命名物品',
    recordType: _labelForRecordType(record.recordType),
    description:
        _nullableText(record.issueDescription) ??
        workDescription ??
        note ??
        '已留下保養維修紀錄。',
    detailLines: [
      if (workDescription != null) '處理內容：$workDescription',
      if (vendorName != null) '店家：$vendorName',
      if (partsChanged.isNotEmpty) '更換零件：${partsChanged.join('、')}',
      if (note != null) '備註：$note',
    ],
    result: result,
    costLabel: record.cost == null ? null : '費用：${record.cost}',
    photoLabel: record.photos.isEmpty ? null : '照片 ${record.photos.length} 張',
    icon: _iconForItem(item),
  );
}

class _HistoryRecordCard extends StatelessWidget {
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

  const _HistoryRecordCard({
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
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0F6),
                    borderRadius: BorderRadius.circular(16),
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: const Color(0xFF263746),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _SoftTag(label: date),
                          _SoftTag(label: recordType),
                          _SoftTag(label: itemName),
                        ],
                      ),
                    ],
                  ),
                ),
                _ResultTag(label: result),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF4D5D6B),
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (detailLines.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final line in detailLines) _DetailLine(text: line),
            ],
            if (costLabel != null || photoLabel != null) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (costLabel != null)
                    _MetaTag(
                      icon: Icons.payments_outlined,
                      label: costLabel!,
                    ),
                  if (photoLabel != null)
                    _MetaTag(
                      icon: Icons.photo_library_outlined,
                      label: photoLabel!,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  final String text;

  const _DetailLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: const Color(0xFF687887),
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SoftTag extends StatelessWidget {
  final String label;

  const _SoftTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5F8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: const Color(0xFF5D7893),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ResultTag extends StatelessWidget {
  final String label;

  const _ResultTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4EA),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFC9DEC9)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: const Color(0xFF456A4A),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetaTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFEAD9B8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF7A6338)),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFF7A6338),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
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
