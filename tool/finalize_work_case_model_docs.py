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
    old_section = """## 2. 目標新增模型

### `WorkCase`（暫定技術名稱）

代表一件實際處理中的保養、修理、工程或生活事件。

建議欄位：

- `id`
- `itemId`
- `sourceType`
- `sourceId`
- `caseType`
- `title`
- `description`
- `occurredAt`
- `startedAt`
- `status`
- `createdAt`
- `closedAt`
- `closeResult`

### `WorkCaseUpdate`（暫定技術名稱）

代表案件中一筆不可被後續進度覆蓋的實際處理紀錄。

建議欄位：

- `id`
- `workCaseId`
- `occurredAt`
- `description`
- `contactOrVendor`
- `cost`
- `partsOrItems`
- `photoIdentifiers`
- `note`
- `nextAction`
- `createdAt`

正式中文介面名稱依情境顯示為保養／修理卡、工程卡、辦理卡或其他生活事件卡；底層角色保持一致。
"""

    new_section = """## 2. 案件模型基線

第一版資料模型已建立；目前只定義角色與 JSON 格式，尚未接入 Repository、正式資料庫或 UI 寫入流程。

### `WorkCase`

代表一件實際處理中的保養、修理、工程或生活事件。

正式來源類型 `WorkCaseSourceType`：

- `maintenanceTask`：由某次保養任務開始
- `generalReminder`：由一般提醒轉入
- `milestone`：由階段性重點開始
- `manual`：使用者直接建立
- `unknown`：未來或未知來源的安全 fallback

正式案件類型 `WorkCaseType`：

- `maintenance`
- `repair`
- `construction`
- `administrative`
- `other`

正式案件狀態 `WorkCaseStatus`：

- `notStarted`
- `inProgress`
- `waiting`
- `completed`
- `canceled`

第一版欄位：

- `schemaVersion`
- `id`
- `itemId`
- `sourceType`
- `sourceId`（手動建立時可空）
- `caseType`
- `title`
- `description`
- `occurredAt`
- `startedAt`
- `status`
- `createdAt`
- `updatedAt`
- `closedAt`
- `closeResult`
- `cancellationReason`

`completed` 與 `canceled` 都屬於結案；取消案件必須能保存取消原因，不得直接消失。

### `WorkCaseUpdate`

代表案件中一筆不可被後續進度覆蓋的實際處理紀錄。

第一版欄位：

- `schemaVersion`
- `id`
- `workCaseId`
- `occurredAt`
- `description`
- `contactOrVendor`
- `result`
- `cost`
- `partsOrItems`
- `photoIdentifiers`
- `waitingReason`
- `note`
- `nextAction`
- `createdAt`

`partsOrItems` 與 `photoIdentifiers` 在模型中以不可修改清單保存。既有進度不得原地改寫；若需更正，未來應新增修正紀錄並保留原始事實。

正式中文介面名稱依情境顯示為保養／修理卡、工程卡、辦理卡或其他生活事件卡；底層角色保持一致。
"""

    replace_exact(
        "docs/control/03-architecture-and-data.md",
        old_section,
        new_section,
    )


def update_change_log() -> None:
    path = Path("docs/control/06-change-log.md")
    text = path.read_text(encoding="utf-8")

    pending = "- squash commit 待合併後補記"
    if text.count(pending) != 1:
        raise RuntimeError(
            f"Expected one pending LM-011 commit entry, found {text.count(pending)}"
        )
    text = text.replace(
        pending,
        "- squash commit `cacb0b718dda835ee1ba5e954373ccce0adf970c`",
    )

    marker = "---\n\n## 後續條目模板"
    if text.count(marker) != 1:
        raise RuntimeError(
            f"Expected one change-log template marker, found {text.count(marker)}"
        )

    entry = """---

## LM-012：建立處理案件與多筆進度模型基線

日期：2026-07-18  
類型：架構／資料模型

### 問題

現有 `Task` 只能表示某次提醒浮上檯面，`MaintenanceRecord` 主要保存已完成結果；兩者都無法表達一件修理、工程或辦理事項從發生、開始、等待、多次處理到結案的完整過程。若直接把進度塞回 Task 或完成紀錄，會再次混淆提醒、規則、實際事件與史略。

### 修改

- 新增 `WorkCaseSourceType`、`WorkCaseType` 與 `WorkCaseStatus`。
- 新增 `WorkCase`，保存來源、案件類型、標題、發生／開始時間、狀態、更新時間、結案結果與取消原因。
- 新增 `WorkCaseUpdate`，保存每一筆處理內容、店家／人員、判斷結果、費用、零件、照片識別、等待原因、備註與下一步。
- 兩個模型的 JSON 都加入 `schemaVersion`。
- 未知 enum 採安全 fallback；未知來源保留為 `unknown`，未知案件類型保留為 `other`，未知狀態回到 `notStarted`。
- `WorkCaseUpdate` 的零件與照片清單採不可修改清單，強化進度不可被後續內容原地覆蓋的原則。
- 新增完整 round-trip、未知 enum、結案、取消原因、nullable 清除、清單不可修改與舊格式安全預設測試。
- 架構文件由「建議欄位」更新為第一版正式模型基線。

### 明確未修改

- 不修改現有 Item、MaintenanceCard、Schedule、Task 或 MaintenanceRecord。
- 不建立案件 Repository 或 SharedPreferences 儲存鍵。
- 不執行舊資料遷移。
- 不讓任何現有 UI 建立或修改案件。
- 不更換正式資料庫。

### 資料影響

無。新模型目前尚未接入持久化層，不會讀寫任何既有本機 JSON。

### 驗收

- 案件與進度資料角色明確分離。
- 五種正式案件狀態可安全序列化。
- 未知 enum 不會造成整筆模型失敗。
- 手動案件可沒有 `sourceId`。
- 已完成與已取消案件可正確判斷為結案。
- 取消原因可被保存。
- 進度清單不可原地修改。
- `flutter analyze`、`flutter test` 與 Web release build 全部通過後才合併。

### 批准

依產品功能規格書第 7 至 11 節及架構文件已批准的 `WorkCase`／`WorkCaseUpdate` 方向執行。

### PR／commit

- PR #174
- squash commit 待合併後補記

---

## 後續條目模板"""
    path.write_text(text.replace(marker, entry), encoding="utf-8")


def remove_one_time_files() -> None:
    for file_name in (
        ".github/workflows/finalize-work-case-model-docs.yml",
        "tool/finalize_work_case_model_docs.py",
    ):
        path = Path(file_name)
        if not path.exists():
            raise RuntimeError(f"Expected one-time file to exist: {file_name}")
        path.unlink()


def main() -> None:
    update_architecture()
    update_change_log()
    remove_one_time_files()


if __name__ == "__main__":
    main()
