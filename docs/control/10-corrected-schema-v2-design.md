# 生活管理 App 修正版 Drift Schema v2 設計

狀態：正式施工前設計  
版本：v0.5.0  
日期：2026-07-18

## 1. 目的

本文件定義 schema v1 → v2 的正式資料表、關聯、限制與 migration 前置條件，避免再次把舊 MVP 的 `Item → Schedule → Task → MaintenanceRecord` 直接當成最終產品架構。

本文件合併時不得同時修改資料庫程式、執行 migration、匯入 SharedPreferences 或接入 UI。

## 2. Schema v2 資料表

### 2.1 `items`

保存生活項目。

必要欄位：

- `id` primary key
- `name`
- `category`
- `photoPath`
- `createdAt`
- `purchaseDate`
- `warrantyEndDate`
- `expectedLifeYears`
- `location`
- `note`
- `status`

限制：

- `expectedLifeYears` 可空；有值時必須大於 0。
- 有 Schedule、Task、MaintenanceRecord、MaintenancePlan 或 WorkCase 關聯時，不得直接實體刪除。
- 一般停用應改為 paused 或 archived。

### 2.2 `maintenance_plans`

保存使用者真正建立的長期保養項目。

必要欄位：

- `schemaVersion`
- `id` primary key
- `itemId` foreign key → `items.id`
- `templateCardId` nullable；只記錄建立來源
- `title`
- `planType`
- `description`
- `riskLevel`
- `estimatedMinutes`
- `requiredPhotos`
- `requiredNote`
- `safetyNotice`
- `status`
- `createdAt`
- `updatedAt`
- `archivedAt`

限制：

- `estimatedMinutes` 可空；有值時必須大於 0。
- `templateCardId` 不建立外鍵，因模板不是使用者持久化資料。
- Item 刪除採 restrict。
- archived 狀態保留歷史與排程關聯。

### 2.3 `maintenance_plan_steps`

保存保養項目建立當下的步驟快照。

必要欄位：

- `id` primary key
- `maintenancePlanId` foreign key → `maintenance_plans.id`
- `stepOrder`
- `title`
- `description`
- `isRequired`
- `photoRequired`
- `noteRequired`

限制：

- `stepOrder >= 0`。
- 同一 MaintenancePlan 內 `(maintenancePlanId, stepOrder)` 必須唯一。
- MaintenancePlan 實體刪除時可 cascade 刪除尚未產生歷史引用的步驟；正式刪除 API 仍需先檢查關聯。
- 模板更新不得直接更新此表。

### 2.4 `schedules`

Schedule 只保存時間規則，來源必須誠實表達。

正式來源欄位：

- `sourceType = maintenancePlan | generalReminder`
- `maintenancePlanId` nullable foreign key → `maintenance_plans.id`
- `itemId` foreign key → `items.id`

其餘欄位：

- `id` primary key
- `legacyCardId` nullable；只為舊資料相容保留
- `cycleType`
- `interval`
- `startDate`
- `nextDueDate`
- `title`
- `reminderTime`
- `status`
- `strictPeriodMode`
- `createdAt`
- `updatedAt`

來源限制：

- `sourceType = maintenancePlan` 時，`maintenancePlanId` 必填。
- `sourceType = generalReminder` 時，`maintenancePlanId` 必須為空。
- `itemId` 永遠必填，作為穩定生活項目關聯。
- `interval > 0`。
- 不再以空字串或特殊 `cardId` 作為正式來源。

### 2.5 `tasks`

Task 只代表某一次提醒實例。

必要欄位：

- `id` primary key
- `itemId` foreign key → `items.id`
- `scheduleId` nullable foreign key → `schedules.id`
- `maintenancePlanId` nullable foreign key → `maintenance_plans.id`
- `legacyCardId` nullable
- `title`
- `dueDate`
- `status`
- `completedAt`
- `postponedAt`
- `overdue`
- `createdAt`

限制：

- 由 Schedule 產生時 `scheduleId` 必填。
- 手動一次性 Task 可沒有 scheduleId。
- 不得用空字串偽裝 nullable foreign key。
- MaintenancePlan 關聯只在保養任務時保存；一般提醒可空。

### 2.6 `maintenance_records`

保存舊完成紀錄與未升級為 WorkCase 的簡單完成結果。

必要欄位沿用現有模型：

