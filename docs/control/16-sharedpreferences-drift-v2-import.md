# SharedPreferences → Drift Schema v2 安全匯入控制

狀態：正式控制文件
版本：v0.5.2
日期：2026-07-19
適用 PR：#203

## 1. 範圍與邊界

本機制只將 `items`、`schedules`、`tasks`、`maintenance_records` 四組 SharedPreferences JSON，在來源已停止寫入後，以單一 Drift transaction 匯入 Schema v2。

本 PR 不接入 Runtime、不切換 Repository、不改 UI、不修改 Schema 或 database migration，也不執行真機資料搬移。SharedPreferences 與 `backup_v1_*` 只透過不含寫入 API 的 `LegacyImportSource` 讀取；匯入器不刪除、不覆蓋、不回寫來源。

## 2. 匯入前准入

dry-run 與正式 execute 使用同一份 preparation：

- 四組來源逐一比對對應的不可變 `backup_v1_*` 原文。
- 保存每組原文的 SHA-256、UTF-8 byte length、raw／valid 來源筆數與目標預計筆數。
- 阻擋頂層 JSON 損壞、無法轉換的 entry、空 ID、重複 ID、非法數值、未知 enum、未知 catalog cardId、孤兒關聯與跨 Item 錯配。
- 正式 execute 必須由呼叫端明確確認 `sourceWritesAreDisabled`；否則不開啟 transaction。
- 匯入前先執行 `PRAGMA foreign_key_check` 與 `PRAGMA integrity_check`。

任何 blocker 都只形成報告，不修復或改寫來源。

## 3. 正式 mapping

### 3.1 Item 與分類

| 舊 ItemCategory | item_categories.systemCode | 顯示名稱 |
|---|---|---|
| appliance | homeAndAppliance | 家電與居家設備 |
| vehicle | vehicleAndTransport | 車輛與交通 |
| house | houseAndRepair | 房屋與修繕 |
| warrantyDocument | documentAndContract | 文件與合約 |
| other | other | 其他 |

分類 ID 為 `legacy-category-{舊 enum}`，時間取該分類最早 Item.createdAt。Item 欄位逐一保存；舊模型沒有 updatedAt，故以 createdAt 作為可重建的保守值。不得依名稱或備註猜測新分類。

若 v1 → v2 migration 曾為 WorkCase 建立完全符合正式 signature 的 placeholder Item，匯入器只更新該 placeholder 為來源 Item，WorkCase 與 WorkCaseUpdate 保持原 ID、關聯、筆數與內容。其他同 ID Drift row 一律視為衝突，禁止覆蓋。

### 3.2 Schedule 正式來源

- `manual-expiry-reminder`：每個舊 Schedule 建立一個 `GeneralReminder`，Schedule sourceType 為 `generalReminder`。
- 已知 MaintenanceCardCatalog cardId：每個舊 Schedule 建立一個內容與步驟快照 `MaintenancePlan`，Schedule sourceType 為 `maintenancePlan`。
- 未知 cardId：阻擋，不以 title 或 Item 名稱猜測。

舊 `strictPeriodMode` 不足以證明使用者選擇 completion-based。非 custom 週期一律映射正式預設 `fixedCalendarPeriod`；custom 週期映射 `userDefined` 並以原 nextDueDate 保存 userDefinedNextDate。不得自行產生 completionBased。

### 3.3 Task

Task 仍只是某一次提醒：依來源 Schedule 映射為 `scheduledMaintenance` 或 `scheduledReminder`，保存原 scheduleId、cardId、title、dueDate、status、completedAt 與 postponedAt。舊 scheduleId 為空時，不猜測它是手動建立或哪一種正式來源，改以 `sourceType = unknown`、nullable scheduleId 保存。舊模型沒有 createdAt／updatedAt，故 createdAt 使用 dueDate，updatedAt 使用 completedAt、postponedAt、dueDate 中第一個可用值。`overdue` 是可重建狀態，不寫成另一份永久真相。

匯入器不由 Task 建立 WorkCase，不由完成 Task 建立 History，也不建立 WorkCaseClosure。

### 3.4 MaintenanceRecord 與照片

MaintenanceRecord 逐欄保存，`partsChanged` 使用 JSON array 字串。若 record 的 task 來自保養 Schedule，補上該確定的 maintenancePlanId；不將舊 Record 偽造成 WorkCase 或 Closure。

Item.photoPath 與 MaintenanceRecord.photos 各自轉成確定性 ID 的 Attachment。storageIdentifier 使用 `legacy-unverified:{來源識別 SHA-256}`，原字串只保留在明確標示未驗證的來源 note，不把平台路徑冒充永久檔案位置；state 為 `unknown`、MIME／content hash／verifiedAt 皆不捏造。後續檔案驗證必須是另一個經批准流程。

## 4. Transaction、完整性與 rollback

寫入順序為 Category → Item → MaintenancePlan／Step → GeneralReminder → Schedule → Task → MaintenanceRecord → Attachment，全部位於同一 transaction。

commit 前重新逐列比對 ID 與內容，並再次執行 foreign key check 與 integrity check。任何 insert、constraint、比對或完整性錯誤會使整個 transaction rollback；SharedPreferences 與備份從未被修改，正式 Runtime 仍可繼續使用舊來源。

本 PR 不提供 commit 後的破壞性刪除。正式 Runtime 尚未切換，若驗收不通過應丟棄該隔離 Drift database 或 roll-forward；不得刪除來源，也不得誤刪 v1 → v2 migration 已保留的案件資料。

## 5. 重複匯入保護

本 PR 不新增 marker table。所有衍生 ID 與欄位皆可由來源確定重建：

- 所有預期 row 都存在且逐欄相同：回報 `alreadyImported`，零寫入。
- 全部不存在（允許正式 v1 placeholder）：回報 `ready`。
- 只有部分存在、或同 ID 內容不同：回報 blocker，禁止 silent upsert、補寫或覆蓋。

這使重跑可驗證且不產生重複資料，也避免以新 Schema 或平行 import ledger 擴大 PR 範圍。

## 6. 驗收與未開放事項

測試至少涵蓋 dry-run 零寫入、完整 mapping、來源／備份異常、未知 card、來源未凍結、重複執行、目標衝突、transaction 中途失敗 rollback、v1 placeholder 合併與 WorkCase 保留、FK 與 integrity。

本機制目前沒有 Runtime 呼叫點。正式匯入、mutation gate、Repository composition root 切換、read-only shadow、真機資料驗證與 Drift writer 開啟都不屬於 PR #203，未經後續單一 PR 批准不得開始。
