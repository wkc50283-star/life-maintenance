from __future__ import annotations

from pathlib import Path


def replace_exact(path_name: str, old: str, new: str, expected: int = 1) -> None:
    path = Path(path_name)
    text = path.read_text(encoding="utf-8")
    count = text.count(old)
    if count != expected:
        raise RuntimeError(
            f"{path_name}: expected {expected} occurrences of target, found {count}"
        )
    path.write_text(text.replace(old, new), encoding="utf-8")


def update_architecture() -> None:
    replace_exact(
        "docs/control/03-architecture-and-data.md",
        "→ 建立 schema 與版本\n→ 保留原始備份",
        "→ 建立 schema 與版本（案件 schema v1 已完成）\n→ 保留原始備份",
    )
    replace_exact(
        "docs/control/03-architecture-and-data.md",
        "下一個資料庫批次只允許建立空的 schema v1、`work_cases`／`work_case_updates` tables、transaction tests 與 native／web 開啟基礎；不得同時匯入舊 SharedPreferences 資料。",
        "案件資料庫 schema v1 已建立，只包含 `work_cases` 與 `work_case_updates`。現有 App 尚未開啟或使用 Drift，SharedPreferences 仍是正式運作中的來源。下一個資料批次必須先建立 Repository 介面與新舊雙讀比對工具；不得直接匯入、覆寫或刪除舊 JSON。",
    )


def update_readme() -> None:
    replace_exact(
        "README.md",
        "5. 正式資料庫 schema 與安全遷移",
        "5. 正式資料庫 schema v1（案件表已完成，尚未接管資料）",
    )
    replace_exact(
        "README.md",
        "正式資料庫已選擇 Drift + SQLite；目前尚未加入 dependency 或遷移資料，下一步只建立空 schema v1 與案件資料表。",
        "Drift + SQLite schema v1 已建立，目前只包含案件與進度資料表；現有 App 尚未開啟資料庫，也沒有遷移任何 SharedPreferences 資料。",
    )
    replace_exact(
        "README.md",
        "```bash\nflutter analyze\nflutter test\nflutter build web --release\n```",
        "```bash\nflutter pub get\ndart run build_runner build --delete-conflicting-outputs\ndart compile js -O4 web/drift_worker.dart -o web/drift_worker.dart.js\npython3 tool/prepare_drift_web_assets.py\nflutter analyze\nflutter test\nflutter build web --release\n```",
    )


def update_change_log() -> None:
    path = Path("docs/control/06-change-log.md")
    text = path.read_text(encoding="utf-8")

    pending = "- squash commit 待合併後補記"
    if text.count(pending) != 1:
        raise RuntimeError(
            f"Expected one pending LM-013 commit entry, found {text.count(pending)}"
        )
    text = text.replace(
        pending,
        "- squash commit `4c00bf4084aca2b9c1faaa57ad2580a97e3baf02`",
    )

    marker = "---\n\n## 後續條目模板"
    if text.count(marker) != 1:
        raise RuntimeError(
            f"Expected one change-log template marker, found {text.count(marker)}"
        )

    entry = """---

## LM-014：建立 Drift 案件 schema v1

日期：2026-07-18  
類型：架構／資料庫／安全／CI

### 問題

案件與多筆進度模型已定義，但尚無可驗證的正式關聯式 schema。若直接把新模型塞進 SharedPreferences，會延續多組 JSON、部分寫入與關聯無法驗證的問題；若同時建立 schema 又搬移舊資料，則風險範圍過大且難以回復。

### 修改

- 鎖定 `drift 2.34.2`、`drift_flutter 0.3.1`、`sqlite3 3.4.0`、`drift_dev 2.34.4` 與 `build_runner 2.15.1`。
- 建立 `AppDatabase` schema version 1。
- 建立 `work_cases` 與 `work_case_updates` 兩張表。
- 建立案件狀態、來源、更新時間與案件進度時間索引。
- `work_case_updates.work_case_id` 使用 foreign key；有進度的案件不得直接刪除。
- 日期採 ISO 8601 文字儲存，保留微秒與 UTC 資訊。
- enum converter 對未知值保留安全 fallback。
- 零件與照片識別清單以 JSON 文字保存；格式異常時安全回傳空清單。
- native 使用 Drift SQLite 開啟基礎；Web 指向 matching `sqlite3.wasm` 與 worker。
- 加入可重現的 Web WASM 準備腳本與 worker 原始碼。
- CI 在 Analyze 前執行 code generation、worker 編譯、matching WASM 準備與資產驗證。
- 新增建表、日期精度、foreign key、限制刪除與 transaction rollback 測試。

### 明確未修改

- 不讓 `main.dart` 開啟 `AppDatabase`。
- 不建立正式案件 Repository。
- 不讀寫、匯入、轉換或刪除 `items`、`schedules`、`tasks`、`maintenance_records`。
- 不修改現有 SharedPreferences 儲存鍵。
- 不新增案件 UI。
- 不切換正式資料來源。

### 資料影響

無現有資料影響。schema v1 雖已可建立，但目前沒有被 App 啟動或寫入；現行 SharedPreferences 仍照原流程運作。

### 生成與資產原則

- `app_database.g.dart`、worker JavaScript 與 `sqlite3.wasm` 是可重現產物，不直接提交。
- `pubspec.lock` 必須提交，確保套件版本可重現。
- Web build 除了成功編譯，還必須確認 worker 與 matching WASM 實際存在於輸出。

### 驗收

- dependency resolution 與 code generation 通過。
- schema v1 建立兩張正確資料表。
- ISO 日期可保留微秒與 UTC。
- 孤兒進度被 foreign key 阻止。
- 有進度的案件不可直接刪除。
- transaction 失敗不留下部分案件或進度。
- Analyze、全部測試、Web release build 與 Web 資產驗證全部通過。

### 批准

依 `07-database-decision.md` 的第一版 schema 邊界執行。

### PR／commit

- PR #176
- squash commit 待合併後補記

---

## 後續條目模板"""
    path.write_text(text.replace(marker, entry), encoding="utf-8")


def remove_temporary_files() -> None:
    paths = (
        ".github/workflows/generate-drift-schema-v1.yml",
        ".github/trigger-drift-generation.txt",
        "diagnostics/drift-pub-get.txt",
        "diagnostics/drift-analyze.txt",
        "tool/finalize_drift_schema_v1.py",
    )
    for file_name in paths:
        path = Path(file_name)
        if not path.exists():
            raise RuntimeError(f"Expected temporary file to exist: {file_name}")
        path.unlink()


def main() -> None:
    update_architecture()
    update_readme()
    update_change_log()
    remove_temporary_files()


if __name__ == "__main__":
    main()
