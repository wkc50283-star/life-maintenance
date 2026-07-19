# Legacy Runtime 最終稽核與退休 Gate

狀態：正式控制文件
版本：v0.5.10
日期：2026-07-19
適用 PR：#211

> 歷史稽核：本文件保留 v0.5.10／PR #211 當時的 blocker 與證據。PR #212 已解除 MaintenanceRecord Local read 及 Legacy writer fallback 阻擋；v0.5.11 現行 Runtime、rollback 與 Gate 規則以 `24-drift-safe-runtime-and-maintenance-record-read-cutover.md` 為準。

## 1. 結論

本次依 `lib/main.dart` 正式入口，完整掃描 `lib/app`、`lib/screens`、`lib/widgets`、`lib/services`、`lib/repositories` 與全部 `test`。

退休 Gate 結論：**尚未通過，不得刪除 Legacy Runtime。**

- 成功 cutover 後，Drift 是 Item／Planning／Task／WorkCase／WorkCaseClosure／MaintenanceRecord／Attachment 的唯一正式 domain writer。
- SharedPreferences domain keys 與 `backup_v1_*` 不會被 mirror、雙寫、刪除或覆蓋；舊 Repository write/remove 由同一 `LocalStorageService` 唯讀 Gate 阻擋。
- 每次冷啟動仍讀取舊來源與不可變備份，用於完整性、匯入身分及 rollback admission 驗證；驗證成功後維持 Drift Runtime，不是資料畫面 fallback。
- 驗證失敗時才恢復完整 Legacy Runtime 與 writer，且不注入部分 Drift Runtime。
- `ItemsScreen`、`HistoryScreen` 仍以 `MaintenanceRecordLocalRepository` 讀取舊完成紀錄；新增 Item／補登紀錄 Widget 仍保留 legacy write 程式碼，但成功 cutover 後入口關閉且底層 Gate 再次阻擋。

因此本 PR 只建立證據、分類與防回歸 Gate，不移除舊程式，也不宣稱 Legacy 已退休。

## 2. 正式入口與 Composition Root

| 檔案 | 依賴／行為 | 分類 | 退休判定 |
|---|---|---|---|
| `lib/main.dart` | 只建立或接收 `AppCompositionRoot`，不建立 Repository、LocalStorageService 或 SharedPreferences | 正式 Runtime 已無直接引用 | 可維持 |
| `lib/app/app_composition_root.dart` | 唯一建立 `LocalStorageService`、四個 LocalRepository、AppDatabase 與 Drift Runtime；先備份／解析／凍結來源，再匯入及切換 | 僅供唯讀備份與回復；失敗時為 Legacy Runtime | 尚不可移除 |
| `lib/services/local_storage_service.dart` | `lib` 中唯一匯入 SharedPreferences；所有 save/remove 共用 writesEnabled Gate | 唯讀來源 abstraction／rollback writer | 尚不可移除 |

正式畫面與 Widget 均未直接呼叫 `SharedPreferences.getInstance()`，也未自行建構 LocalStorageService 或任何 LocalRepository。

## 3. 畫面與 Widget 全量分類

### 3.1 正式 Runtime 已無 Local 具體依賴

| 範圍 | 正式依賴 | 結論 |
|---|---|---|
| `lib/screens/today_screen.dart` | `ItemReadRepository`、`ScheduleRepository`、`TaskRepository` | cutover 後全部由 Drift adapter 提供；沒有 Task 直接完成或 MaintenanceRecord 舊寫入 |
| `lib/widgets/expiry_reminder_preview_sheet.dart` | Composition Root 的 Schedule／Planning contract | cutover 後 GeneralReminder + Schedule 寫入 Drift transaction |
| `lib/widgets/reminder_list_sheet.dart` | `ScheduleRepository`／`TaskRepository` abstraction | cutover 後只寫 Drift，沒有 Local 具體類型 |
| WorkCase、History Projection、Attachment Runtime | Composition Root 正式 abstraction | 沒有 SharedPreferences 寫入或平行 History writer |
| 其他 screen／widget | UI／domain presentation | 沒有 legacy persistence 物件建構 |

