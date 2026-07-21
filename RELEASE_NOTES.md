# Life Management v0.5.34 Backup and Restore Core Safety Notes

日期：2026-07-21

## 本版內容

- 正式備份格式維持 Schema v2 SQLite database file，沒有新增 manifest、資料表或另一套資料來源。
- backup／restore 核心在 promotion 前驗證格式版本、13 張正式資料表、SQLite integrity、foreign key 與逐表筆數。
- SQLite snapshot 只寫入隔離 staging；完整驗證後才原子替換目的檔。
- snapshot 或 promotion 中途失敗時，staging 會清除，既有目的 database 保持原內容，禁止部分還原。
- 既有 backup file 不會被建立備份流程覆寫。

## 安全邊界

- 呼叫前必須先關閉 Drift database；本版沒有將備份／還原接進 UI 或正式啟動流程。
- `backup_v1_*` 繼續是 SharedPreferences 舊來源的唯讀回復證據，不是正式 Drift backup 的雙寫目的地。
- Attachment metadata 會包含於 SQLite backup，但 identifier 指向的實體檔案內容尚未宣告可跨裝置備份／還原。
- Task 保持提醒角色；WorkCase、WorkCaseClosure 與 History 的正式資料角色沒有改變。

## 發佈驗證

- Drift codegen 必須無差異。
- Flutter Analyze 與全部 tests 必須通過。
- Web／Android／iOS build 與 GitHub Actions 必須全綠。
- 格式錯誤、未知版本、copy 中斷與 promotion 失敗均必須由防回歸測試證明不會部分覆寫目的資料。

## 已知限制

- 本版沒有新增使用者可操作的備份／還原 UI 或自動排程。
- Web IndexedDB 的匯出／還原與 Attachment 實體檔案內容跨裝置備份不在本 PR 範圍。
- iPhone／Android 實體裝置仍依 Device Validation Checklist 個別簽核；平台 build 不等於真機完成。
- v0.5.34 不是 v1.0 正式產品版，也不代表正式 UI／UX 改版完成。
