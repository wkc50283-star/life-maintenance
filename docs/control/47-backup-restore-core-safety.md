# Backup and Restore Core Safety（PR #235）

狀態：正式控制文件  
版本：v0.5.34  
日期：2026-07-21

## 1. 範圍與正式格式

本 PR 只補強正式 Drift SQLite 資料庫的備份與還原核心安全，不接 UI、Composition Root 或自動啟動流程。正式備份格式仍是 Schema v2 SQLite database file；沒有新增 JSON、manifest、資料表、database name、Schema 或 Migration。

`backup_v1_*` 仍是 SharedPreferences 舊來源的不可變唯讀證據，與本文件的正式 Drift SQLite 備份角色不同。兩者都不得被自動刪除、覆蓋或當成雙寫目的地。

## 2. 呼叫前置條件

- 呼叫端必須先關閉正式 Drift database，避免仍持有中的 executor 與檔案替換競爭。
- source、backup 與 restore destination 必須是不同路徑。
- 建立備份不得覆寫既有 backup file。
- 本核心只處理 SQLite database；Attachment identifier 指向的實體檔案內容不在本 PR 範圍。

## 3. 完整性與格式 Gate

每個來源與 staging database 在 promotion 前都必須通過：

1. 可由 SQLite 以唯讀模式開啟。
2. `PRAGMA user_version = 2`。
3. Schema v2 的 13 張正式資料表全部存在。
4. `PRAGMA integrity_check` 唯一結果為 `ok`。
5. `PRAGMA foreign_key_check` 為空。
6. 來源與 staging 的 13 張表逐表筆數完全一致。

任一條件失敗時，目的資料不得被修改，也不得把不完整 staging 宣告為可還原備份。

## 4. Transaction、原子替換與 rollback

- 使用 SQLite Online Backup API 建立一致 snapshot；SQLite 對 destination backup 採交易式寫入。
- snapshot 先寫入與目的檔同目錄的隔離 staging file，不直接寫入正式目的檔。
- staging 完整驗證後才以同檔案系統原子 rename promotion。
- copy、驗證或 promotion 任一步失敗時刪除 staging；原目的檔保持原內容，不留下部分資料。
- 來源與目的相同、版本不支援、資料表缺漏、integrity／FK 異常或既有備份目的檔存在時，必須明確拒絕。

## 5. 防回歸 Gate

測試必須涵蓋：

- 完整 Schema v2 backup 的版本、資料表與 row count 驗證。
- 非 SQLite 格式與未知 `user_version` 在還原前被拒絕。
- 成功還原只在完整 staging 驗證後替換目的檔。
- 中途 snapshot 失敗時，既有目的資料完全不變且 staging 清除。
- promotion 失敗時，既有目的資料完全不變且 staging 清除。
- 建立備份不覆寫既有備份。

codegen 無差異、Analyze、全部 tests、Web／Android／iOS build 與 GitHub Actions 必須全綠後才可合併。

## 6. 明確未修改

- 不修改 UI、正式 SQLite 備份格式、Schema、Migration、Domain 或 Repository contract。
- 不把備份核心接入正式 Runtime，也不新增自動備份／自動還原產品功能。
- 不讀寫、刪除或覆蓋 SharedPreferences、`backup_v1_*` 或正式使用者資料。
- Item 仍是 Root；Task 仍是提醒；WorkCase 才是案件；WorkCaseClosure 才是正式結案；History 仍是唯讀投影。
