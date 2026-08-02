import 'package:flutter/material.dart';

import '../app/app_composition_root.dart';
import '../app/ui_tokens.dart';
import '../widgets/add_entry_card.dart';
import '../widgets/add_item_preview_sheet.dart';
import '../widgets/expiry_reminder_preview_sheet.dart';
import '../widgets/maintenance_record_detail_sheet.dart';
import '../widgets/maintenance_record_preview_sheet.dart';
import '../widgets/reminder_list_sheet.dart';
import '../widgets/ui_v2_components.dart';
import 'formal_planning_screens.dart';
import 'maintenance_record_screens.dart';
import 'work_case_screens.dart';

class AddScreen extends StatefulWidget {
  const AddScreen({super.key, this.onShowItems});

  final VoidCallback? onShowItems;

  @override
  State<AddScreen> createState() => AddScreenState();
}

class AddScreenState extends State<AddScreen> {
  Future<void> showItemCreationMenu() => _openItemForm();

  @override
  Widget build(BuildContext context) {
    final formalEditor = formalPlanningEditor(context);

    if (formalEditor != null) {
      return const _FormalAddScreen();
    }

    return SingleChildScrollView(
      key: const ValueKey('add-screen-scroll'),
      padding: UiInsets.pageCompact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const UiCompactPageHeader(
            icon: Icons.add_rounded,
            title: '現在需要記住或處理什麼？',
            description: '選擇需要的建立方式。',
          ),
          const Text('更多建立方式', style: UiType.sectionTitle),
          const SizedBox(height: UiSpace.xs),
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

  Future<void> _openItemForm() async {
    final result = await Navigator.of(context).push<ItemFormResult>(
      MaterialPageRoute<ItemFormResult>(
        builder: (_) => const ItemFormScreen(usesTypedResult: true),
      ),
    );
    if (!mounted || result?.createdItemId == null) return;
    if (result!.showItems) widget.onShowItems?.call();
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
      key: const ValueKey('add-screen-scroll'),
      padding: UiInsets.pageCompact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const UiCompactPageHeader(
            icon: Icons.add_rounded,
            title: '現在需要記住或處理什麼？',
            description: '選擇需要的建立方式。',
          ),
          const Text('更多建立方式', style: UiType.sectionTitle),
          const SizedBox(height: UiSpace.xs),
          AddEntryCard(
            icon: Icons.category_outlined,
            title: '分類',
            description: '用自己熟悉的名稱整理生活項目。',
            onTap: () => open(const CategoryManagementScreen()),
          ),
          AddEntryCard(
            icon: Icons.home_repair_service_outlined,
            title: '保養項目與步驟',
            description: '建立長期保養內容與標準步驟。',
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
            description: '安排達到條件後才需要注意的事情。',
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
            description: '替既有內容設定週期、日期與重新計算方式。',
            onTap: () => open(
              const PlanningContentScreen(
                kind: PlanningContentKind.schedule,
                handoffCreatedSchedule: true,
              ),
            ),
          ),
          AddEntryCard(
            icon: Icons.handyman_outlined,
            title: '突發事項／工程',
            description: '建立仍在處理中的突發狀況、修繕或工程案件。',
            onTap: () => _openManualWorkCase(context),
          ),
          AddEntryCard(
            icon: Icons.fact_check_outlined,
            title: '補登完成紀錄',
            description: '已完成的事情，可以補留下正式紀錄。',
            onTap: () => _openManualMaintenanceRecord(context),
          ),
        ],
      ),
    );
  }

  Future<void> _openManualMaintenanceRecord(BuildContext context) async {
    final result = await Navigator.of(context)
        .push<ManualMaintenanceRecordResult>(
          MaterialPageRoute<ManualMaintenanceRecordResult>(
            builder: (_) => const ManualMaintenanceRecordFormScreen(),
          ),
        );
    if (!context.mounted || result == null) return;

    try {
      final repository = AppCompositionScope.of(
        context,
      ).maintenanceRecordRepository;
      final record = await repository.findById(result.recordId);
      if (!context.mounted) return;
      if (record == null ||
          record.id != result.recordId ||
          record.itemId != result.itemId) {
        _showMaintenanceRecordReadFailure(context);
        return;
      }
      showMaintenanceRecordDetailSheet(
        context,
        data: MaintenanceRecordDetailData(
          title: record.title,
          recordType: '完成紀錄',
          date: _formatRecordDate(record.date),
          result: '已記錄',
          rows: [
            if (record.note case final note? when note.trim().isNotEmpty)
              MaintenanceRecordDetailRow(label: '備註', value: note),
          ],
        ),
      );
    } catch (_) {
      if (context.mounted) _showMaintenanceRecordReadFailure(context);
    }
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

  void _showWorkCaseReadFailure(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('暫時無法讀取剛建立的案件。')));
  }

  void _showMaintenanceRecordReadFailure(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('無法讀取剛建立的紀錄。')));
  }

  String _formatRecordDate(DateTime value) =>
      '${value.year}/${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')}';
}
