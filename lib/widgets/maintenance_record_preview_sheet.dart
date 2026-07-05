import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/enums.dart';
import '../models/maintenance_record.dart';
import '../repositories/maintenance_record_local_repository.dart';
import '../services/local_storage_service.dart';
import 'preview_form_fields.dart';

void showMaintenanceRecordPreviewSheet(BuildContext context) {
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
        child: const _MaintenanceRecordPreviewForm(),
      );
    },
  );
}

class _MaintenanceRecordPreviewForm extends StatefulWidget {
  const _MaintenanceRecordPreviewForm();

  @override
  State<_MaintenanceRecordPreviewForm> createState() =>
      _MaintenanceRecordPreviewFormState();
}

class _MaintenanceRecordPreviewFormState
    extends State<_MaintenanceRecordPreviewForm> {
  final TextEditingController _workDescriptionController =
      TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String? _itemId;
  String? _recordType;

  @override
  void dispose() {
    _workDescriptionController.dispose();
    _costController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveRecord(BuildContext context) async {
    final now = DateTime.now();
    final repository = MaintenanceRecordLocalRepository(LocalStorageService());
    final records = await repository.loadRecords();
    final record = MaintenanceRecord(
      id: now.millisecondsSinceEpoch.toString(),
      itemId: _itemId ?? MockData.items.first.id,
      recordType: _recordTypeForLabel(_recordType),
      date: now,
      title: _recordType ?? '保養/維修紀錄',
      workDescription: _workDescriptionController.text,
      cost: int.tryParse(_costController.text.trim()),
      note: _noteController.text,
      createdAt: now,
    );

    await repository.saveRecords([...records, record]);

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('保養維修紀錄已儲存'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  RecordType _recordTypeForLabel(String? label) {
    return switch (label) {
      '保養' => RecordType.regularMaintenance,
      '維修' => RecordType.repair,
      '更換' => RecordType.partsReplacement,
      '到期提醒' => RecordType.expiryHandled,
      _ => RecordType.other,
    };
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
            '保養/維修紀錄預覽',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF263746),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '記下處理內容與費用後，按下預覽完成會儲存到本機。',
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
          PreviewRecordTypeDropdown(
            value: _recordType,
            onChanged: (recordType) {
              setState(() {
                _recordType = recordType;
              });
            },
          ),
          const SizedBox(height: 12),
          PreviewTextField(
            label: '處理內容',
            controller: _workDescriptionController,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          PreviewTextField(label: '費用', controller: _costController),
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
                  onPressed: () => _saveRecord(context),
                  child: const Text('預覽完成'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
