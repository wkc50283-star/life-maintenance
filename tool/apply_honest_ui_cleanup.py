from __future__ import annotations

from pathlib import Path


def replace_exact(
    path_name: str,
    old: str,
    new: str,
    expected: int = 1,
) -> None:
    path = Path(path_name)
    text = path.read_text(encoding="utf-8")
    count = text.count(old)
    if count != expected:
        raise RuntimeError(
            f"{path_name}: expected {expected} occurrences of {old!r}, found {count}"
        )
    path.write_text(text.replace(old, new), encoding="utf-8")


def update_product_code() -> None:
    replace_exact(
        "lib/screens/items_screen.dart",
        "import '../widgets/items_category_chips.dart';\n",
        "",
    )
    replace_exact(
        "lib/screens/items_screen.dart",
        "  static const _categories = ['全部', '家電', '車輛', '房屋', '保固證件', '其他'];\n\n",
        "",
    )
    replace_exact(
        "lib/screens/items_screen.dart",
        "        const ItemsHeader(),\n"
        "        const SizedBox(height: 18),\n"
        "        const ItemsCategoryChips(categories: ItemsScreen._categories),\n"
        "        const SizedBox(height: 18),\n",
        "        const ItemsHeader(),\n"
        "        const SizedBox(height: 18),\n",
    )

    internal_rows = (
        "      MaintenanceRecordDetailRow(label: '紀錄 ID', value: record.id),\n"
        "      MaintenanceRecordDetailRow(label: '生活項目 ID', value: record.itemId),\n"
        "      if (_nullableText(record.taskId) != null)\n"
        "        MaintenanceRecordDetailRow(label: '任務 ID', value: record.taskId!),\n"
    )
    replace_exact("lib/screens/items_screen.dart", internal_rows, "")

    replace_exact(
        "lib/screens/history_screen.dart",
        "import '../widgets/history_category_chips.dart';\n",
        "",
    )
    replace_exact(
        "lib/screens/history_screen.dart",
        "  static const _categories = ['全部', '保養', '維修', '更換', '到期提醒'];\n\n",
        "",
    )
    replace_exact(
        "lib/screens/history_screen.dart",
        "        const HistoryHeader(),\n"
        "        const SizedBox(height: 18),\n"
        "        const HistoryCategoryChips(categories: HistoryScreen._categories),\n"
        "        const SizedBox(height: 20),\n",
        "        const HistoryHeader(),\n"
        "        const SizedBox(height: 20),\n",
    )
    replace_exact("lib/screens/history_screen.dart", internal_rows, "")

    old_settings = """  static const _settings = [
    _SettingCardData(
      title: '預設提醒時間',
      content: '每天 09:00',
      icon: Icons.notifications_active_outlined,
      highlighted: false,
    ),
    _SettingCardData(
      title: '安全界線',
      content: '高風險維修不提供 DIY 步驟，請尋求合格專業人員協助。',
      icon: Icons.health_and_safety_outlined,
      highlighted: true,
    ),
    _SettingCardData(
      title: '資料儲存',
      content: '目前資料先保存在本機，雲端同步後續版本開放。',
      icon: Icons.storage_outlined,
      highlighted: false,
    ),
    _SettingCardData(
      title: '匯出資料',
      content: '後續可匯出保養與維修紀錄。',
      icon: Icons.ios_share_outlined,
      highlighted: false,
    ),
    _SettingCardData(
      title: '版本資訊',
      content: 'v0.9.0 責任流程穩定版',
      icon: Icons.info_outline,
      highlighted: false,
    ),
  ];
"""
    new_settings = """  static const _settings = [
    _SettingCardData(
      title: '安全界線',
      content: '高風險維修不提供 DIY 步驟，請尋求合格專業人員協助。',
      icon: Icons.health_and_safety_outlined,
      highlighted: true,
    ),
    _SettingCardData(
      title: '版本資訊',
      content: 'v0.14.0',
      icon: Icons.info_outline,
      highlighted: false,
    ),
  ];
"""
    replace_exact(
        "lib/screens/settings_screen.dart",
        old_settings,
        new_settings,
    )
    replace_exact(
        "lib/widgets/settings_header.dart",
        "            '提醒時間、安全界線與資料管理。',",
        "            '本機資料、安全界線與版本資訊。',",
    )

    for obsolete in (
        "lib/widgets/items_category_chips.dart",
        "lib/widgets/history_category_chips.dart",
    ):
        path = Path(obsolete)
        if not path.exists():
            raise RuntimeError(f"Expected obsolete file to exist: {obsolete}")
        path.unlink()


