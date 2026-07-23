import 'package:flutter/material.dart';

import '../app/ui_tokens.dart';
import '../widgets/add_entry_card.dart';
import '../widgets/add_item_preview_sheet.dart';
import '../widgets/expiry_reminder_preview_sheet.dart';
import '../widgets/maintenance_record_preview_sheet.dart';
import '../widgets/reminder_list_sheet.dart';
import '../widgets/ui_v2_components.dart';
import 'formal_planning_screens.dart';

class AddScreen extends StatelessWidget {
  const AddScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final formalEditor = formalPlanningEditor(context);

    if (formalEditor != null) {
      return const _FormalAddScreen();
    }

    return ListView(
      padding: UiInsets.pageCompact,
      children: [
        const UiCompactPageHeader(
          icon: Icons.add_rounded,
          title: '你要新增什麼？',
          description: '新增生活項目、提醒或完成紀錄，方便之後查看與管理。',
        ),
        AddEntryCard(
          icon: Icons.add_a_photo_outlined,
          title: '新增生活項目',
          description: '建立家電、車輛、房屋、證件或其他生活項目。',
          onTap: () => showAddItemPreviewSheet(context),
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
          onTap: () => showMaintenanceRecordPreviewSheet(context),
        ),
      ],
    );
  }
}

class _FormalAddScreen extends StatelessWidget {
  const _FormalAddScreen();

  @override
  Widget build(BuildContext context) {
    void open(Widget screen) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => screen));
    }

    return ListView(
      padding: UiInsets.pageCompact,
      children: [
        const UiCompactPageHeader(
          icon: Icons.add_rounded,
          title: '新增與整理',
          description: '先建立生活項目，再加入需要長期管理的保養、提醒、階段重點與排程。',
        ),
        AddEntryCard(
          icon: Icons.inventory_2_outlined,
          title: '生活項目',
          description: '新增或修改家電、車輛、房屋、文件、健康與其他生活項目。',
          onTap: () => open(const ItemManagementScreen()),
        ),
        AddEntryCard(
          icon: Icons.category_outlined,
          title: '分類',
          description: '用自己熟悉的名稱整理生活項目，不必一開始就分得很細。',
          onTap: () => open(const CategoryManagementScreen()),
        ),
        AddEntryCard(
          icon: Icons.home_repair_service_outlined,
          title: '保養項目與步驟',
          description: '建立長期保養內容與標準步驟，不代表某一次已完成。',
          onTap: () => open(
            const PlanningContentScreen(
              kind: PlanningContentKind.maintenancePlan,
            ),
          ),
        ),
        AddEntryCard(
          icon: Icons.notifications_none_rounded,
          title: '一般提醒',
          description: '管理保固、合約、證件、繳費或健康檢查等提醒。',
          onTap: () => open(
            const PlanningContentScreen(kind: PlanningContentKind.reminder),
          ),
        ),
        AddEntryCard(
          icon: Icons.flag_outlined,
          title: '階段性重點',
          description: '安排大修、汰換評估或達到條件後才需要注意的事情。',
          onTap: () => open(
            const PlanningContentScreen(kind: PlanningContentKind.milestone),
          ),
        ),
        AddEntryCard(
          icon: Icons.event_repeat_outlined,
          title: '提醒排程',
          description: '替既有內容設定週期、日期與完成後重新計算方式。',
          onTap: () => open(
            const PlanningContentScreen(kind: PlanningContentKind.schedule),
          ),
        ),
      ],
    );
  }
}
