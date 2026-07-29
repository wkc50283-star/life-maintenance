import 'package:flutter/material.dart';

import '../app/app_composition_root.dart';
import '../app/ui_tokens.dart';
import '../models/enums.dart';
import '../models/item.dart';
import '../models/maintenance_record.dart';
import '../repositories/repository_constraint_exception.dart';
import '../widgets/ui_v2_components.dart';

class ManualMaintenanceRecordResult {
  const ManualMaintenanceRecordResult({
    required this.recordId,
    required this.itemId,
  });

  final String recordId;
  final String itemId;
}

class ManualMaintenanceRecordFormScreen extends StatefulWidget {
  const ManualMaintenanceRecordFormScreen({super.key});

  @override
  State<ManualMaintenanceRecordFormScreen> createState() =>
      _ManualMaintenanceRecordFormScreenState();
}

class _ManualMaintenanceRecordFormScreenState
    extends State<ManualMaintenanceRecordFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _note = TextEditingController();
  List<Item>? _items;
  Object? _loadError;
  String? _itemId;
  DateTime _completedDate = _dateOnly(DateTime.now());
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_items == null && _loadError == null) _loadItems();
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    try {
      final items = await AppCompositionScope.of(
        context,
      ).itemReadRepository.loadItems();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loadError = null;
      });
    } catch (error) {
      if (mounted) setState(() => _loadError = error);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('補登完成紀錄')),
    body: switch ((_items, _loadError)) {
      (null, null) => const Center(child: CircularProgressIndicator()),
      (null, _) => _RecordLoadFailure(onRetry: _retry),
      (final items?, _) when items.isEmpty => const Padding(
        padding: UiInsets.page,
        child: UiEmptyState(
          icon: Icons.inventory_2_outlined,
          title: '目前還沒有生活項目',
          description: '請先建立生活項目，才能補登完成紀錄。',
        ),
      ),
      (final items?, _) => Form(
        key: _formKey,
        child: ListView(
          padding: UiInsets.page,
          children: [
            Text('留下已完成的事實', style: UiType.sectionTitle),
            const SizedBox(height: UiSpace.xxs),
            Text('選擇生活項目，記下實際完成的內容與日期。', style: UiType.body),
            const SizedBox(height: UiSpace.lg),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(UiSpace.md),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      key: const ValueKey('maintenance-record-item'),
                      initialValue: _itemId,
                      decoration: const InputDecoration(labelText: '所屬生活項目'),
                      hint: const Text('請選擇生活項目'),
                      items: [
                        for (final item in items)
                          DropdownMenuItem(
                            value: item.id,
                            child: Text(
                              item.status == ItemStatus.archived
                                  ? '${item.name}（已封存）'
                                  : item.name,
                            ),
                          ),
                      ],
                      validator: (value) => value == null ? '請選擇生活項目' : null,
                      onChanged: _saving
                          ? null
                          : (value) => setState(() => _itemId = value),
                    ),
                    const SizedBox(height: UiSpace.md),
                    TextFormField(
                      key: const ValueKey('maintenance-record-title'),
                      controller: _title,
                      enabled: !_saving,
                      decoration: const InputDecoration(labelText: '完成內容'),
                      validator: (value) =>
                          _text(value) == null ? '請填寫完成內容' : null,
                    ),
                    const SizedBox(height: UiSpace.md),
                    InkWell(
                      key: const ValueKey('maintenance-record-date'),
                      onTap: _saving ? null : _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: '實際完成日期',
                          suffixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(_formatDate(_completedDate)),
                      ),
                    ),
                    const SizedBox(height: UiSpace.md),
                    TextFormField(
                      key: const ValueKey('maintenance-record-note'),
                      controller: _note,
                      enabled: !_saving,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: '備註（選填）',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: UiSpace.lg),
            UiPrimaryButton(
              key: const ValueKey('maintenance-record-save'),
              label: _saving ? '建立中…' : '建立紀錄',
              icon: Icons.fact_check_outlined,
              loading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    },
  );

  void _retry() {
    setState(() => _loadError = null);
    _loadItems();
  }

  Future<void> _pickDate() async {
    final today = _dateOnly(DateTime.now());
    final selected = await showDatePicker(
      context: context,
      initialDate: _completedDate.isAfter(today) ? today : _completedDate,
      firstDate: DateTime(1900),
      lastDate: today,
      helpText: '選擇實際完成日期',
    );
    if (selected != null && mounted) {
      setState(() => _completedDate = _dateOnly(selected));
    }
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final itemId = _itemId;
    if (itemId == null) return;
    final today = _dateOnly(DateTime.now());
    final completedDate = _dateOnly(_completedDate);
    if (completedDate.isAfter(today)) {
      _showError(context, '實際完成日期不能晚於今天。');
      return;
    }

    setState(() => _saving = true);
    final now = DateTime.now();
    final recordId = 'record-${now.microsecondsSinceEpoch}';
    final record = MaintenanceRecord(
      id: recordId,
      itemId: itemId,
      recordType: RecordType.other,
      date: completedDate,
      title: _title.text.trim(),
      note: _text(_note.text),
      createdAt: now,
    );
    try {
      await AppCompositionScope.of(
        context,
      ).maintenanceRecordRepository.createSimpleRecord(record);
      if (mounted) {
        Navigator.pop(
          context,
          ManualMaintenanceRecordResult(recordId: recordId, itemId: itemId),
        );
      }
    } catch (error) {
      if (mounted) {
        _showError(
          context,
          error is RepositoryConstraintException
              ? error.message
              : '目前無法建立紀錄，請稍後再試。',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _RecordLoadFailure extends StatelessWidget {
  const _RecordLoadFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: UiInsets.page,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('目前無法讀取生活項目', style: UiType.sectionTitle),
          const SizedBox(height: UiSpace.sm),
          Text('請稍後再試一次。', style: UiType.body),
          const SizedBox(height: UiSpace.md),
          FilledButton(onPressed: onRetry, child: const Text('重新載入')),
        ],
      ),
    ),
  );
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String _formatDate(DateTime value) =>
    '${value.year}/${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')}';

String? _text(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
