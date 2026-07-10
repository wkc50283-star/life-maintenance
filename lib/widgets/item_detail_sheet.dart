import 'package:flutter/material.dart';

import 'maintenance_record_detail_sheet.dart';

class ItemDetailData {
  final String title;
  final List<ItemDetailRow> rows;
  final List<ItemDetailMaintenanceRecord> maintenanceRecords;

  const ItemDetailData({
    required this.title,
    required this.rows,
    this.maintenanceRecords = const [],
  });
}

class ItemDetailRow {
  final String label;
  final String value;

  const ItemDetailRow({required this.label, required this.value});
}

class ItemDetailMaintenanceRecord {
  final String date;
  final String title;
  final String recordType;
  final String result;
  final MaintenanceRecordDetailData detail;

  const ItemDetailMaintenanceRecord({
    required this.date,
    required this.title,
    required this.recordType,
    required this.result,
    required this.detail,
  });
}

Future<ItemDetailMaintenanceRecord?> showItemDetailSheet(
  BuildContext context, {
  required ItemDetailData data,
}) {
  return showModalBottomSheet<ItemDetailMaintenanceRecord>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFF7F3EA),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        ),
        child: _ItemDetailSheet(data: data),
      );
    },
  );
}

class _ItemDetailSheet extends StatelessWidget {
  final ItemDetailData data;

  const _ItemDetailSheet({required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFB8CBDC),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            data.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF263746),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          for (final row in data.rows) _ItemDetailRow(row: row),
          const SizedBox(height: 8),
          _MaintenanceRecordsSection(records: data.maintenanceRecords),
        ],
      ),
    );
  }
}

class _MaintenanceRecordsSection extends StatelessWidget {
  final List<ItemDetailMaintenanceRecord> records;

  const _MaintenanceRecordsSection({required this.records});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E0D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '處理紀錄',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: const Color(0xFF263746),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          if (records.isEmpty) ...[
            Text(
              '目前尚無處理紀錄',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF4D5D6B),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '之後完成處理時，紀錄會出現在這裡。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF687887),
                height: 1.4,
              ),
            ),
          ] else
            for (final record in records)
              _MaintenanceRecordSummaryTile(record: record),
        ],
      ),
    );
  }
}

class _MaintenanceRecordSummaryTile extends StatelessWidget {
  final ItemDetailMaintenanceRecord record;

  const _MaintenanceRecordSummaryTile({required this.record});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.of(context).pop(record),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F3EA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE4E0D8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              record.title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF263746),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _RecordSummaryTag(label: record.date),
                _RecordSummaryTag(label: record.recordType),
                _RecordSummaryTag(label: record.result),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordSummaryTag extends StatelessWidget {
  final String label;

  const _RecordSummaryTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0F6),
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

class _ItemDetailRow extends StatelessWidget {
  final ItemDetailRow row;

  const _ItemDetailRow({required this.row});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E0D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            row.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFF5D7893),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            row.value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF263746),
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
