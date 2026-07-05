import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/item.dart';
import '../repositories/item_local_repository.dart';
import '../services/local_storage_service.dart';
import 'preview_form_fields.dart';

void showAddItemPreviewSheet(BuildContext context) {
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
        child: const _AddItemPreviewForm(),
      );
    },
  );
}

class _AddItemPreviewForm extends StatefulWidget {
  const _AddItemPreviewForm();

  @override
  State<_AddItemPreviewForm> createState() => _AddItemPreviewFormState();
}

class _AddItemPreviewFormState extends State<_AddItemPreviewForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String? _category;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveItem(BuildContext context) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('請輸入物品名稱'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final now = DateTime.now();
    final repository = ItemLocalRepository(LocalStorageService());
    final items = await repository.loadItems();
    final item = Item(
      id: now.millisecondsSinceEpoch.toString(),
      name: name,
      category: _categoryForLabel(_category),
      createdAt: now,
      location: _locationController.text,
      note: _noteController.text,
    );

    await repository.saveItems([...items, item]);

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('物品已儲存'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  ItemCategory _categoryForLabel(String? label) {
    return switch (label) {
      '家電' => ItemCategory.appliance,
      '車輛' => ItemCategory.vehicle,
      '房屋' => ItemCategory.house,
      '保固證件' => ItemCategory.warrantyDocument,
      _ => ItemCategory.other,
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
            '新增物品預覽',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF263746),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '先試填基本資料，這一步不會儲存。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF687887),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          PreviewTextField(label: '物品名稱', controller: _nameController),
          const SizedBox(height: 12),
          PreviewCategoryDropdown(
            value: _category,
            onChanged: (category) {
              setState(() {
                _category = category;
              });
            },
          ),
          const SizedBox(height: 12),
          PreviewTextField(label: '放置位置', controller: _locationController),
          const SizedBox(height: 12),
          PreviewTextField(
            label: '備註',
            controller: _noteController,
            maxLines: 3,
          ),
          const SizedBox(height: 14),
          const _SafetyNoteCard(),
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
                  onPressed: () => _saveItem(context),
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

class _SafetyNoteCard extends StatelessWidget {
  const _SafetyNoteCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6E2EC)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F3EA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.shield_outlined,
              size: 18,
              color: Color(0xFF5D7893),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '涉及電力、瓦斯、煞車、冷媒、結構等高風險項目，App 不提供自行維修步驟，請尋求合格專業人員協助。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF506272),
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