def create_acceptance_test() -> None:
    path = Path("test/honest_ui_test.dart")
    if path.exists():
        raise RuntimeError("test/honest_ui_test.dart already exists")

    path.write_text(
        """import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/models/enums.dart';
import 'package:life_maintenance/models/item.dart';
import 'package:life_maintenance/models/maintenance_record.dart';
import 'package:life_maintenance/screens/history_screen.dart';
import 'package:life_maintenance/screens/items_screen.dart';
import 'package:life_maintenance/screens/settings_screen.dart';
import 'package:life_maintenance/services/local_data_integrity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.resetStatic();
    SharedPreferences.setMockInitialValues({
      'items': '[]',
      'maintenance_records': '[]',
      'schedules': '[]',
      'tasks': '[]',
    });
    LocalDataIntegrityService.instance.resetForTesting();
  });

  testWidgets('items screen does not show inactive category filters', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ItemsScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('全部'), findsNothing);
    expect(find.text('保固證件'), findsNothing);
  });

  testWidgets('history screen does not show inactive category filters', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HistoryScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('全部'), findsNothing);
    expect(find.text('到期提醒'), findsNothing);
  });

  testWidgets('settings only shows available information', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SettingsScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('預設提醒時間'), findsNothing);
    expect(find.text('匯出資料'), findsNothing);
    expect(find.text('安全界線'), findsOneWidget);
    expect(find.text('版本資訊'), findsOneWidget);
    expect(find.text('v0.14.0'), findsOneWidget);
  });

  testWidgets('history detail hides internal identifiers', (tester) async {
    final item = Item(
      id: 'item-1',
      name: '冷氣',
      category: ItemCategory.appliance,
      createdAt: DateTime(2026, 7, 1),
    );
    final record = MaintenanceRecord(
      id: 'record-1',
      itemId: item.id,
      taskId: 'task-1',
      recordType: RecordType.repair,
      date: DateTime(2026, 7, 2),
      title: '冷氣維修',
      workDescription: '更換零件並測試',
      result: '正常運作',
      createdAt: DateTime(2026, 7, 2),
    );
    SharedPreferences.setMockInitialValues({
      'items': jsonEncode([item.toJson()]),
      'maintenance_records': jsonEncode([record.toJson()]),
      'schedules': '[]',
      'tasks': '[]',
    });

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HistoryScreen())),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('冷氣維修').first);
    await tester.pumpAndSettle();

    expect(find.text('紀錄 ID'), findsNothing);
    expect(find.text('生活項目 ID'), findsNothing);
    expect(find.text('任務 ID'), findsNothing);
    expect(find.text('處理內容'), findsOneWidget);
  });
}
""",
        encoding="utf-8",
    )


def update_change_log() -> None:
    path = Path("docs/control/06-change-log.md")
    text = path.read_text(encoding="utf-8")

    pending = "- squash commit 待合併後補記"
    if text.count(pending) != 1:
        raise RuntimeError(
            f"Expected one pending LM-008 commit entry, found {text.count(pending)}"
        )
    text = text.replace(
        pending,
        "- squash commit `4fe81132fc7a143a3c9cc1bd54d4b8568f7a8902`",
    )

    marker = "---\n\n## 後續條目模板"
    if text.count(marker) != 1:
        raise RuntimeError(
            f"Expected one change-log template marker, found {text.count(marker)}"
        )

    entry = """---

## LM-009：移除假操作元件與工程資訊

日期：2026-07-18  
類型：UI／產品治理

### 問題

「我的項目」與「履歷」頁顯示看似可選的分類膠囊，但實際不能操作；設定頁列出尚不存在的預設提醒時間與資料匯出功能；完成紀錄詳情直接顯示內部 ID。這些內容會讓使用者誤以為 App 已具備功能，或暴露不必要的工程資訊。

### 修改

- 移除「我的項目」與「履歷」頁的非功能性分類膠囊。
- 移除尚未實作的「預設提醒時間」與「匯出資料」設定卡。
- 設定頁保留本機資料說明、安全界線與目前版本資訊。
- 移除完成紀錄詳情中的紀錄 ID、生活項目 ID 與任務 ID。
- 新增 Widget 測試，確認假操作元件與內部 ID 不會出現在一般畫面。

### 明確未修改

- 不新增真正的分類篩選、提醒時間設定或匯出功能。
- 不修改資料模型、Repository、儲存鍵或既有資料。
- 不修改排程、提醒、完成與紀錄流程。
- 不重做整體視覺設計。

### 資料影響

無。內部 ID 仍保留在資料模型與儲存內容中，只是不再直接顯示給一般使用者。

### 驗收

- 兩頁不再顯示不可操作的分類膠囊。
- 設定頁不再宣稱尚未存在的功能。
- 完成紀錄詳情不顯示工程 ID。
- `flutter analyze`、`flutter test` 與 Web release build 全部通過後才合併。

### 批准

依產品憲法「只做真的功能」與產品功能規格書的直接、誠實介面原則執行。

### PR／commit

- PR #171
- squash commit 待合併後補記

---

## 後續條目模板"""
    path.write_text(text.replace(marker, entry), encoding="utf-8")


def remove_one_time_files() -> None:
    for file_name in (
        ".github/workflows/apply-honest-ui-cleanup.yml",
        ".github/trigger-honest-ui.txt",
        "tool/apply_honest_ui_cleanup.py",
    ):
        path = Path(file_name)
        if not path.exists():
            raise RuntimeError(f"Expected one-time file to exist: {file_name}")
        path.unlink()


def main() -> None:
    update_product_code()
    create_acceptance_test()
    update_change_log()
    remove_one_time_files()


if __name__ == "__main__":
    main()
