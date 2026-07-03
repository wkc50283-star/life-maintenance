import 'package:flutter/material.dart';

import '../widgets/add_entry_card.dart';
import '../widgets/add_item_preview_sheet.dart';
import '../widgets/expiry_reminder_preview_sheet.dart';
import '../widgets/maintenance_record_preview_sheet.dart';

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
          onTap: () => showMaintenanceRecordPreviewSheet(context),
        ),
        AddEntryCard(
          icon: Icons.event_available_outlined,
          title: '新增到期提醒',
          description: '保固、證件、保險、合約到期前提醒。',
          onTap: () => showExpiryReminderPreviewSheet(context),
        ),
      ],
    );
  }
}
