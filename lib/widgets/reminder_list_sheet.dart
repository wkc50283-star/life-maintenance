import 'package:flutter/material.dart';

import '../models/item.dart';
import '../models/schedule.dart';
import '../repositories/item_local_repository.dart';
import '../repositories/schedule_local_repository.dart';
import '../services/local_storage_service.dart';

void showReminderListSheet(BuildContext context) {
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
        child: const _ReminderListSheet(),
      );
    },
  );
}

class _ReminderListSheet extends StatefulWidget {
  const _ReminderListSheet();

  @override
  State<_ReminderListSheet> createState() => _ReminderListSheetState();
}

class _ReminderListSheetState extends State<_ReminderListSheet> {
  final LocalStorageService _storageService = LocalStorageService();
  late final ScheduleLocalRepository _scheduleRepository =
      ScheduleLocalRepository(_storageService);
  late final ItemLocalRepository _itemRepository = ItemLocalRepository(
    _storageService,
  );
  List<Schedule>? _schedules;
  List<Item>? _items;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final schedules = await _scheduleRepository.loadSchedules();
    final items = await _itemRepository.loadItems();
    if (!mounted) {
      return;
    }

    setState(() {
      _schedules = schedules
          .where((schedule) => schedule.cardId == 'manual-expiry-reminder')
          .toList();
      _items = items;
    });
  }

  @override
  Widget build(BuildContext context) {
    final schedules = _schedules;
    final items = _items ?? const <Item>[];

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
            '需要你記住的事',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF263746),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '這裡只顯示你已建立的本機提醒。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF687887),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          if (schedules == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (schedules.isEmpty)
            const _EmptyReminderState()
          else
            for (final schedule in schedules)
              _ReminderTile(
                title: _titleForSchedule(schedule),
                itemName: _itemNameForSchedule(schedule, items),
                dueDate: _formatDate(schedule.nextDueDate),
                status: _statusForSchedule(schedule),
                onTap: () {
                  _showReminderDetailSheet(
                    context,
                    title: _titleForSchedule(schedule),
                    itemName: _itemNameForSchedule(schedule, items),
                    dueDate: _formatDate(schedule.nextDueDate),
                    status: _statusForSchedule(schedule),
                  );
                },
              ),
        ],
      ),
    );
  }
}

class _EmptyReminderState extends StatelessWidget {
  const _EmptyReminderState();

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
      child: Text(
        '目前沒有需要你記住的事',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF4D5D6B),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  final String title;
  final String itemName;
  final String dueDate;
  final String status;
  final VoidCallback? onTap;

  const _ReminderTile({
    required this.title,
    required this.itemName,
    required this.dueDate,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
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
              '事項名稱',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: const Color(0xFF5D7893),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
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
                _ReminderTag(label: '所屬項目：$itemName'),
                _ReminderTag(label: '提醒日期：$dueDate'),
                _ReminderTag(label: '狀態：$status'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void _showReminderDetailSheet(
  BuildContext context, {
  required String title,
  required String itemName,
  required String dueDate,
  required String status,
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
        child: SingleChildScrollView(
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
                '事項詳情',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF263746),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              _ReminderDetailRow(label: '事項名稱', value: title),
              _ReminderDetailRow(label: '所屬項目', value: itemName),
              _ReminderDetailRow(label: '提醒日期', value: dueDate),
              _ReminderDetailRow(label: '狀態', value: status),
            ],
          ),
        ),
      );
    },
  );
}

class _ReminderDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReminderDetailRow({required this.label, required this.value});

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
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFF5D7893),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
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

class _ReminderTag extends StatelessWidget {
  final String label;

  const _ReminderTag({required this.label});

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

String _titleForSchedule(Schedule schedule) {
  final title = schedule.title?.trim();
  if (title == null || title.isEmpty) {
    return '需要你記住的事';
  }

  return title;
}

String _itemNameForSchedule(Schedule schedule, List<Item> items) {
  for (final item in items) {
    if (item.id == schedule.itemId) {
      return item.name;
    }
  }

  return '項目不存在';
}

String _statusForSchedule(Schedule schedule) {
  if (!schedule.enabled) {
    return '已取消';
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dueDate = DateTime(
    schedule.nextDueDate.year,
    schedule.nextDueDate.month,
    schedule.nextDueDate.day,
  );

  return dueDate.isAfter(today) ? '尚未到期' : '已到期';
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}/$month/$day';
}
