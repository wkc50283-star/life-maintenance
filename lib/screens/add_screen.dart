import 'package:flutter/material.dart';

import '../app/app_composition_root.dart';
import '../widgets/add_entry_card.dart';
import '../widgets/add_item_preview_sheet.dart';
import '../widgets/expiry_reminder_preview_sheet.dart';
import '../widgets/maintenance_record_preview_sheet.dart';
import '../widgets/reminder_list_sheet.dart';

class AddScreen extends StatelessWidget {
  const AddScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final planningEnabled = AppCompositionScope.of(context).usesDriftPlanning;
    void unavailable() {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('此項寫入尚未切換至 Drift，目前保持唯讀')));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const SizedBox(height: 8),
        const Text(
          '你要新增什麼？',
          style: TextStyle(
            color: Color(0xFF263746),
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '新增生活項目、提醒或完成紀錄，方便之後查看與管理。',
          style: TextStyle(color: Color(0xFF687887), fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 20),
        AddEntryCard(
          icon: Icons.add_a_photo_outlined,
          title: '新增生活項目',
          description: '建立家電、車輛、房屋、證件或其他生活項目。',
          onTap: planningEnabled
              ? unavailable
              : () => showAddItemPreviewSheet(context),
        ),
        AddEntryCard(
          icon: Icons.event_available_outlined,
          title: '新增提醒',
          description: '設定到期日、保固、證件、合約或其他日期提醒。',
          onTap: () => showExpiryReminderPreviewSheet(context),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => showReminderListSheet(context),
            icon: const Icon(Icons.event_note_outlined),
            label: const Text('查看已建立的提醒'),
          ),
        ),
        const SizedBox(height: 8),
        AddEntryCard(
          icon: Icons.construction_outlined,
          title: '補登完成紀錄',
          description: '記錄已完成的保養、修理、辦理事項、費用與結果。',
          onTap: planningEnabled
              ? unavailable
              : () => showMaintenanceRecordPreviewSheet(context),
        ),
      ],
    );
  }
}
