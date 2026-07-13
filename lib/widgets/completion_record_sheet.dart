import 'package:flutter/material.dart';

enum CompletionScheduleAction { continueCycle, pauseSchedule, endSchedule }

enum CompletionManualReminderAction { endReminder, pauseReminder, reschedule }

enum CompletionFollowUpMode { none, maintenanceSchedule, manualReminder }

class CompletionRecordSheetData {
  final String? workDescription;
  final int? cost;
  final String? vendorName;
  final List<String> partsChanged;
  final String? note;
  final String? result;
  final CompletionScheduleAction scheduleAction;
  final CompletionManualReminderAction manualReminderAction;
  final DateTime? rescheduledDate;

  const CompletionRecordSheetData({
    required this.workDescription,
    required this.cost,
    required this.vendorName,
    required this.partsChanged,
    required this.note,
    required this.result,
    required this.scheduleAction,
    required this.manualReminderAction,
    required this.rescheduledDate,
  });
}

Future<CompletionRecordSheetData?> showCompletionRecordSheet(
  BuildContext context, {
  CompletionFollowUpMode followUpMode = CompletionFollowUpMode.none,
}) async {
  final workDescriptionController = TextEditingController();
  final costController = TextEditingController();
  final vendorNameController = TextEditingController();
  final partsChangedController = TextEditingController();
  final noteController = TextEditingController();
  final resultController = TextEditingController(text: '已完成');
  var scheduleAction = CompletionScheduleAction.continueCycle;
  var manualReminderAction = CompletionManualReminderAction.endReminder;
  DateTime? rescheduledDate;

  final shouldComplete = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFF7F3EA),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (sheetContext, setSheetState) {
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
                    '補充完成紀錄',
                    style: Theme.of(sheetContext).textTheme.titleLarge
                        ?.copyWith(
                          color: const Color(0xFF263746),
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '完成後會建立一筆紀錄，並保存本次補充欄位。',
                    style: Theme.of(sheetContext).textTheme.bodyMedium
                        ?.copyWith(
                          color: const Color(0xFF687887),
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: workDescriptionController,
                    maxLines: 3,
                    decoration: _completionRecordInputDecoration('處理內容'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: costController,
                    keyboardType: TextInputType.number,
                    decoration: _completionRecordInputDecoration('費用'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: vendorNameController,
                    decoration: _completionRecordInputDecoration('店家'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: partsChangedController,
                    decoration: _completionRecordInputDecoration('更換零件'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    decoration: _completionRecordInputDecoration('備註'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: resultController,
                    decoration: _completionRecordInputDecoration('結果'),
                  ),
                  if (followUpMode ==
                      CompletionFollowUpMode.maintenanceSchedule) ...[
                    const SizedBox(height: 18),
                    Text(
                      '後續安排',
                      style: Theme.of(sheetContext).textTheme.titleMedium
                          ?.copyWith(
                            color: const Color(0xFF263746),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    _ScheduleActionOption(
                      title: '繼續原週期',
                      value: CompletionScheduleAction.continueCycle,
                      groupValue: scheduleAction,
                      onChanged: (value) {
                        setSheetState(() {
                          scheduleAction = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    _ScheduleActionOption(
                      title: '保留但不排程',
                      value: CompletionScheduleAction.pauseSchedule,
                      groupValue: scheduleAction,
                      onChanged: (value) {
                        setSheetState(() {
                          scheduleAction = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    _ScheduleActionOption(
                      title: '結束排程',
                      value: CompletionScheduleAction.endSchedule,
                      groupValue: scheduleAction,
                      onChanged: (value) {
                        setSheetState(() {
                          scheduleAction = value;
                        });
                      },
                    ),
                  ],
                  if (followUpMode ==
                      CompletionFollowUpMode.manualReminder) ...[
                    const SizedBox(height: 18),
                    Text(
                      '後續安排',
                      style: Theme.of(sheetContext).textTheme.titleMedium
                          ?.copyWith(
                            color: const Color(0xFF263746),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    _ManualReminderActionOption(
                      title: '結束提醒',
                      value: CompletionManualReminderAction.endReminder,
                      groupValue: manualReminderAction,
                      onChanged: (value) {
                        setSheetState(() {
                          manualReminderAction = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    _ManualReminderActionOption(
                      title: '保留但不排程',
                      value: CompletionManualReminderAction.pauseReminder,
                      groupValue: manualReminderAction,
                      onChanged: (value) {
                        setSheetState(() {
                          manualReminderAction = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    _ManualReminderActionOption(
                      title: '重新安排日期',
                      value: CompletionManualReminderAction.reschedule,
                      groupValue: manualReminderAction,
                      onChanged: (value) {
                        setSheetState(() {
                          manualReminderAction = value;
                        });
                      },
                    ),
                    if (manualReminderAction ==
                        CompletionManualReminderAction.reschedule) ...[
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () async {
                          final today = DateTime.now();
                          final firstDate = DateTime(
                            today.year,
                            today.month,
                            today.day + 1,
                          );
                          final selectedDate = await showDatePicker(
                            context: sheetContext,
                            initialDate: rescheduledDate ?? firstDate,
                            firstDate: firstDate,
                            lastDate: DateTime(2100),
                            helpText: '重新安排日期',
                          );

                          if (selectedDate == null) {
                            return;
                          }

                          setSheetState(() {
                            rescheduledDate = selectedDate;
                          });
                        },
                        child: Text(
                          rescheduledDate == null
                              ? '選擇新的提醒日期'
                              : _formatDate(rescheduledDate!),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(sheetContext).pop(false);
                          },
                          child: const Text('取消'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            if (followUpMode ==
                                    CompletionFollowUpMode.manualReminder &&
                                manualReminderAction ==
                                    CompletionManualReminderAction.reschedule &&
                                rescheduledDate == null) {
                              ScaffoldMessenger.of(sheetContext).showSnackBar(
                                const SnackBar(
                                  content: Text('請選擇新的提醒日期'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }

                            Navigator.of(sheetContext).pop(true);
                          },
                          child: const Text('完成'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  final data = shouldComplete == true
      ? CompletionRecordSheetData(
          workDescription: _nullableTrimmedText(
            workDescriptionController.text,
          ),
          cost: _parseOptionalCost(costController.text),
          vendorName: _nullableTrimmedText(vendorNameController.text),
          partsChanged: _partsChangedFrom(partsChangedController.text),
          note: _nullableTrimmedText(noteController.text),
          result: _nullableTrimmedText(resultController.text),
          scheduleAction: scheduleAction,
          manualReminderAction: manualReminderAction,
          rescheduledDate: rescheduledDate,
        )
      : null;

  workDescriptionController.dispose();
  costController.dispose();
  vendorNameController.dispose();
  partsChangedController.dispose();
  noteController.dispose();
  resultController.dispose();

  return data;
}

class _ScheduleActionOption extends StatelessWidget {
  final String title;
  final CompletionScheduleAction value;
  final CompletionScheduleAction groupValue;
  final ValueChanged<CompletionScheduleAction> onChanged;

  const _ScheduleActionOption({
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        onChanged(value);
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFCF6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE4E0D8)),
        ),
        child: Row(
          children: [
            _ScheduleActionIndicator(selected: value == groupValue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF263746),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualReminderActionOption extends StatelessWidget {
  final String title;
  final CompletionManualReminderAction value;
  final CompletionManualReminderAction groupValue;
  final ValueChanged<CompletionManualReminderAction> onChanged;

  const _ManualReminderActionOption({
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        onChanged(value);
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFCF6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE4E0D8)),
        ),
        child: Row(
          children: [
            _ScheduleActionIndicator(selected: value == groupValue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF263746),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleActionIndicator extends StatelessWidget {
  final bool selected;

  const _ScheduleActionIndicator({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? const Color(0xFF5D7893) : const Color(0xFFB8CBDC),
          width: 2,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF5D7893),
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}/$month/$day';
}

String? _nullableTrimmedText(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

int? _parseOptionalCost(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  return int.tryParse(trimmed);
}

List<String> _partsChangedFrom(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return const [];
  }

  return trimmed
      .split(RegExp(r'[,，、\n]'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
}

InputDecoration _completionRecordInputDecoration(String label) {
  return InputDecoration(
    labelText: label,
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
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF5D7893)),
    ),
  );
}
