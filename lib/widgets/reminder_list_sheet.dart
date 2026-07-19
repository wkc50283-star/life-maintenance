import 'package:flutter/material.dart';

import '../app/app_composition_root.dart';
import '../models/enums.dart';
import '../models/item.dart';
import '../models/schedule.dart';
import '../models/task.dart';

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
  List<Schedule>? _schedules;
  List<Item>? _items;
  bool _dependenciesInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dependenciesInitialized) {
      return;
    }
    _dependenciesInitialized = true;
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final root = AppCompositionScope.of(context);
    final schedules = await root.scheduleRepository.loadSchedules();
    final items = await root.itemReadRepository.loadItems();
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
            '提醒與到期事項',
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
                    schedule: schedule,
                    title: _titleForSchedule(schedule),
                    itemName: _itemNameForSchedule(schedule, items),
                    dueDate: _formatDate(schedule.nextDueDate),
                    status: _statusForSchedule(schedule),
                    onTitleSaved: _loadReminders,
                    onDateSaved: _loadReminders,
                    onReminderCanceled: _loadReminders,
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
        '目前沒有已建立的提醒',
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
              '提醒名稱',
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
                _ReminderTag(label: '所屬生活項目：$itemName'),
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
  required Schedule schedule,
  required String title,
  required String itemName,
  required String dueDate,
  required String status,
  required Future<void> Function() onTitleSaved,
  required Future<void> Function() onDateSaved,
  required Future<void> Function() onReminderCanceled,
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
                '提醒詳情',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF263746),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              _ReminderDetailRow(label: '提醒名稱', value: title),
              _ReminderDetailRow(label: '所屬生活項目', value: itemName),
              _ReminderDetailRow(label: '提醒日期', value: dueDate),
              _ReminderDetailRow(label: '狀態', value: status),
              if (schedule.status == ScheduleStatus.active) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showEditReminderTitleSheet(
                        sheetContext,
                        schedule: schedule,
                        currentTitle: title,
                        onTitleSaved: onTitleSaved,
                      );
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('編輯名稱'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _editReminderDate(
                        sheetContext,
                        schedule: schedule,
                        onDateSaved: onDateSaved,
                      );
                    },
                    icon: const Icon(Icons.event_outlined),
                    label: const Text('編輯提醒日期'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _cancelReminder(
                        sheetContext,
                        schedule: schedule,
                        onReminderCanceled: onReminderCanceled,
                      );
                    },
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('取消提醒'),
                  ),
                ),
              ] else if (schedule.cardId == 'manual-expiry-reminder' &&
                  schedule.status == ScheduleStatus.paused) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _reschedulePausedReminder(
                        sheetContext,
                        schedule: schedule,
                        onDateSaved: onDateSaved,
                      );
                    },
                    icon: const Icon(Icons.event_available_outlined),
                    label: const Text('重新安排並恢復'),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

