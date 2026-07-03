import 'package:flutter/material.dart';

import '../widgets/add_entry_card.dart';
import '../widgets/add_item_preview_sheet.dart';
import '../widgets/preview_form_fields.dart';

class AddScreen extends StatelessWidget {
  const AddScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const SizedBox(height: 8),
        const Text(
          '你想記住什麼？',
          style: TextStyle(
            color: Color(0xFF263746),
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '先把生活裡需要維護的事建立入口，下一版再接上實際新增流程。',
          style: TextStyle(color: Color(0xFF687887), fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 20),
        AddEntryCard(
          icon: Icons.add_a_photo_outlined,
          title: '新增物品',
          description: '拍照建立物品，設定保養提醒。',
          onTap: () => showAddItemPreviewSheet(context),
        ),
        AddEntryCard(
          icon: Icons.construction_outlined,
          title: '新增保養/維修紀錄',
          description: '記下修過什麼、換過什麼、花多少錢。',
          onTap: () => _showMaintenanceRecordPreviewSheet(context),
        ),
        AddEntryCard(
          icon: Icons.event_available_outlined,
          title: '新增到期提醒',
          description: '保固、證件、保險、合約到期前提醒。',
          onTap: () => _showExpiryReminderPreviewSheet(context),
        ),
      ],
    );
  }
}

void _showMaintenanceRecordPreviewSheet(BuildContext context) {
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

void _showExpiryReminderPreviewSheet(BuildContext context) {
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

class _MaintenanceRecordPreviewForm extends StatelessWidget {
  const _MaintenanceRecordPreviewForm();

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
            '先記下處理內容與費用，這一步不會儲存。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF687887),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          const PreviewItemDropdown(),
          const SizedBox(height: 12),
          const PreviewRecordTypeDropdown(),
          const SizedBox(height: 12),
          const PreviewTextField(label: '處理內容', maxLines: 3),
          const SizedBox(height: 12),
          const PreviewTextField(label: '費用'),
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
