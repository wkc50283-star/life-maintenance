import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/enums.dart';
import '../models/item.dart';
import '../models/maintenance_record.dart';
import '../widgets/history_category_chips.dart';
import '../widgets/history_header.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  static const _categories = ['全部', '保養', '維修', '更換', '到期提醒'];

  @override
  Widget build(BuildContext context) {
    final sections = _historySectionsFrom(MockData.maintenanceRecords);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const HistoryHeader(),
        const SizedBox(height: 18),
        const HistoryCategoryChips(categories: _categories),
        const SizedBox(height: 20),
        if (sections.isEmpty)
          const _EmptyHistoryState()
        else
          for (final section in sections) _MonthSection(section: section),
      ],
    );
  }
}

class _MonthSection extends StatelessWidget {
  final _HistoryMonthSection section;

  const _MonthSection({required this.section});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 10),
            child: Text(
              section.month,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF263746),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          for (final record in section.records)
            _HistoryRecordCard(record: record),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _HistoryRecordCard extends StatelessWidget {
  final _HistoryEntryData record;

  const _HistoryRecordCard({required this.record});

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
                  child: Icon(record.icon, color: const Color(0xFF5D7893)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.title,
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
                          _SoftTag(label: record.date),
                          _SoftTag(label: record.recordType),
                          _SoftTag(label: record.itemName),
                        ],
                      ),
                    ],
                  ),
                ),
                _ResultTag(label: record.result),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              record.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF4D5D6B),
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaTag(
                  icon: Icons.payments_outlined,
                  label: record.costLabel,
                ),
                if (record.photoLabel != null)
                  _MetaTag(
                    icon: Icons.photo_library_outlined,
                    label: record.photoLabel!,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4E0D8)),
      ),
      child: Text(
        '目前還沒有履歷紀錄。',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF687887),
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
  final String result;
  final String costLabel;
  final String? photoLabel;
  final IconData icon;

  const _HistoryEntryData({
    required this.date,
    required this.title,
    required this.itemName,
    required this.recordType,
    required this.description,
    required this.result,
    required this.costLabel,
    required this.photoLabel,
    required this.icon,
  });
}

List<_HistoryMonthSection> _historySectionsFrom(
  List<MaintenanceRecord> records,
) {
  final groupedRecords = <String, List<_HistoryEntryData>>{};
  final sortedRecords = [...records]..sort((a, b) => b.date.compareTo(a.date));

  for (final record in sortedRecords) {
    final month = '${record.date.year} 年 ${record.date.month} 月';
    groupedRecords.putIfAbsent(month, () => []);
    groupedRecords[month]!.add(_historyEntryFor(record));
  }

  return [
    for (final entry in groupedRecords.entries)
      _HistoryMonthSection(month: entry.key, records: entry.value),
  ];
}

_HistoryEntryData _historyEntryFor(MaintenanceRecord record) {
  final item = _itemForRecord(record);
  final result = record.result ?? record.note ?? '已記錄';

  return _HistoryEntryData(
    date: _formatShortDate(record.date),
    title: record.title,
    itemName: item?.name ?? '未命名物品',
    recordType: _labelForRecordType(record.recordType),
    description:
        record.workDescription ??
        record.issueDescription ??
        record.note ??
        '已留下保養維修紀錄。',
    result: result,
    costLabel: record.cost == null ? '未記錄費用' : 'NT\$ ${record.cost}',
    photoLabel: record.photos.isEmpty ? null : '照片 ${record.photos.length} 張',
    icon: _iconForItem(item),
  );
}

Item? _itemForRecord(MaintenanceRecord record) {
  for (final item in MockData.items) {
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

String _formatShortDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$month/$day';
}
