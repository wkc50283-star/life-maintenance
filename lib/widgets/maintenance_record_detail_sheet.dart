import 'package:flutter/material.dart';

class MaintenanceRecordDetailData {
  final String title;
  final String recordType;
  final String date;
  final String result;
  final List<MaintenanceRecordDetailRow> rows;

  const MaintenanceRecordDetailData({
    required this.title,
    required this.recordType,
    required this.date,
    required this.result,
    required this.rows,
  });
}

class MaintenanceRecordDetailRow {
  final String label;
  final String value;

  const MaintenanceRecordDetailRow({required this.label, required this.value});
}

void showMaintenanceRecordDetailSheet(
  BuildContext context, {
  required MaintenanceRecordDetailData data,
}) {
  showModalBottomSheet<void>(
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
        child: _MaintenanceRecordDetailSheet(data: data),
      );
    },
  );
}

class _MaintenanceRecordDetailSheet extends StatelessWidget {
  final MaintenanceRecordDetailData data;

  const _MaintenanceRecordDetailSheet({required this.data});

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
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DetailTag(label: data.date),
              _DetailTag(label: data.recordType),
              _DetailTag(label: data.result),
            ],
          ),
          const SizedBox(height: 18),
          for (final row in data.rows) _DetailRow(row: row),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final MaintenanceRecordDetailRow row;

  const _DetailRow({required this.row});

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

class _DetailTag extends StatelessWidget {
  final String label;

  const _DetailTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0F6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD6E2EC)),
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