void _showEditReminderTitleSheet(
  BuildContext context, {
  required Schedule schedule,
  required String currentTitle,
  required Future<void> Function() onTitleSaved,
}) {
  final titleController = TextEditingController(text: currentTitle);

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFF7F3EA),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) {
      Future<void> saveTitle() async {
        final title = titleController.text.trim();
        if (title.isEmpty) {
          ScaffoldMessenger.of(sheetContext).showSnackBar(
            const SnackBar(
              content: Text('請輸入事項名稱'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        final repository = AppCompositionScope.of(
          sheetContext,
        ).scheduleRepository;
        final schedules = await repository.loadSchedules();
        final updatedSchedules = [
          for (final existingSchedule in schedules)
            existingSchedule.id == schedule.id
                ? existingSchedule.copyWith(title: title)
                : existingSchedule,
        ];
        await repository.saveSchedules(updatedSchedules);
        await onTitleSaved();

        if (!sheetContext.mounted || !context.mounted) {
          return;
        }

        final messenger = ScaffoldMessenger.of(sheetContext);
        Navigator.of(sheetContext).pop();
        Navigator.of(context).pop();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('事項名稱已更新'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

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
                '編輯名稱',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF263746),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: '提醒名稱',
                  filled: true,
                  fillColor: const Color(0xFFFFFCF6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE4E0D8)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE4E0D8)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: saveTitle,
                      child: const Text('儲存'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  ).whenComplete(titleController.dispose);
}

Future<void> _reschedulePausedReminder(
  BuildContext context, {
  required Schedule schedule,
  required Future<void> Function() onDateSaved,
}) async {
  final root = AppCompositionScope.of(context);
  final today = _dateOnly(DateTime.now());
  final firstDate = today.add(const Duration(days: 1));
  final initialDate = _dateOnly(schedule.nextDueDate).isAfter(today)
      ? _dateOnly(schedule.nextDueDate)
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

  final taskRepository = root.taskRepository;
  final List<Task> tasks;
  try {
    tasks = await taskRepository.loadTasks();
  } catch (_) {
    if (!context.mounted) {
      return;
    }
    _showRescheduleFailedMessage(context);
    return;
  }
  final hasConflictingTask = tasks.any(
    (task) =>
        task.scheduleId == schedule.id &&
        _isSameDay(task.dueDate, selectedDate) &&
        task.status != TaskStatus.completed &&
        task.status != TaskStatus.canceled,
  );

  if (!context.mounted) {
    return;
  }

  if (hasConflictingTask) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('這個日期已有待處理提醒，請選擇其他日期'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  final repository = root.scheduleRepository;
  final List<Schedule> schedules;
  try {
    schedules = await repository.loadSchedules();
  } catch (_) {
    if (!context.mounted) {
      return;
    }
    _showRescheduleFailedMessage(context);
    return;
  }

  var didUpdateSchedule = false;
  final updatedSchedules = [
    for (final existingSchedule in schedules)
      if (!didUpdateSchedule &&
          existingSchedule.id == schedule.id &&
          existingSchedule.cardId == 'manual-expiry-reminder' &&
          existingSchedule.status == ScheduleStatus.paused)
        () {
          didUpdateSchedule = true;
          return existingSchedule.copyWith(
            status: ScheduleStatus.active,
            nextDueDate: selectedDate,
          );
        }()
      else
        existingSchedule,
  ];

  if (!didUpdateSchedule) {
    if (!context.mounted) {
      return;
    }
    _showRescheduleFailedMessage(context);
    return;
  }

  try {
    await repository.saveSchedules(updatedSchedules);
  } catch (_) {
    if (!context.mounted) {
      return;
    }
    _showRescheduleFailedMessage(context);
    return;
  }
  await onDateSaved();

  if (!context.mounted) {
    return;
  }

  final messenger = ScaffoldMessenger.of(context);
  Navigator.of(context).pop();
  messenger.showSnackBar(
    const SnackBar(
      content: Text('提醒已重新安排並恢復'),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

void _showRescheduleFailedMessage(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('重新安排失敗，請稍後再試'),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

Future<void> _cancelReminder(
  BuildContext context, {
  required Schedule schedule,
  required Future<void> Function() onReminderCanceled,
}) async {
  final root = AppCompositionScope.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('取消提醒'),
        content: const Text('確定要取消這筆提醒嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('返回'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('取消提醒'),
          ),
        ],
      );
    },
  );

  if (confirmed != true) {
    return;
  }

  final taskRepository = root.taskRepository;
  final tasks = await taskRepository.loadTasks();
  final hasPendingTask = tasks.any(
    (task) =>
        task.scheduleId == schedule.id &&
        task.status != TaskStatus.completed &&
        task.status != TaskStatus.canceled,
  );

  if (hasPendingTask) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已有待處理提醒，請先完成後再取消'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  final repository = root.scheduleRepository;
  final schedules = await repository.loadSchedules();
  final updatedSchedules = [
    for (final existingSchedule in schedules)
      existingSchedule.id == schedule.id
          ? existingSchedule.copyWith(enabled: false)
          : existingSchedule,
  ];
  await repository.saveSchedules(updatedSchedules);
  await onReminderCanceled();

  if (!context.mounted) {
    return;
  }

  final messenger = ScaffoldMessenger.of(context);
  Navigator.of(context).pop();
  messenger.showSnackBar(
    const SnackBar(content: Text('提醒已取消'), behavior: SnackBarBehavior.floating),
  );
}

Future<void> _editReminderDate(
  BuildContext context, {
  required Schedule schedule,
  required Future<void> Function() onDateSaved,
}) async {
  final root = AppCompositionScope.of(context);
  final taskRepository = root.taskRepository;
  final tasks = await taskRepository.loadTasks();
  final hasUnfinishedTask = tasks.any(
    (task) =>
        task.scheduleId == schedule.id &&
        task.status != TaskStatus.completed &&
        task.status != TaskStatus.canceled,
  );

  if (!context.mounted) {
    return;
  }

  if (hasUnfinishedTask) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已有待處理提醒，請先完成或取消後再修改日期'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  final selectedDate = await showDatePicker(
    context: context,
    initialDate: schedule.nextDueDate,
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
    helpText: '編輯提醒日期',
  );

  if (selectedDate == null) {
    return;
  }

  final repository = root.scheduleRepository;
  final schedules = await repository.loadSchedules();
  final updatedSchedules = [
    for (final existingSchedule in schedules)
      existingSchedule.id == schedule.id
          ? existingSchedule.copyWith(nextDueDate: selectedDate)
          : existingSchedule,
  ];
  await repository.saveSchedules(updatedSchedules);
  await onDateSaved();

  if (!context.mounted) {
    return;
  }

  final messenger = ScaffoldMessenger.of(context);
  Navigator.of(context).pop();
  messenger.showSnackBar(
    const SnackBar(
      content: Text('提醒日期已更新'),
      behavior: SnackBarBehavior.floating,
    ),
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
    return '提醒事項';
  }

  return title;
}

String _itemNameForSchedule(Schedule schedule, List<Item> items) {
  for (final item in items) {
    if (item.id == schedule.itemId) {
      return item.name;
    }
  }

  return '生活項目不存在';
}

String _statusForSchedule(Schedule schedule) {
  switch (schedule.status) {
    case ScheduleStatus.paused:
      return '已暫停';
    case ScheduleStatus.ended:
      return '已結束';
    case ScheduleStatus.active:
      break;
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

DateTime _dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

bool _isSameDay(DateTime firstDate, DateTime secondDate) {
  return _dateOnly(firstDate) == _dateOnly(secondDate);
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}/$month/$day';
}
