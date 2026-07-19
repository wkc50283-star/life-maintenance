import 'package:flutter/material.dart';

import '../models/item.dart';
import '../repositories/item_read_repository.dart';

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

class PreviewItemDropdown extends StatefulWidget {
  const PreviewItemDropdown({
    super.key,
    required this.repository,
    this.value,
    this.onChanged,
  });

  final ItemReadRepository repository;
  final String? value;
  final ValueChanged<String?>? onChanged;

  @override
  State<PreviewItemDropdown> createState() => _PreviewItemDropdownState();
}

class _PreviewItemDropdownState extends State<PreviewItemDropdown> {
  List<Item>? _localItems;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await widget.repository.loadItems();
    if (!mounted) {
      return;
    }

    setState(() {
      _localItems = items;
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = _localItems ?? const <Item>[];
    final isDisabled = items.isEmpty;
    final selectedValue = items.any((item) => item.id == widget.value)
        ? widget.value
        : null;

    return DropdownButtonFormField<String>(
      initialValue: selectedValue,
      decoration: _previewInputDecoration('選擇生活項目'),
      hint: Text(isDisabled ? '請先新增生活項目' : '請選擇生活項目'),
      dropdownColor: const Color(0xFFFFFCF6),
      borderRadius: BorderRadius.circular(16),
      iconEnabledColor: const Color(0xFF5D7893),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item.id,
              child: Text(item.name),
            ),
          )
          .toList(),
      onChanged: isDisabled ? null : widget.onChanged ?? (_) {},
    );
  }
}

class PreviewRecordTypeDropdown extends StatelessWidget {
  const PreviewRecordTypeDropdown({super.key, this.value, this.onChanged});

  static const List<String> _recordTypes = ['保養', '維修', '更換', '到期提醒'];

  final String? value;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
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
      onChanged: onChanged ?? (_) {},
    );
  }
}

class PreviewCategoryDropdown extends StatelessWidget {
  const PreviewCategoryDropdown({super.key, this.value, this.onChanged});

  static const List<String> _categories = ['家電', '車輛', '房屋', '保固證件', '其他'];

  final String? value;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
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
      onChanged: onChanged ?? (_) {},
    );
  }
}

class PreviewTextField extends StatelessWidget {
  final String label;
  final int maxLines;
  final TextEditingController? controller;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;

  const PreviewTextField({
    super.key,
    required this.label,
    this.maxLines = 1,
    this.controller,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      decoration: _previewInputDecoration(
        label,
      ).copyWith(suffixIcon: suffixIcon),
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
