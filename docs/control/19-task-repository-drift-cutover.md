# Task Repository Drift 切換

狀態：正式控制文件
版本：v0.5.6
日期：2026-07-19
適用 PR：#207

## 1. 正式範圍

只有當 AppCompositionRoot 完成舊來源驗證，且匯入器回報 `imported` 或 `alreadyImported`，Task Runtime 才切換至 Drift Repository。SharedPreferences Task 只作匯入、備份與失敗回復來源，不再是正式 Runtime writer。

本版本不切換 MaintenanceRecord、WorkCase 或 WorkCaseClosure，不修改 Schema、Migration、UI 視覺或正式功能。

## 2. Task 的正式角色

- Task 只代表某一次提醒實例，不保存案件過程或正式結案。
- Schedule 是產生規則，Task 是規則產生的實例，兩者不得混用。
- Task 不得直接完成成 MaintenanceRecord；使用者開始處理後的正式生命週期屬於後續 WorkCase／WorkCaseClosure。
- History 仍由正式資料投影，不建立 Task History writer。

## 3. 來源契約

正式 Runtime 只從有效 Schedule 產生 Task：

- MaintenancePlan Schedule → `scheduledMaintenance` Task。
- GeneralReminder Schedule → `scheduledReminder` Task。
- Milestone Schedule → `milestone` Task。

Task、Schedule 與來源必須隸屬同一 Item，且 source FK 必須完全一致。`unknown` 只允許保留舊匯入資料，不得用於新 Task；Runtime 也不得以沒有 Schedule 的 manual Task 繞過正式來源。

## 4. Transaction、去重與 rollback

- 一批到期 Task 在單一 Drift transaction 內寫入。
- 相同 `scheduleId + dueDate` 只能存在一筆；Runtime 先做 idempotent 檢查，Schema v2 unique index 是最後防線。
- 同批輸入含重複 composite key 時整批拒絕。
- 任一 Schedule 缺失、跨 Item 或 source 不一致時整批 rollback，不允許部分產生。
- Runtime 不提供 Task completion 或 MaintenanceRecord 寫入 API。

## 5. 單一 writer

- 切換成功後 Task 的唯一正式 writer 是 Drift。
- SharedPreferences 與 `backup_v1_*` 不得刪除、覆蓋、mirror 或 fallback 寫入。
- 啟動失敗時才回到完整 legacy Runtime；不得同時對 Drift 與 SharedPreferences 雙寫。

## 6. 驗收

- 三種 Schedule source mapping 與跨 Item／來源約束。
- `scheduleId + dueDate` idempotency、同批重複拒絕與 database unique 防線。
- 多筆產生 transaction 失敗 rollback。
- 首頁讀取正式 Drift Task，且不出現直接完成入口或建立 MaintenanceRecord。
- SharedPreferences 原文與不可變備份零寫入。
- codegen、Analyze、全部 tests、Web release build、CI 與 Web 預覽通過。
