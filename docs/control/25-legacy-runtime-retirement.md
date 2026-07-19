# Legacy Runtime 正式退休

狀態：正式控制文件
版本：v0.5.12
日期：2026-07-19
適用 PR：#213

## 1. 正式結論

Legacy Runtime 已退休。正式 `lib/main.dart` 與 `AppCompositionRoot` 只建立 AppDatabase、Drift Schema v2 Repository 與正式 Runtime；正常冷啟動不讀取 LocalRepository 或 SharedPreferences business keys，也不執行 Legacy fallback。

Drift 是 Item、MaintenancePlan、GeneralReminder、Milestone、Schedule、Task、MaintenanceRecord、WorkCase、WorkCaseUpdate、WorkCaseClosure、Attachment 與 History Projection 的唯一正式資料來源。History 仍是投影，不新增 writer 或資料表。

## 2. 正式 Runtime 禁止事項

- `lib/main.dart`、`lib/app`、screen 與 widget 不得 import、建立或持有 LocalRepository、LocalStorageService、SharedPreferences 或 Legacy importer。
- AppRuntimeDependencies 不得暴露 Legacy repository、backup service、integrity service、writer 狀態或 fallback mode。
- 正式操作不得讀寫 `items`、`schedules`、`tasks`、`maintenance_records` SharedPreferences business keys。
- 不得因 Drift 錯誤自動切回 Legacy read model 或 writer。
- 不得用測試相容層、備份工具或 importer 冒充正式 Runtime dependency。

## 3. 保留的 Legacy recovery 邊界

舊資料不刪除。下列能力保留，但只能由明確、受控的匯入、稽核或災難回復流程呼叫：

- `LocalStorageService.readString`：唯讀取得舊 business keys 與 `backup_v1_*`。
- `writeBackupIfAbsent`：只接受 `backup_v1_*` key，只在缺少時建立，永不覆寫。
- 四個 LocalRepository：只保留逐筆相容解析與 read API，不實作正式 mutable Repository contract。
- `LegacyDriftImportService`：來源使用不含 writer 的 `LegacyImportSource`，目標寫入仍由單一 Drift transaction、重跑保護、FK 與 integrity 驗證控制。
- relation audit、readiness 與 admission service：只讀來源並形成報告。

這些工具不是 normal startup dependency，也不得由 UI 直接呼叫。若需實際災難回復，必須先保留 Drift database、舊 business keys 與 `backup_v1_*` 原文，再依受控 runbook 執行 dry-run、比對及人工批准；禁止自動覆蓋任一來源。

## 4. Writer 退休規則

Legacy production code 不再提供：

- generic `saveString`／`remove`
- writer enable／disable toggle
- Item／Schedule／Task／MaintenanceRecord 的 LocalRepository save／create／complete API
- LegacyRuntimeDependencies 或 RuntimeDataMode.legacy

測試若需要驗證舊 Widget 行為，只能使用 `test/` 下的相容 dependency，不得把測試 writer 移回 `lib/`。

## 5. 資料安全

- 不刪除或覆蓋 SharedPreferences business keys、`backup_v1_*` 或任何 Drift row。
- 本 PR 不修改 Schema、Migration、匯入 mapping 或既有資料。
- 正常 Runtime 不會把空的 Legacy source 當作清空 Drift 的指令。
- Recovery importer 仍禁止 silent upsert、部分匯入、跨 Item 關聯錯配或由 Task／MaintenanceRecord 偽造案件與史略。
- Task 仍只是提醒；WorkCase 才是案件；WorkCaseClosure 才是正式結案；History 仍是投影。

## 6. 防回歸 Gate

- 靜態掃描正式入口、app、screen 與 widget，Local／SharedPreferences persistence reference 必須為零。
- Legacy storage 與 LocalRepository 不得出現 business writer API。
- 正式 Root 即使面對損壞或不一致的 Legacy source，也只讀取既有 Drift 資料，且來源原文不變。
- 冷啟動與重啟後 Drift 新資料持續存在，不 fallback。
- `backup_v1_*` 限定 writer 必須拒絕 business key 並禁止覆寫既有備份。
- Legacy read-only source、backup、dry-run importer、audit、readiness 與 admission 測試持續通過。
- codegen、Analyze、全部 tests、Web release build、GitHub Actions 全綠後才可合併。

## 7. 明確未修改

- 不刪除舊使用者資料或 `backup_v1_*`。
- 不修改 UI 視覺、導覽、Schema、Migration、Domain 或匯入 mapping。
- 不新增產品功能、資料表、平行流程或下一個 PR。
