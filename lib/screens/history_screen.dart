import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  static const _categories = ['全部', '保養', '維修', '更換', '到期提醒'];

  static const _sections = [
    _HistoryMonthSection(
      month: '2026 年 7 月',
      records: [
        _HistoryEntryData(
          date: '07/03',
          itemName: '客廳冷氣',
          recordType: '保養',
          description: '建立清洗濾網提醒，確認每月保養週期。',
          result: '正常',
          costLabel: null,
          photoLabel: '照片 1 張',
          icon: Icons.ac_unit_outlined,
        ),
        _HistoryEntryData(
          date: '07/03',
          itemName: '機車',
          recordType: '保養',
          description: '建立胎壓檢查提醒，排入每週維護。',
          result: '已排程',
          costLabel: null,
          photoLabel: null,
          icon: Icons.two_wheeler_outlined,
        ),
      ],
    ),
    _HistoryMonthSection(
      month: '2026 年 6 月',
      records: [
        _HistoryEntryData(
          date: '06/18',
          itemName: '浴室門鎖',
          recordType: '更換',
          description: '更換門鎖內芯，保留零件與保固資訊。',
          result: '已完成',
          costLabel: 'NT\$ 850',
          photoLabel: '照片 2 張',
          icon: Icons.door_front_door_outlined,
        ),
        _HistoryEntryData(
          date: '06/02',
          itemName: '租屋合約',
          recordType: '到期提醒',
          description: '建立合約到期前 30 天提醒。',
          result: '追蹤中',
          costLabel: null,
          photoLabel: null,
          icon: Icons.description_outlined,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const _HistoryHeader(),
        const SizedBox(height: 18),
        const _HistoryCategoryChips(categories: _categories),
        const SizedBox(height: 20),
        for (final section in _sections) _MonthSection(section: section),
      ],
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4E0D8)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '保養履歷',
            style: TextStyle(
              color: Color(0xFF263746),
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '修過什麼、換過什麼、花多少錢，都留在這裡。',
            style: TextStyle(
              color: Color(0xFF687887),
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCategoryChips extends StatelessWidget {
  final List<String> categories;

  const _HistoryCategoryChips({required this.categories});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final category in categories) ...[
            _HistoryChip(label: category, selected: category == '全部'),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _HistoryChip extends StatelessWidget {
  final String label;
  final bool selected;

  const _HistoryChip({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFDCE8F2) : const Color(0xFFFFFCF6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? const Color(0xFFB8CBDC) : const Color(0xFFE4E0D8),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: selected ? const Color(0xFF263746) : const Color(0xFF687887),
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
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
                        record.itemName,
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
            if (record.costLabel != null || record.photoLabel != null) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (record.costLabel != null)
                    _MetaTag(
                      icon: Icons.payments_outlined,
                      label: record.costLabel!,
                    ),
                  if (record.photoLabel != null)
                    _MetaTag(
                      icon: Icons.photo_library_outlined,
                      label: record.photoLabel!,
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
  final String itemName;
  final String recordType;
  final String description;
  final String result;
  final String? costLabel;
  final String? photoLabel;
  final IconData icon;

  const _HistoryEntryData({
    required this.date,
    required this.itemName,
    required this.recordType,
    required this.description,
    required this.result,
    required this.costLabel,
    required this.photoLabel,
    required this.icon,
  });
}
