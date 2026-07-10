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
          '先建立一個名稱、提醒或紀錄，讓需要承接的事不再散落在腦中。',
          style: TextStyle(color: Color(0xFF687887), fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 20),
        AddEntryCard(
          icon: Icons.add_a_photo_outlined,
          title: '先放著',
          description: '建立一個可追蹤的名稱，先把責任收進來。',
          onTap: () => showAddItemPreviewSheet(context),
        ),
        AddEntryCard(
          icon: Icons.event_available_outlined,
          title: '需要你記住的事',
          description: '到期日、保固、證件、合約或其他提醒。',
          onTap: () => showExpiryReminderPreviewSheet(context),
        ),
        AddEntryCard(
          icon: Icons.construction_outlined,
          title: '完成紀錄',
          description: '記下處理過什麼、花多少錢、結果如何。',
          onTap: () => showMaintenanceRecordPreviewSheet(context),
        ),
      ],
    );
  }
}
