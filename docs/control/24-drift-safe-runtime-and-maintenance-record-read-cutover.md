# Drift 安全 Runtime 與 MaintenanceRecord 讀取切換

狀態：正式控制文件
版本：v0.5.11
日期：2026-07-19
適用 PR：#212

## 1. 正式結論

Items／History 的 MaintenanceRecord 讀取統一經由 `MaintenanceRecordRepository`，成功 admission 後由 Drift Runtime adapter 提供。正式 screen／widget 不得依賴或建構 `MaintenanceRecordLocalRepository`。

啟動備份、完整性檢查或匯入 admission 任一步失敗時，Runtime 必須進入 Drift 唯讀安全狀態：可讀既有 Drift Item、Schedule、Task、MaintenanceRecord 與 History Projection，但所有正式 mutation 及 Legacy storage mutation 均被阻擋。不得恢復 SharedPreferences／LocalRepository writer。

## 2. 單一 writer 與來源規則

- admission 成功時，Drift 是唯一正式 domain writer。
- admission 失敗時沒有正式 writer；Drift 只讀，Legacy storage 同時保持唯讀。
- SharedPreferences domain keys 與 `backup_v1_*` 僅供匯入身分、稽核與人工回復證據，不是 Runtime read model。
- 不 mirror、不雙寫、不刪除、不覆蓋舊來源或不可變備份。
- Legacy Repository、Service 與解析程式本版保留，但不得由正式畫面取得 MaintenanceRecord 資料或恢復寫入。

## 3. MaintenanceRecord 正式邊界

- `listAll`、`listForItem` 與 `findById` 是正式 read contract；Items／History 不再呼叫 LocalRepository 的 `loadRecords`。
- `createSimpleRecord` 只保存不需案件過程的簡單完成事實。
- 需要過程與正式結案的事件仍必須走 WorkCase → WorkCaseUpdate → WorkCaseClosure。
- Task 仍只是提醒；MaintenanceRecord 不取代 WorkCaseClosure，History 仍只是正式資料的唯讀投影。
- Drift 唯讀安全狀態下，MaintenanceRecord、Schedule、Task 的 mutation contract 必須明確拒絕，不得暗中寫回舊來源。

## 4. Rollback 與安全狀態

本版所稱 rollback 是「資料交易 rollback 後留在 Drift 安全狀態」，不是切回 Legacy Runtime：

1. 匯入 transaction 失敗時由既有 importer 完整 rollback。
2. Composition Root 關閉 Legacy storage writer。
3. Item、Schedule、Task、MaintenanceRecord 與 History 從 Drift 讀取。
4. 正式 mutation 入口關閉；WorkCase／Attachment mutation Runtime 不注入。
5. SharedPreferences 與 `backup_v1_*` 原文保留，供後續受控診斷或人工回復，不自動成為 writer。

備份建立本身失敗也適用相同安全狀態，避免在安全準備不完整時繼續修改任何正式或舊資料。

## 5. Retirement Gate

PR #212 解除 v0.5.10 所列兩項正式阻擋：

- ItemsScreen／Item Detail 的 MaintenanceRecord 已切至正式 Drift read contract。
- HistoryScreen 的 MaintenanceRecord 已切至正式 Drift read contract，且正式 UI 不再引用 `MaintenanceRecordLocalRepository`。

因此正式 Runtime 不再以 Legacy writer 作 rollback，MaintenanceRecord Local read blocker 已退休。仍保留的 Legacy 類別、舊解析與既有 dormant UI 程式只可服務唯讀備份／回復與後續分階段清理；本 PR 不刪除它們，也不重新開放已關閉的舊寫入入口。

## 6. 防回歸驗收

- screen／widget 不得出現 `MaintenanceRecordLocalRepository` 依賴或自行建立 persistence 物件。
- Drift-only MaintenanceRecord 必須同時出現在 Items detail 與 History。
- 來源／備份不一致、備份失敗或 import 失敗時，Runtime mode 必須為 `driftSafeReadOnly`。
- 安全狀態仍讀取既有 Drift rows；Schedule、Task、MaintenanceRecord 與 Legacy storage mutation 均失敗。
- 成功 cutover、冷啟動及正式 MaintenanceRecord 寫入前後，SharedPreferences domain keys 與 `backup_v1_*` 原文完全相同。
- codegen、Analyze、全部 tests、Web release build、GitHub Actions 與預覽驗證全部通過後才可合併。

## 7. 明確未修改

- 不刪除 Legacy Repository、Service、SharedPreferences source 或 `backup_v1_*`。
- 不修改 UI 視覺、Schema、Migration、匯入 mapping 或 Domain role。
- 不新增功能、不建立平行 History／Task／WorkCase／Closure／Attachment 流程。
- 不開始下一個 PR。
