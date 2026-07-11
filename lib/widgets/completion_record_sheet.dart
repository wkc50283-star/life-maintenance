import 'package:flutter/material.dart';

class CompletionRecordSheetData {
  final String? workDescription;
  final int? cost;
  final String? vendorName;
  final List<String> partsChanged;
  final String? note;
  final String? result;

  const CompletionRecordSheetData({
    required this.workDescription,
    required this.cost,
    required this.vendorName,
    required this.partsChanged,
    required this.note,
    required this.result,
  });
}

Future<CompletionRecordSheetData?> showCompletionRecordSheet(
  BuildContext context,
) async {
  final workDescriptionController = TextEditingController();
  final costController = TextEditingController();
  final vendorNameController = TextEditingController();
  final partsChangedController = TextEditingController();
  final noteController = TextEditingController();
  final resultController = TextEditingController(text: '已完成');

  final shouldComplete = await showModalBottomSheet<bool>(
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
                '補充完成紀錄',
                style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF263746),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '完成後會建立一筆紀錄，並保存本次補充欄位。',
                style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
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

  final data = shouldComplete == true
      ? CompletionRecordSheetData(
          workDescription: _nullableTrimmedText(workDescriptionController.text),
          cost: _parseOptionalCost(costController.text),
          vendorName: _nullableTrimmedText(vendorNameController.text),
          partsChanged: _partsChangedFrom(partsChangedController.text),
          note: _nullableTrimmedText(noteController.text),
          result: _nullableTrimmedText(resultController.text),
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
