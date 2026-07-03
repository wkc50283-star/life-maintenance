import 'package:flutter/material.dart';

import '../data/mock_data.dart';

class PreviewAdvanceReminderDropdown extends StatelessWidget {
  const PreviewAdvanceReminderDropdown({super.key});

  static const List<String> _advanceOptions = [
    '當天',
    '提前 3 天',
    '提前 7 天',
    '提前 30 天',
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: _previewInputDecoration('提前提醒'),
      hint: const Text('請選擇提前提醒'),
      dropdownColor: const Color(0xFFFFFCF6),
      borderRadius: BorderRadius.circular(16),
      iconEnabledColor: const Color(0xFF5D7893),
      items: _advanceOptions
          .map(
            (advanceOption) => DropdownMenuItem<String>(
              value: advanceOption,
              child: Text(advanceOption),
            ),
          )
          .toList(),
      onChanged: (_) {},
    );
  }
}

class PreviewItemDropdown extends StatelessWidget {
  const PreviewItemDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: _previewInputDecoration('選擇物品'),
      hint: const Text('請選擇物品'),
      dropdownColor: const Color(0xFFFFFCF6),
      borderRadius: BorderRadius.circular(16),
      iconEnabledColor: const Color(0xFF5D7893),
      items: MockData.items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item.id,
              child: Text(item.name),
            ),
          )
          .toList(),
      onChanged: (_) {},
    );
  }
}

class PreviewRecordTypeDropdown extends StatelessWidget {
  const PreviewRecordTypeDropdown({super.key});

  static const List<String> _recordTypes = ['保養', '維修', '更換', '到期提醒'];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: _previewInputDecoration('紀錄類型'),
      hint: const Text('請選擇紀錄類型'),
      dropdownColor: const Color(0xFFFFFCF6),
      borderRadius: BorderRadius.circular(16),
      iconEnabledColor: const Color(0xFF5D7893),
      items: _recordTypes
          .map(
            (recordType) => DropdownMenuItem<String>(
              value: recordType,
              child: Text(recordType),
            ),
          )
          .toList(),
      onChanged: (_) {},
    );
  }
}

class PreviewCategoryDropdown extends StatelessWidget {
  const PreviewCategoryDropdown({super.key});

  static const List<String> _categories = ['家電', '車輛', '房屋', '保固證件', '其他'];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: _previewInputDecoration('分類'),
      hint: const Text('請選擇分類'),
      dropdownColor: const Color(0xFFFFFCF6),
      borderRadius: BorderRadius.circular(16),
      iconEnabledColor: const Color(0xFF5D7893),
      items: _categories
          .map(
            (category) => DropdownMenuItem<String>(
              value: category,
              child: Text(category),
            ),
          )
          .toList(),
      onChanged: (_) {},
    );
  }
}

class PreviewTextField extends StatelessWidget {
  final String label;
  final int maxLines;

  const PreviewTextField({super.key, required this.label, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return TextField(
      maxLines: maxLines,
      decoration: _previewInputDecoration(label),
    );
  }
}

InputDecoration _previewInputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: const Color(0xFFFFFCF6),
    labelStyle: const TextStyle(color: Color(0xFF687887)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE4E0D8)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF8FA4B8), width: 1.4),
    ),
  );
}
