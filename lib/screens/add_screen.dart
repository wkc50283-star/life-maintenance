import 'package:flutter/material.dart';

import '../app/app_composition_root.dart';
import '../app/ui_tokens.dart';
import '../widgets/add_entry_card.dart';
import '../widgets/add_item_preview_sheet.dart';
import '../widgets/expiry_reminder_preview_sheet.dart';
import '../widgets/maintenance_record_preview_sheet.dart';
import '../widgets/reminder_list_sheet.dart';
import '../widgets/ui_v2_components.dart';
import 'formal_planning_screens.dart';
import 'item_detail_screen.dart';
import 'work_case_screens.dart';

class AddScreen extends StatelessWidget {
  const AddScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final formalEditor = formalPlanningEditor(context);

    if (formalEditor != null) {
      return const _FormalAddScreen();
    }

    return SingleChildScrollView(
      padding: UiInsets.pageCompact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
      ),
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

    return SingleChildScrollView(
      padding: UiInsets.pageCompact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const UiCompactPageHeader(
            icon: Icons.add_rounded,
            title: '新增與整理',
            description: '先建立生活項目，再加入需要長期管理的保養、提醒、階段重點與排程。',
          ),
          const _AddSectionHeader(
            step: '1',
            title: '先建立要管理的生活項目',
            description: '第一次使用，從這裡開始就好。',
          ),
          AddEntryCard(
            icon: Icons.inventory_2_outlined,
            title: '生活項目',
            description: '新增或修改家電、車輛、房屋、文件、健康與其他生活項目。',
            emphasized: true,
            onTap: () => _openItemForm(context),
          ),
          AddEntryCard(
            icon: Icons.category_outlined,
            title: '分類',
            description: '用自己熟悉的名稱整理生活項目，不必一開始就分得很細。',
            onTap: () => open(const CategoryManagementScreen()),
          ),
          const SizedBox(height: UiSpace.sm),
          const _AddSectionHeader(
            step: '2',
            title: '再安排需要長期記住的事',
            description: '保養、提醒與重要階段都會隸屬於生活項目。',
          ),
          AddEntryCard(
            icon: Icons.home_repair_service_outlined,
            title: '保養項目與步驟',
            description: '建立長期保養內容與標準步驟，不代表某一次已完成。',
            onTap: () => open(
              const PlanningContentScreen(
                kind: PlanningContentKind.maintenancePlan,
                handoffCreatedMaintenancePlan: true,
              ),
            ),
          ),
          AddEntryCard(
            icon: Icons.notifications_none_rounded,
            title: '一般提醒',
            description: '管理保固、合約、證件、繳費或健康檢查等提醒。',
            onTap: () => open(
              const PlanningContentScreen(
                kind: PlanningContentKind.reminder,
                handoffCreatedReminder: true,
              ),
            ),
          ),
          AddEntryCard(
            icon: Icons.flag_outlined,
            title: '階段性重點',
            description: '安排大修、汰換評估或達到條件後才需要注意的事情。',
            onTap: () => open(
              const PlanningContentScreen(
                kind: PlanningContentKind.milestone,
                handoffCreatedMilestone: true,
              ),
            ),
          ),
          AddEntryCard(
            icon: Icons.event_repeat_outlined,
            title: '提醒排程',
            description: '替既有內容設定週期、日期與完成後重新計算方式。',
            onTap: () => open(
              const PlanningContentScreen(
                kind: PlanningContentKind.schedule,
                handoffCreatedSchedule: true,
              ),
            ),
          ),
          const SizedBox(height: UiSpace.sm),
          const _AddSectionHeader(
            step: '3',
            title: '開始處理正在發生的事情',
            description: '突發狀況、維修或工程，可以從案件持續留下處理過程。',
          ),
          AddEntryCard(
            icon: Icons.handyman_outlined,
            title: '突發事項／工程',
            description: '建立仍在處理中的突發狀況、修繕、維修或工程案件。',
            onTap: () => _openManualWorkCase(context),
          ),
        ],
      ),
    );
  }

  Future<void> _openManualWorkCase(BuildContext context) async {
    final createdCaseId = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => const ManualWorkCaseFormScreen(),
      ),
    );
    if (!context.mounted || createdCaseId == null) return;

    try {
      final root = AppCompositionScope.of(context);
      final runtime = root.workCaseRuntime;
      if (runtime == null) throw StateError('正式案件服務目前無法使用。');
      final createdCase = await runtime.findCaseById(createdCaseId);
      if (createdCase == null || createdCase.id != createdCaseId) {
        throw StateError('無法讀取剛建立的案件。');
      }
      final items = await root.itemReadRepository.loadItems();
      final matchingItems = items.where(
        (item) => item.id == createdCase.itemId,
      );
      if (!context.mounted) return;
      if (matchingItems.length != 1) {
        _showWorkCaseReadFailure(context);
        return;
      }
      await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => WorkCaseDetailScreen(
            workCaseId: createdCase.id,
            itemName: matchingItems.single.name,
          ),
        ),
      );
    } catch (_) {
      if (context.mounted) _showWorkCaseReadFailure(context);
    }
  }

  Future<void> _openItemForm(BuildContext context) async {
    final result = await Navigator.of(context).push<ItemFormResult>(
      MaterialPageRoute<ItemFormResult>(
        builder: (_) => const ItemFormScreen(usesTypedResult: true),
      ),
    );
    final createdItemId = result?.createdItemId;
    if (!context.mounted || createdItemId == null) return;

    try {
      final items = await AppCompositionScope.of(
        context,
      ).itemReadRepository.loadItems();
      if (!context.mounted) return;
      final createdItems = items.where((item) => item.id == createdItemId);
      if (createdItems.isEmpty) {
        _showItemReadFailure(context);
        return;
      }
      await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => ItemDetailScreen(item: createdItems.single),
        ),
      );
    } catch (_) {
      if (context.mounted) _showItemReadFailure(context);
    }
  }

  void _showItemReadFailure(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('暫時無法讀取生活項目。')));
  }

  void _showWorkCaseReadFailure(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('暫時無法讀取剛建立的案件。')));
  }
}

class _AddSectionHeader extends StatelessWidget {
  const _AddSectionHeader({
    required this.step,
    required this.title,
    required this.description,
  });

  final String step;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: UiSpace.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: UiColors.primary,
            shape: BoxShape.circle,
          ),
          child: Text(step, style: UiType.button.copyWith(color: Colors.white)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: UiType.sectionTitle),
              const SizedBox(height: UiSpace.xxs),
              Text(description, style: UiType.body),
            ],
          ),
        ),
      ],
    ),
  );
}
