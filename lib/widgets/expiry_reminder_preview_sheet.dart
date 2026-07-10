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
  final TextEditingController _noteController = TextEditingController();
  String? _itemId;

  @override
  void dispose() {
    _titleController.dispose();
    _dueDateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveSchedule(BuildContext context) async {
    final itemId = _itemId;
    if (itemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('請選擇項目'),
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
    );

    await repository.saveSchedules([...schedules, schedule]);

    if (!context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('需要你記住的事已儲存'),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
            '需要你記住的事',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF263746),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '記下到期日、保固、證件、合約等需要留意的時間，完成後會儲存到本機。',
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
          PreviewTextField(label: '事項名稱', controller: _titleController),
          const SizedBox(height: 12),
          PreviewTextField(label: '提醒日期', controller: _dueDateController),
          const SizedBox(height: 12),
          const PreviewAdvanceReminderDropdown(),
          const SizedBox(height: 12),
          PreviewTextField(
            label: '備註',
            controller: _noteController,
            maxLines: 3,
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
