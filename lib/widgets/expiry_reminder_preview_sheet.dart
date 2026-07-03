import 'package:flutter/material.dart';

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

class _ExpiryReminderPreviewForm extends StatelessWidget {
  const _ExpiryReminderPreviewForm();

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
            '到期提醒預覽',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF263746),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '先試填到期資訊，這一步不會儲存。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF687887),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          const PreviewItemDropdown(),
          const SizedBox(height: 12),
          const PreviewTextField(label: '提醒名稱'),
          const SizedBox(height: 12),
          const PreviewTextField(label: '到期日期'),
          const SizedBox(height: 12),
          const PreviewAdvanceReminderDropdown(),
          const SizedBox(height: 12),
          const PreviewTextField(label: '備註', maxLines: 3),
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
