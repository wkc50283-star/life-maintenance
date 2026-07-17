from __future__ import annotations

from pathlib import Path


def replace_exact(path_name: str, old: str, new: str, expected: int = 1) -> None:
    path = Path(path_name)
    text = path.read_text(encoding="utf-8")
    count = text.count(old)
    if count != expected:
        raise RuntimeError(
            f"{path_name}: expected {expected} occurrences of target block, found {count}"
        )
    path.write_text(text.replace(old, new), encoding="utf-8")


def update_architecture() -> None:
    old = """## 8. 正式資料庫遷移

更換正式資料庫的方向已批准，但不得先選技術再硬套產品。

遷移順序：

```text
定義最終資料角色
→ 比較候選資料庫
→ 建立 schema 與版本
→ 保留原始備份
→ 新舊雙讀驗證
→ 匯入資料
→ 比對筆數與關聯
→ 真機驗收
→ 確認可回復
→ 才停止舊儲存
```

候選技術必須評估：

- Flutter／iOS／Web 支援
- schema migration
- 查詢與關聯
- 照片識別管理
- 備份與匯出
- 長期維護性
- 測試便利性
"""
    new = """## 8. 正式資料庫遷移

正式選型已批准：Drift + SQLite；native 使用 `NativeDatabase`，Flutter Web 使用 `WasmDatabase`。完整證據、候選比較、風險與重新評估條件見 `07-database-decision.md`。

這項決策不代表可以直接搬移資料。遷移順序仍為：

```text
定義最終資料角色
→ 比較候選資料庫（已完成）
→ 建立 schema 與版本
→ 保留原始備份
→ 新舊雙讀驗證
→ 匯入資料
→ 比對筆數與關聯
→ 真機驗收
→ 確認可回復
→ 才停止舊儲存
```

下一個資料庫批次只允許建立空的 schema v1、`work_cases`／`work_case_updates` tables、transaction tests 與 native／web 開啟基礎；不得同時匯入舊 SharedPreferences 資料。

正式資料庫實作必須持續驗證：

- Flutter／iOS／Web 支援
- schema migration
- 查詢與關聯
- 照片識別管理
- 備份與匯出
- 長期維護性
- 測試便利性
- Web WASM 與 worker 實際部署
"""
    replace_exact("docs/control/03-architecture-and-data.md", old, new)


def update_readme() -> None:
    replace_exact(
        "README.md",
        "4. 處理案件與多筆進度模型\n5. 階段性重點\n6. 正式資料庫與安全遷移",
        "4. 處理案件與多筆進度模型（模型基線已完成）\n5. 正式資料庫 schema 與安全遷移\n6. 階段性重點",
    )
    replace_exact(
        "README.md",
        "- SharedPreferences（現行過渡儲存）\n- GitHub Actions",
        "- SharedPreferences（現行過渡儲存）\n- Drift + SQLite（正式資料庫已選型，尚未接管資料）\n- GitHub Actions",
    )
    replace_exact(
        "README.md",
        "正式資料庫遷移方向已批准，但資料庫技術選型必須在案件模型與遷移驗證完成後定案。",
        "正式資料庫已選擇 Drift + SQLite；目前尚未加入 dependency 或遷移資料，下一步只建立空 schema v1 與案件資料表。",
    )
    replace_exact(
        "README.md",
        "6. [變更與決策紀錄](docs/control/06-change-log.md)",
        "6. [變更與決策紀錄](docs/control/06-change-log.md)\n7. [正式資料庫選型決策](docs/control/07-database-decision.md)",
    )


def update_archive_readme() -> None:
    replace_exact(
        "docs/archive/README.md",
        "6. `docs/control/06-change-log.md`",
        "6. `docs/control/06-change-log.md`\n7. `docs/control/07-database-decision.md`",
    )


def update_change_log() -> None:
    path = Path("docs/control/06-change-log.md")
    text = path.read_text(encoding="utf-8")

    pending = "- squash commit 待合併後補記"
    if text.count(pending) != 1:
        raise RuntimeError(
            f"Expected one pending LM-012 commit entry, found {text.count(pending)}"
        )
    text = text.replace(
        pending,
        "- squash commit `b8e880469e951d0970f9411a11a10961edd95d6e`",
    )

    marker = "---\n\n## 後續條目模板"
    if text.count(marker) != 1:
        raise RuntimeError(
            f"Expected one change-log template marker, found {text.count(marker)}"
        )

    entry = """---

## LM-013：正式資料庫選擇 Drift + SQLite

日期：2026-07-18  
類型：架構／技術選型／資料安全

### 問題

SharedPreferences 的四組 JSON 可承接現有 MVP，但不適合長期保存 `Item → WorkCase → WorkCaseUpdate` 關聯、大量史略、照片識別與需要原子交易的複合操作。案件模型完成後，必須先以目前正式資料角色比較候選資料庫，不能先加入套件再硬套產品。

### 證據檢查

以官方文件比較 Drift、Hive CE、Isar、ObjectBox 與 sqflite，必要條件包括 iOS／Web、關聯查詢、交易、schema version、可驗證 migration、測試與長期維護。

### 決策

- 正式資料層採 Drift + SQLite。
- native 使用 `NativeDatabase`。
- Flutter Web 使用 `WasmDatabase`。
- Web 部署必須驗證 `sqlite3.wasm`、worker、持久化與瀏覽器 fallback。
- 完整選型依據、候選比較、已知成本、實作順序與重新評估條件記錄於 `07-database-decision.md`。

### 不採用重點

- Hive CE：跨平台，但 key-value／NoSQL 需要自行補足本專案的關聯、交易與 migration 證據鏈。
- Isar：有 ACID 與 links，但資料 migration 版本與流程需由 App 自行管理，原始穩定版與社群 fork 的長期治理風險較高。
- ObjectBox：官方 Dart／Flutter 平台文件未列 Web。
- sqflite：Web 實作仍標示 experimental。

### 明確未修改

- 不加入任何資料庫 dependency。
- 不建立正式 schema 或生成程式碼。
- 不新增資料庫檔案。
- 不讀寫、匯入或刪除任何 SharedPreferences 資料。
- 不讓 UI 或 Repository 改用 Drift。

### 資料影響

無。本批次只有架構決策與控制文件。

### 下一步邊界

下一個 PR 只允許鎖定相容 dependency、建立空 schema v1、`work_cases`／`work_case_updates` tables、必要索引、foreign keys、transaction tests 與 native／web 開啟基礎。不得同時遷移舊資料。

### 驗收

- 選型條件與證據來源可追溯。
- 已知 Web 成本與回復原則沒有被隱藏。
- README、架構文件與封存區的控制文件清單一致。
- PR 差異只包含文件。
- 現有 Analyze、Test 與 Web build 仍通過。

### 批准

依架構文件第 8 節的候選評估條件與產品資料角色執行。

### PR／commit

- PR #175
- squash commit 待合併後補記

---

## 後續條目模板"""
    path.write_text(text.replace(marker, entry), encoding="utf-8")


def remove_one_time_files() -> None:
    for file_name in (
        ".github/workflows/finalize-database-decision.yml",
        "tool/finalize_database_decision.py",
    ):
        path = Path(file_name)
        if not path.exists():
            raise RuntimeError(f"Expected one-time file to exist: {file_name}")
        path.unlink()


def main() -> None:
    update_architecture()
    update_readme()
    update_archive_readme()
    update_change_log()
    remove_one_time_files()


if __name__ == "__main__":
    main()