- `id` primary key
- `itemId` foreign key → `items.id`
- `taskId` nullable foreign key → `tasks.id`
- `recordType`
- `date`
- `title`
- `issueDescription`
- `workDescription`
- `partsChanged`
- `cost`
- `vendorName`
- `warrantyUntil`
- `result`
- `photos`
- `note`
- `createdAt`

限制：

- `taskId` 可空，支援補登完成紀錄。
- 不新增 `workCaseId`，避免把舊完成紀錄混入案件事實來源。
- partsChanged 與 photos 先以 JSON text 保存；照片檔仍由檔案層管理。

### 2.7 `work_cases` 修正

schema v2 必須讓 `work_cases.itemId` 正式關聯 `items.id`。

SQLite 無法直接在既有欄位補 foreign key，因此必須：

1. 建立 `work_cases_v2`。
2. 建立正式 itemId foreign key。
3. 驗證舊表為空或所有 itemId 已有對應 Item。
4. 複製資料。
5. 重建 work_case_updates foreign key 關聯。
6. 替換舊表。
7. 驗證筆數與外鍵完整性。

## 3. Migration 前置條件

由於現行 App 尚未使用 Drift 寫入案件，正式 migration 預期 v1 的：

- `work_cases`
- `work_case_updates`

皆為空。

migration 開始前必須查詢兩表筆數：

- 若兩表皆為 0，可進行表重建。
- 任一表非 0，migration 必須停止並回報，不得猜測、補造或刪除資料。

不得因「理論上應該是空的」而省略檢查。

## 4. Schema v1 → v2 順序

```text
確認 foreign_keys=ON
→ 檢查 work_cases／work_case_updates 為空
→ 建立 items
→ 建立 maintenance_plans
→ 建立 maintenance_plan_steps
→ 建立 schedules
→ 建立 tasks
→ 建立 maintenance_records
→ 重建 work_cases 並加入 itemId foreign key
→ 重建 work_case_updates foreign key
→ 建立索引
→ 驗證 schema
→ 驗證所有 foreign key
→ transaction commit
```

任一步驟失敗必須完整 rollback。

## 5. 刪除與封存政策

- Item：優先封存；有任何歷史、案件或規則時禁止實體刪除。
- MaintenancePlan：優先封存；有 Schedule、Task 或歷史時禁止實體刪除。
- Schedule：可 ended，不應因停止提醒而刪除歷史來源。
- Task：完成、取消或延期皆保留。
- MaintenanceRecord：不可因來源 Task 被刪除而消失；正式 API 不提供一般實體刪除。
- WorkCase／WorkCaseUpdate：結案後唯讀，不提供一般實體刪除。

資料庫 foreign key 是最低安全線，Repository 還需實作更嚴格的封存規則。

## 6. 索引基線

至少建立：

- items `(category, status)`、`createdAt`
- maintenance_plans `(itemId, status)`、`updatedAt`
- maintenance_plan_steps `(maintenancePlanId, stepOrder)` unique
- schedules `(itemId, status)`、`maintenancePlanId`、`nextDueDate`
- tasks `(itemId, status)`、`scheduleId`、`dueDate`
- maintenance_records `(itemId, date)`、`taskId`
- work_cases `(itemId, status)`、`updatedAt`
- work_case_updates `(workCaseId, occurredAt)`

## 7. 測試要求

schema v2 PR 必須包含：

- 全新資料庫建立測試
- v1 → v2 migration 測試
- v1 目標表非空時拒絕 migration
- migration rollback 測試
- Item foreign key 測試
- MaintenancePlan 與 steps 關聯測試
- Schedule sourceType 約束測試
- Task nullable scheduleId 測試
- MaintenanceRecord nullable taskId 測試
- WorkCase itemId foreign key 測試
- native schema 驗證
- Web build 與 WASM／worker 資產驗證

## 8. 明確不包含

schema v2 PR 不得同時：

- 匯入 SharedPreferences
- 切換現有 Repository
- 讓 UI 開啟 Drift
- 建立 MaintenancePlan UI
- 把 MaintenanceRecord 轉成 WorkCase
- 刪除 `backup_v1_*`
- 停止舊資料來源

## 9. 舊草稿處理

舊 `database/core-schema-v2` 分支只保留為稽核證據：

- enum converter 可重新評估後重寫。
- Items table 可參考欄位，但需加入正式限制。
- Schedules table 因缺少 MaintenancePlan 與來源角色，不得合併或直接 cherry-pick。

正式施工必須由最新 main 建立新分支，不在舊草稿上繼續追加。
