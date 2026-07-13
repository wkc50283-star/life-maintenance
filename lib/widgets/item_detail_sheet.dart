import 'package:flutter/material.dart';

import 'maintenance_record_detail_sheet.dart';

class ItemDetailData {
  final String title;
  final List<ItemDetailRow> rows;
  final List<ItemDetailMaintenanceSchedule> maintenanceSchedules;
  final List<ItemDetailMaintenanceRecord> maintenanceRecords;
  final List<ItemDetailReminder> reminders;

  const ItemDetailData({
    required this.title,
    required this.rows,
    this.maintenanceSchedules = const [],
    this.maintenanceRecords = const [],
    this.reminders = const [],
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

enum ItemDetailScheduleResumeResult { updated, conflict, failed }

class ItemDetailMaintenanceSchedule {
  final String id;
  final String title;
  final String nextDueDate;
  final DateTime rawNextDueDate;
  final String status;
  final bool canResume;
  final Future<ItemDetailScheduleResumeResult> Function(DateTime selectedDate)?
  onReschedule;

  const ItemDetailMaintenanceSchedule({
    required this.id,
    required this.title,
    required this.nextDueDate,
    required this.rawNextDueDate,
    required this.status,
    this.canResume = false,
    this.onReschedule,
  });
}

class ItemDetailReminder {
  final String title;
  final String dueDate;
  final String status;

  const ItemDetailReminder({
    required this.title,
    required this.dueDate,
    required this.status,
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
          _RemindersSection(reminders: data.reminders),
          const SizedBox(height: 10),
          _MaintenanceSchedulesSection(schedules: data.maintenanceSchedules),
          const SizedBox(height: 10),
          _MaintenanceRecordsSection(records: data.maintenanceRecords),
        ],
      ),
    );
  }
}

class _RemindersSection extends StatelessWidget {
  final List<ItemDetailReminder> reminders;

  const _RemindersSection({required this.reminders});

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
            '需要你記住的事',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: const Color(0xFF263746),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          if (reminders.isEmpty)
            Text(
              '目前沒有需要你記住的事',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF4D5D6B),
                fontWeight: FontWeight.w700,
              ),
            )
          else
            for (final reminder in reminders)
              _ReminderSummaryTile(reminder: reminder),
        ],
      ),
    );
  }
}

class _ReminderSummaryTile extends StatelessWidget {
  final ItemDetailReminder reminder;

  const _ReminderSummaryTile({required this.reminder});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            '事項名稱',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFF5D7893),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            reminder.title,
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
              _RecordSummaryTag(label: '提醒日期：${reminder.dueDate}'),
              _RecordSummaryTag(label: '狀態：${reminder.status}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MaintenanceSchedulesSection extends StatelessWidget {
  final List<ItemDetailMaintenanceSchedule> schedules;

  const _MaintenanceSchedulesSection({required this.schedules});

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
            '保養安排',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: const Color(0xFF263746),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          if (schedules.isEmpty)
            Text(
              '目前沒有保養安排',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF4D5D6B),
                fontWeight: FontWeight.w700,
              ),
            )
          else
            for (final schedule in schedules)
              _MaintenanceScheduleSummaryTile(schedule: schedule),
        ],
      ),
    );
  }
}

class _MaintenanceScheduleSummaryTile extends StatelessWidget {
  final ItemDetailMaintenanceSchedule schedule;

  const _MaintenanceScheduleSummaryTile({required this.schedule});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            schedule.title,
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
              _RecordSummaryTag(label: '下次日期：${schedule.nextDueDate}'),
              _RecordSummaryTag(label: '狀態：${schedule.status}'),
            ],
          ),
          if (schedule.canResume && schedule.onReschedule != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    _rescheduleMaintenanceSchedule(context, schedule: schedule),
                icon: const Icon(Icons.event_available_outlined),
                label: const Text('重新安排並恢復'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> _rescheduleMaintenanceSchedule(
  BuildContext context, {
  required ItemDetailMaintenanceSchedule schedule,
}) async {
  final today = _dateOnly(DateTime.now());
  final firstDate = today.add(const Duration(days: 1));
  final initialDate = _dateOnly(schedule.rawNextDueDate).isAfter(today)
      ? _dateOnly(schedule.rawNextDueDate)
      : firstDate;
  final selectedDate = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: DateTime(2100),
    helpText: '重新安排並恢復',
  );

  if (selectedDate == null) {
    return;
  }

  final result = await schedule.onReschedule!(selectedDate);
  if (!context.mounted) {
    return;
  }

  switch (result) {
    case ItemDetailScheduleResumeResult.updated:
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('保養安排已重新安排並恢復'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    case ItemDetailScheduleResumeResult.conflict:
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('這個日期已有待處理提醒，請選擇其他日期'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    case ItemDetailScheduleResumeResult.failed:
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('重新安排失敗，請稍後再試'),
          behavior: SnackBarBehavior.floating,
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

DateTime _dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
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
