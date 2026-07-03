import 'package:flutter/material.dart';

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

class _AddItemPreviewForm extends StatelessWidget {
  const _AddItemPreviewForm();

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
          const PreviewTextField(label: '物品名稱'),
          const SizedBox(height: 12),
          const PreviewCategoryDropdown(),
          const SizedBox(height: 12),
          const PreviewTextField(label: '放置位置'),
          const SizedBox(height: 12),
          const PreviewTextField(label: '備註', maxLines: 3),
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
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('這是預覽流程，尚未儲存資料'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
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
