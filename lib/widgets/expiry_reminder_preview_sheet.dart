import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/schedule.dart';
import '../repositories/schedule_local_repository.dart';
import '../services/local_storage_service.dart';
import 'preview_form_fields.dart';

void showExpiryReminderPreviewSheet(BuildContext context) {
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
        child: const _ExpiryReminderPreviewForm(),
      );
    },
  );
}

class _ExpiryReminderPreviewForm extends StatefulWidget {
  const _ExpiryReminderPreviewForm();

  @override
  State<_ExpiryReminderPreviewForm> createState() =>
      _ExpiryReminderPreviewFormState();
}

class _ExpiryReminderPreviewFormState
    extends State<_ExpiryReminderPreviewForm> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  String? _itemId;

  static String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  Future<void> _saveSchedule(BuildContext context) async {
    final itemId = _itemId;
    if (itemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('請選擇生活項目'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final dueDate = DateTime.tryParse(_dueDateController.text.trim());
    if (dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('請輸入正確日期'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final now = DateTime.now();
    final title = _titleController.text.trim();
    final repository = ScheduleLocalRepository(LocalStorageService());
    final schedules = await repository.loadSchedules();
    final schedule = Schedule(
      id: now.millisecondsSinceEpoch.toString(),
      itemId: itemId,
      cardId: 'manual-expiry-reminder',
      cycleType: CycleType.custom,
      interval: 1,
      startDate: now,
      nextDueDate: dueDate,
      title: title.isEmpty ? null : title,
    );

    await repository.saveSchedules([...schedules, schedule]);

    if (!context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('提醒已儲存'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickDueDate(BuildContext context) async {
    final today = DateTime.now();
    final initialDate =
        DateTime.tryParse(_dueDateController.text.trim()) ??
        DateTime(today.year, today.month, today.day);
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
      helpText: '選擇提醒日期',
    );

    if (selectedDate == null) {
      return;
    }

    _dueDateController.text = _formatDate(selectedDate);
  }

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
            '新增提醒',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF263746),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '設定到期日、保固、證件、合約或其他需要留意的日期。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF687887),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          PreviewItemDropdown(
            value: _itemId,
            onChanged: (itemId) {
              setState(() {
                _itemId = itemId;
              });
            },
          ),
          const SizedBox(height: 12),
          PreviewTextField(label: '提醒名稱', controller: _titleController),
          const SizedBox(height: 12),
          PreviewTextField(
            label: '提醒日期',
            controller: _dueDateController,
            readOnly: true,
            onTap: () => _pickDueDate(context),
            suffixIcon: const Icon(Icons.calendar_today_outlined),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF5D7893),
                    side: const BorderSide(color: Color(0xFFB8CBDC)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => _saveSchedule(context),
                  child: const Text('儲存'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