### 3.2 尚不可移除的正式程式引用

| 檔案 | 引用 | 現況與風險 | 退休前必要條件 |
|---|---|---|---|
| `lib/screens/items_screen.dart` | `MaintenanceRecordLocalRepository` | Item／Schedule／Task 已正式切換，但完成紀錄仍從舊來源讀取 | Item Detail 改用正式 MaintenanceRecord／History Projection read contract 並驗收 |
| `lib/screens/history_screen.dart` | `MaintenanceRecordLocalRepository` | 畫面仍只呈現舊完成紀錄，尚未接正式 History Projection | History 畫面切換後比對舊紀錄、案件、附件與排序 |
| `lib/widgets/add_item_preview_sheet.dart` | `root.itemRepository` | 保留 legacy writer；成功 cutover 時 AddScreen 關閉入口，底層 Gate 仍阻擋 | 正式 Item mutation Repository 與 UI 接線完成前不得刪除或重新開放 |
| `lib/widgets/maintenance_record_preview_sheet.dart` | `root.maintenanceRecordRepository` | 保留 legacy writer；成功 cutover 時入口關閉，底層 Gate 仍阻擋 | 接正式 `createSimpleRecord` 並驗證案件分流後才能移除 |

上述四個檔案是本次靜態防回歸測試鎖定的已知清單。新增第五個 legacy UI 引用會直接使測試失敗。

## 4. Service 與 Repository 全量分類

| 檔案／群組 | 用途 | 分類 | 退休判定 |
|---|---|---|---|
| `item_local_repository.dart` | Legacy Item 解析、失敗回復與尚未切換的舊 Item mutation 程式 | rollback／尚存 UI writer | 尚不可移除 |
| `schedule_local_repository.dart` | 匯入前解析與完整 Legacy rollback | rollback | 尚不可移除 |
| `task_local_repository.dart` | 匯入前解析與完整 Legacy rollback | rollback | 尚不可移除 |
| `maintenance_record_local_repository.dart` | 匯入前解析、rollback、Items／History read 與舊補登程式 | 正式 UI 尚有 read 引用 | 尚不可移除 |
| `local_data_integrity_service.dart` | 收集逐筆解析問題並在異常時阻擋四個 LocalRepository writer | 匯入前／rollback 安全 Gate | 尚不可移除 |
| `local_data_backup_service.dart` | 只在備份不存在時複製原始字串，不覆寫既有備份 | 唯讀保護準備；唯一例外是建立不可變 backup key | 尚不可移除 |
| `legacy_drift_import_service.dart` | 透過只讀 `LegacyImportSource` 驗證來源、備份與確定性 mapping | 唯讀匯入來源 | 尚不可移除 |
| `legacy_relation_audit_service.dart` | 只讀關聯稽核 | 唯讀備份／回復驗證 | 尚不可移除 |
| `migration_readiness_service.dart` | 只讀來源、備份與 Drift counts | 唯讀 admission 證據 | 尚不可移除 |
| `migration_admission_service.dart` | 組合 readiness／relation blockers，不直接存取 SharedPreferences | admission Gate | 尚不可移除 |
| Drift repositories／runtimes | 正式 domain CRUD、transaction 與 projection | 正式 Runtime 已無 Local 引用 | 正式 writer |

`LocalStorageService.remove()` 仍沒有正式 production 呼叫點；只在測試驗證唯讀 Gate。不得因方法存在而解讀為正式刪除流程。

其餘 `lib/services` 與正式 Repository 沒有 SharedPreferences／LocalStorageService／LocalRepository 具體依賴；`MaintenanceTaskService` 只處理傳入的 domain schedule／task，沒有 persistence API。

## 5. 測試依賴分類

測試中的 SharedPreferences／Local 類別引用均屬相容、匯入、rollback、既有 UI 行為或 Gate 驗證，不是正式 writer：

