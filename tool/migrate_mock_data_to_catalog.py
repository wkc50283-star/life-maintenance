from __future__ import annotations

from pathlib import Path


def replace_exact(path_name: str, old: str, new: str, expected: int = 1) -> None:
    path = Path(path_name)
    text = path.read_text(encoding="utf-8")
    count = text.count(old)
    if count != expected:
        raise RuntimeError(
            f"{path_name}: expected {expected} occurrences of {old!r}, found {count}"
        )
    path.write_text(text.replace(old, new), encoding="utf-8")


def update_today_screen() -> None:
    replace_exact(
        "lib/screens/today_screen.dart",
        "import '../data/mock_data.dart';",
        "import '../data/maintenance_card_catalog.dart';",
    )

    old_lookup = """MaintenanceCard? _cardForTask(maintenance_task.Task task) {
  for (final card in MockData.maintenanceCards) {
    if (card.id == task.cardId) {
      return card;
    }
  }

  return null;
}
"""
    new_lookup = """MaintenanceCard? _cardForTask(maintenance_task.Task task) {
  return MaintenanceCardCatalog.resolve(
    cardId: task.cardId,
    itemId: task.itemId,
  );
}
"""
    replace_exact("lib/screens/today_screen.dart", old_lookup, new_lookup)


def remove_obsolete_mock_data() -> None:
    path = Path("lib/data/mock_data.dart")
    if not path.exists():
        raise RuntimeError("Expected lib/data/mock_data.dart to exist")
    path.unlink()


def update_change_log() -> None:
    path = Path("docs/control/06-change-log.md")
    text = path.read_text(encoding="utf-8")

    pending = "- squash commit 待合併後補記"
    if text.count(pending) != 1:
        raise RuntimeError(
            f"Expected one pending LM-010 commit entry, found {text.count(pending)}"
        )
    text = text.replace(
        pending,
        "- squash commit `c7594515937ea8bcc2b4fd4750d994d492db2764`",
    )

    marker = "---\n\n## 後續條目模板"
    if text.count(marker) != 1:
        raise RuntimeError(
            f"Expected one change-log template marker, found {text.count(marker)}"
        )

    entry = """---

## LM-011：將假資料檔改為正式保養卡目錄

日期：2026-07-18  
類型：架構／資料治理

### 問題

`TodayScreen` 仍從 `MockData.maintenanceCards` 取得保養卡步驟、預估時間與風險資訊。原 `mock_data.dart` 同時包含假生活項目、假排程、假任務與假履歷，而且保養卡模板綁著假的 `itemId`。即使假生活項目目前沒有直接顯示，正式流程仍依賴混雜假資料的來源，未來很容易誤接回正式畫面或錯誤關聯使用者資料。

### 修改

- 新增 `MaintenanceCardCatalog` 作為正式保養卡模板目錄。
- 保留四張目前仍被既有任務卡 ID 使用的模板與原有步驟、風險、時間資料。
- 解析模板時以任務真正的 `itemId` 建立卡片，不再沿用假生活項目關聯。
- 未知 `cardId` 維持安全回傳 `null`。
- `TodayScreen` 改由正式目錄解析卡片。
- 刪除包含假生活項目、排程、任務與履歷的 `mock_data.dart`。
- 新增目錄解析與真實 `itemId` 綁定測試。

### 明確未修改

- 不修改既有保養卡 ID，避免舊任務失去對應。
- 不修改 Task、Schedule、Item 或 MaintenanceRecord 的資料格式。
- 不遷移、不刪除任何使用者本機資料。
- 不修改今日任務產生、完成與後續排程邏輯。
- 不新增保養卡編輯功能。

### 資料影響

無持久化資料變更。這一批只清理程式內建目錄來源；既有本機 JSON 不會被讀寫或轉換。

### 驗收

- repo 不再存在 `MockData` 或 `mock_data.dart`。
- 已知卡片 ID 仍可取得相同步驟、風險與預估時間。
- 解析後的卡片使用任務真正的 `itemId`。
- 未知卡片維持安全降級。
- `flutter analyze`、`flutter test` 與 Web release build 全部通過後才合併。

### 批准

依產品憲法「只做真的功能」與架構文件「正式資料不得依賴展示假資料」原則執行。

### PR／commit

- PR #173
- squash commit 待合併後補記

---

## 後續條目模板"""
    path.write_text(text.replace(marker, entry), encoding="utf-8")


def remove_one_time_files() -> None:
    for file_name in (
        ".github/workflows/migrate-mock-data-to-catalog.yml",
        "tool/migrate_mock_data_to_catalog.py",
    ):
        path = Path(file_name)
        if not path.exists():
            raise RuntimeError(f"Expected one-time file to exist: {file_name}")
        path.unlink()


def main() -> None:
    update_today_screen()
    remove_obsolete_mock_data()
    update_change_log()
    remove_one_time_files()


if __name__ == "__main__":
    main()
