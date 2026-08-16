import 'package:flutter/material.dart';

import '../app/ui_tokens.dart';
import '../widgets/add_entry_card.dart';
import '../widgets/add_item_preview_sheet.dart';
import '../widgets/expiry_reminder_preview_sheet.dart';
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
      return _FormalAddScreen(onOpenItemCreation: _openItemForm);
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
  const _FormalAddScreen({required this.onOpenItemCreation});

  final VoidCallback onOpenItemCreation;

  @override
  Widget build(BuildContext context) {
    void openPurpose({
      required String routeKey,
      required String title,
      required String message,
    }) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _ManualCreatePurposeRoute(
            routeKey: routeKey,
            title: title,
            message: message,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      key: const ValueKey('add-screen-scroll'),
      padding: UiInsets.pageCompact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const UiCompactPageHeader(
            icon: Icons.add_rounded,
            title: '你現在想做什麼？',
            description: '選擇最接近目前目的的方式。',
          ),
          AddEntryCard(
            key: const ValueKey('manual-create-purpose-item'),
            icon: Icons.inventory_2_outlined,
            title: '建立要長期管理的內容',
            description: '例如家電、車輛、房屋、證件或其他生活項目。',
            onTap: onOpenItemCreation,
          ),
          AddEntryCard(
            key: const ValueKey('manual-create-purpose-future-matter'),
            icon: Icons.event_note_outlined,
            title: '安排未來要注意或處理的事情',
            description: '例如之後再安排、指定日期、固定重複或達到條件。',
            onTap: () => openPurpose(
              routeKey: 'manual-create-future-matter-route',
              title: '安排未來要注意或處理的事情',
              message: '未來事項建立流程尚在準備中，目前不會建立任何資料。',
            ),
          ),
          AddEntryCard(
            key: const ValueKey('manual-create-purpose-work-case'),
            icon: Icons.handyman_outlined,
            title: '記錄正在處理的事情',
            description: '例如突發狀況、修繕、維修或仍在處理的問題。',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ManualWorkCaseFormScreen(),
              ),
            ),
          ),
          AddEntryCard(
            key: const ValueKey('manual-create-purpose-completed'),
            icon: Icons.fact_check_outlined,
            title: '補記已完成的事情',
            description: '例如補記實際完成日期、結果或相關紀錄。',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ManualMaintenanceRecordFormScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualCreatePurposeRoute extends StatelessWidget {
  const _ManualCreatePurposeRoute({
    required this.routeKey,
    required this.title,
    required this.message,
  });

  final String routeKey;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
    key: ValueKey(routeKey),
    appBar: AppBar(title: Text(title)),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: UiInsets.page,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(UiSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded),
                const SizedBox(height: UiSpace.sm),
                Text(title, style: UiType.cardTitle),
                const SizedBox(height: UiSpace.xs),
                Text(message, style: UiType.body),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