| 類別 | 測試檔案 |
|---|---|
| Composition／冷啟動／唯一 writer | `test/app/app_composition_root_test.dart`、`test/architecture/legacy_runtime_retirement_gate_test.dart`、`test/today_screen_task_runtime_test.dart`、`test/widget_test.dart` |
| 舊解析與 write-lock | `test/repositories/local_data_integrity_test.dart`、`test/services/local_data_backup_service_test.dart` |
| 匯入／readiness／relation／admission／rollback | `test/services/legacy_drift_import_service_test.dart`、`legacy_relation_audit_service_test.dart`、`migration_readiness_service_test.dart`、`migration_admission_service_test.dart` |
| 尚未切換的 UI／Widget 相容測試 | `test/history_screen_test.dart`、`item_detail_sheet_test.dart`、`expiry_reminder_preview_sheet_test.dart`、`reminder_list_sheet_test.dart`、`honest_ui_test.dart` |
| 測試注入 | `test/flutter_test_config.dart` 以 `LegacyRuntimeDependencies` 提供隔離的既有 Widget 測試依賴 |

這些測試必須在對應正式 UI read/mutation 完成且另有 Drift 測試替代後，才可分批退休；不得一次刪除以製造「零引用」。

## 6. 單一 writer 與冷啟動證據

防回歸測試正式鎖定：

1. `lib` 只有 `local_storage_service.dart` 可直接 import SharedPreferences。
2. screen／widget 不得建構 SharedPreferences、LocalStorageService 或 LocalRepository。
3. 成功 cutover 後 `legacyWritesEnabled == false`，舊 Item／MaintenanceRecord save 必須拋出 `LegacyStorageReadOnlyException`。
4. 正式 MaintenanceRecord 寫入 Drift 前後，四個來源 key 與四個 backup key 原文完全相同。
5. 同一 database 冷啟動重新執行 admission 後仍為 `driftMaintenanceRecords`，且只存在 Drift 的新正式紀錄仍可讀；不得 fallback 到舊來源。
6. 來源／備份不一致時，Runtime 必須完整回到 `legacy`，所有正式 Drift Runtime 為 null、legacy writer 恢復、Drift Item 零寫入且來源原文不變。

冷啟動讀取舊來源是 admission 驗證，不等於把舊來源重新設為正式 read model。只有 `RuntimeDataMode.legacy` 才是 rollback fallback。

## 7. 退休 Gate

### 已通過

- [x] SharedPreferences 只有一個 production abstraction。
- [x] 正式畫面／Widget 不自行建立儲存或 Repository。
- [x] 成功 cutover 後 Drift 是唯一正式 domain writer。
- [x] 無 SharedPreferences／Drift 雙寫。
- [x] 冷啟動通過 admission 後維持 Drift Runtime。
- [x] blocked import／admission 完整 rollback，不進入部分 cutover。
- [x] Legacy source 與不可變備份不刪除、不覆蓋。

### 尚未通過

- [ ] ItemsScreen 完成紀錄讀取切換至正式 Drift read contract。
- [ ] HistoryScreen 切換至正式 History Projection。
- [ ] 新增 Item UI 接正式 Drift mutation。
- [ ] 補登簡單完成 UI 接正式 MaintenanceRecord Repository，並保留 WorkCase 分流。
- [ ] 真機 recovery drill 證明可由保留來源回復。
- [ ] 上述切換完成後再證明 production code 對四個 LocalRepository 零引用。

任一未通過項存在時，不得刪除 LocalRepository、LocalStorageService、SharedPreferences source、`backup_v1_*` 或 LegacyRuntimeDependencies。

## 8. 本 PR 明確未修改

- 不刪除 Legacy Runtime、Repository、Service、來源 key 或備份。
- 不修改 UI、Schema、Migration、匯入 mapping 或正式 CRUD。
- 不搬資料、不新增功能、不建立第二套 writer／History／rollback 流程。
- 不開始下一個 PR。
