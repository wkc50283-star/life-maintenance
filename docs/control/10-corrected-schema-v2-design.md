# 生活管理 App｜Drift Schema v2 正式設計

狀態：重新稽核候選，不代表已批准施工  
版本：v0.5.0 Foundation  
日期：2026-07-18

## 1. 文件目的

本文件定義生活管理 App 的 Drift Schema v2 資料責任、資料表、關聯、限制、刪除政策、遷移閘門與測試要求。

Schema v2 必須承接正式產品生命週期：

```text
Item
├─ MaintenancePlan ─ Schedule ─ Task
├─ GeneralReminder ─ Schedule ─ Task
├─ Milestone ─ Task／WorkCase
└─ WorkCase ─ WorkCaseUpdate ─ WorkCaseClosure ─ 史略
```

本 App 不是 PMS、To-do List、打卡 App 或提醒 App。資料庫不得以「今日任務」為中心，也不得把 Schedule、Task、MaintenanceRecord 或模板誤當成生活管理的核心。

本文件只批准設計方向。合併本文件時仍不得：

- 新增或修改 Drift table 程式。
- 修改 `AppDatabase.schemaVersion`。
- 執行 v1 → v2 migration。
- 匯入 SharedPreferences。
- 切換 Repository。
- 將正式 UI 接上 Drift。
- 修改或刪除任何既有使用者資料。

## 2. 不可違反的資料角色

### 2.1 Item

生活項目是根物件，承接家電、房屋、車輛、寵物、健康、家人、財務、工作、學習、文件、合約、保固及其他生活內容。

### 2.2 MaintenancePlan

使用者真正建立並長期管理的保養項目。系統模板只提供建立來源，不是使用者的持久資料。

### 2.3 GeneralReminder

一般生活提醒的正式內容來源。Schedule 只保存時間規則，不能同時扮演提醒內容。

### 2.4 Schedule

只保存時間、週期與下一次到期規則。固定週期預設不因延遲完成而漂移。

### 2.5 Task

只代表某一次提醒實例。Task 不等於案件，也不得直接被當成完整史略。

### 2.6 Milestone

代表階段性重點、大修、重大檢查、汰換評估、續約、照護轉換或使用者自訂的重要節點。條件達成不等於事情完成。

### 2.7 WorkCase

代表事情已開始發生或使用者正式開始處理。突發修理、工程、異常、重大辦理事項均由 WorkCase 承接。

### 2.8 WorkCaseUpdate

保存案件過程中的每一筆事實，不覆寫過去紀錄。

### 2.9 WorkCaseClosure

保存使用者正式確認的結案結果。不得由系統從 WorkCaseUpdate 自動猜測。

### 2.10 MaintenanceRecord 與史略

`maintenance_records` 只承接舊完成紀錄及不需案件流程的簡單完成結果。正式案件的歷史事實來源是 WorkCase、WorkCaseUpdate 與 WorkCaseClosure。

「史略」在 v2 是讀取模型與查詢結果，不新增一張可任意寫入、重複保存事實的 `history` 表。未來若建立搜尋索引或摘要快取，必須可由正式來源重建，不能成為另一份真相。

### 2.11 Attachment

附件保存穩定識別、擁有者、MIME、Hash 與生命週期狀態；不得把平台暫存路徑當成永久資料。

## 3. Schema v2 正式資料表

Schema v2 至少包含：

1. `item_categories`
2. `items`
3. `maintenance_plans`
4. `maintenance_plan_steps`
5. `general_reminders`
6. `milestones`
7. `schedules`
8. `tasks`
9. `maintenance_records`
10. `work_cases`（重建）
11. `work_case_updates`（重建或驗證）
12. `work_case_closures`
13. `attachments`

不得因施工方便省略正式模型，也不得以 JSON 大欄位取代需要查詢、約束與生命週期管理的一級實體。

## 4. `item_categories`

採「系統分類＋使用者自訂名稱」策略，不使用封閉式 Item enum 作為永久真相。

必要欄位：

- `id` primary key
- `systemCode` nullable
- `customName` nullable
- `displayName`
- `sortOrder`
- `status`
- `createdAt`
- `updatedAt`
- `archivedAt` nullable

限制：

- `systemCode` 與 `customName` 至少一項有效。
- 系統分類代碼不得由一般使用者資料覆寫成不同意義。
- 自訂名稱去除前後空白後不得為空。
- 已被 Item 使用的分類不得直接實體刪除，只能封存。
- `displayName` 是當前顯示名稱，不得以舊 enum ordinal 儲存。

## 5. `items`

必要欄位：

- `id` primary key
- `name`
- `categoryId` foreign key → `item_categories.id`
- `createdAt`
- `updatedAt`
- `purchaseDate` nullable
- `warrantyEndDate` nullable
- `expectedLifeYears` nullable
- `location` nullable
- `note` nullable
- `status`
- `archivedAt` nullable

限制：

- `name` 去除前後空白後不得為空。
- `expectedLifeYears` 有值時必須大於 0。
- Item 是所有子資料的穩定根關聯。
- 有任何 Plan、Reminder、Milestone、Schedule、Task、Record、WorkCase 或 Attachment 時禁止一般實體刪除。
- 停用採 paused／archived，不得用刪除假裝不存在。
- 主照片不得以 `photoPath` 永久保存，應由 Attachment 關聯承接。

## 6. `maintenance_plans`

必要欄位：

- `schemaVersion`
- `id` primary key
- `itemId` foreign key → `items.id`
- `templateCardId` nullable，僅記錄建立來源，不設外鍵
- `title`
- `planType`
- `description` nullable
- `riskLevel`
- `estimatedMinutes` nullable
- `requiredPhotos`
- `requiredNote`
- `safetyNotice` nullable
- `status`
- `createdAt`
- `updatedAt`
- `archivedAt` nullable

限制：

- `estimatedMinutes` 有值時必須大於 0。
- 模板更新不得覆蓋既有 Plan 的內容或步驟。
- Item 刪除採 restrict。
- 有 Schedule、Task、Record、Milestone 或 WorkCase 引用時禁止實體刪除。

## 7. `maintenance_plan_steps`

必要欄位：

- `id` primary key
- `maintenancePlanId` foreign key → `maintenance_plans.id`
- `stepOrder`
- `title`
- `description` nullable
- `isRequired`
- `photoRequired`
- `noteRequired`

限制：

- `stepOrder >= 0`。
- `(maintenancePlanId, stepOrder)` unique。
- 步驟是建立當下快照，不與模板動態同步。
- 正式刪除 API 必須先確認尚未形成歷史引用。

## 8. `general_reminders`

一般提醒不能只存在 Schedule 的 title 中。

必要欄位：

- `schemaVersion`
- `id` primary key
- `itemId` foreign key → `items.id`
- `title`
- `description` nullable
- `reminderType`
- `status`
- `createdAt`
- `updatedAt`
- `archivedAt` nullable

限制：

- `title` 不得為空。
- 到期、續約、文件、健康、家庭或其他提醒可透過 `reminderType` 表達，但未知值必須安全保留，不可擅自推論。
- Item 刪除採 restrict。
- 已產生 Schedule 或 Task 時優先封存，不實體刪除。

## 9. `milestones`

必要欄位依正式 Milestone 模型保存：

- `schemaVersion`
- `id` primary key
- `itemId` foreign key → `items.id`
- `title`
- `description` nullable
- `kind`
- `triggerType`
- `sourcePlanId` nullable foreign key → `maintenance_plans.id`
- `thresholdValue` nullable
- `thresholdUnit` nullable
- `triggerDate` nullable
- `dependencyMilestoneId` nullable self foreign key
- `lifeStageCode` nullable
- `status`
- `createdAt`
- `updatedAt`
- `reachedAt` nullable
- `acknowledgedAt` nullable
- `startedAt` nullable
- `completedAt` nullable
- `canceledAt` nullable
- `archivedAt` nullable
- `workCaseId` nullable foreign key → `work_cases.id`
- `cancellationReason` nullable

觸發約束：

- usageYears／mileage／usageValue／completionCount／anomalyCount：`thresholdValue > 0` 且 `thresholdUnit` 必填。
- specificDate：`triggerDate` 必填。
- dependencyCompleted：`dependencyMilestoneId` 必填且不得等於自身。
- lifeStage：`lifeStageCode` 必填。
- manual：不得要求系統假造門檻。
- unknown：可保存，但不得自動觸發。

生命週期限制：

- reached 只表示條件達成，不表示已完成。
- 若連到 WorkCase，`milestones.itemId` 必須等於 `work_cases.itemId`。
- completed／canceled／archived 後不得回寫成 pending。
- 不得因 Milestone 完成而自動產生 MaintenanceRecord。

## 10. `schedules`

Schedule 只保存時間規則及正式來源參照。

必要欄位：

- `id` primary key
- `itemId` foreign key → `items.id`
- `sourceType`
- `maintenancePlanId` nullable foreign key
- `generalReminderId` nullable foreign key
- `milestoneId` nullable foreign key
- `legacyCardId` nullable，僅供舊資料稽核
- `cycleType`
- `interval`
- `startDate`
- `nextDueDate`
- `reminderTime` nullable
- `status`
- `anchorPolicy`
- `userDefinedNextDate` nullable
- `createdAt`
- `updatedAt`
- `endedAt` nullable

正式 `sourceType`：

- `maintenancePlan`
- `generalReminder`
- `milestone`
- `unknown`

來源約束：

- 三個正式來源 FK 必須互斥。
- maintenancePlan 時只允許 `maintenancePlanId` 有值。
- generalReminder 時只允許 `generalReminderId` 有值。
- milestone 時只允許 `milestoneId` 有值。
- unknown 可保存舊資料，但不得產生新 Task。
- 所有來源實體的 `itemId` 必須與 Schedule 的 `itemId` 相同。
- 不使用空字串、特殊 cardId 或 title 推論來源。

週期基準：

- `anchorPolicy = fixedCalendarPeriod` 為正式預設。
- `completionBased` 只在使用者明確選擇時使用。
- `userDefined` 必須有使用者指定的下一日期。
- 不再使用 `strictPeriodMode` 布林值作為正式模型。
- 日、週、月、季、半年、年均依其原週期基準推進；延遲完成不得默認改變下一期。
- `interval > 0`。

## 11. `tasks`

必要欄位：

- `id` primary key
- `itemId` foreign key → `items.id`
- `sourceType`
- `scheduleId` nullable foreign key → `schedules.id`
- `maintenancePlanId` nullable foreign key
- `generalReminderId` nullable foreign key
- `milestoneId` nullable foreign key
- `legacyCardId` nullable
- `title`
- `dueDate`
- `status`
- `completedAt` nullable
- `postponedAt` nullable
- `canceledAt` nullable
- `createdAt`
- `updatedAt`

正式 `sourceType`：

- `scheduledMaintenance`
- `scheduledReminder`
- `milestone`
- `manual`
- `unknown`

限制：

- 由 Schedule 產生時 `scheduleId` 必填。
- manual Task 不得假裝綁定 Schedule、Plan、Reminder 或 Milestone。
- 各來源欄位必須依 sourceType 互斥。
- 有 Schedule 時，Task 與 Schedule 的 `itemId` 必須一致。
- 有 MaintenancePlan、GeneralReminder 或 Milestone 時，各來源的 `itemId` 必須與 Task 一致。
- sourceType 必須與 Schedule sourceType 相容。
- 同一 Schedule、同一到期週期不得重複產生 Task。
- 不用儲存型 `overdue` 布林值作為永久真相；逾期應由 dueDate 與狀態計算。若為相容保留，必須標示為可重建快取。

## 12. `maintenance_records`

保存舊完成紀錄與不需正式案件流程的簡單完成結果。

必要欄位：

- `id` primary key
- `itemId` foreign key → `items.id`
- `taskId` nullable foreign key → `tasks.id`
- `maintenancePlanId` nullable foreign key
- `recordType`
- `date`
- `title`
- `issueDescription` nullable
- `workDescription` nullable
- `partsChanged` nullable
- `cost` nullable
- `vendorName` nullable
- `warrantyUntil` nullable
- `result` nullable
- `note` nullable
- `createdAt`

限制：

- `taskId` 可空，支援補登。
- `cost` 有值時不得為負數。
- 不新增 `workCaseId`，避免與正式案件事實來源混淆。
- 舊 `photos` JSON 只作遷移相容；新附件一律經 `attachments` 保存。
- 有 Task 或 Plan 時，跨表 `itemId` 必須一致。

## 13. `work_cases`

v2 必須重建或驗證正式 Item 外鍵。

必要欄位至少保留現有 WorkCase 模型，並包含：

- `id` primary key
- `itemId` foreign key → `items.id`
- `sourceType`
- `sourceTaskId` nullable foreign key
- `sourceMilestoneId` nullable foreign key
- `title`
- `description` nullable
- `status`
- `openedAt`
- `updatedAt`
- `closedAt` nullable
- `canceledAt` nullable
- `cancellationReason` nullable

限制：

- WorkCase 可由 Task、Milestone 或使用者手動建立。
- sourceTask／sourceMilestone 與 WorkCase 必須屬於同一 Item。
- 結案摘要不得塞回 WorkCase 一般欄位取代 WorkCaseClosure。
- 已結案案件不允許一般修改或實體刪除。

## 14. `work_case_updates`

必要欄位至少包含：

- `id` primary key
- `workCaseId` foreign key → `work_cases.id`
- `occurredAt`
- `updateType`
- `content`
- `cost` nullable
- `createdAt`

限制：

- 每一筆 Update 是不可覆寫的過程事實。
- `cost` 有值時不得為負數。
- WorkCase 結案後不得新增一般進度；若需補正，必須走正式更正機制並保留原紀錄。
- Attachment 透過 owner 關聯，不在 Update 中存平台路徑。

## 15. `work_case_closures`

每個正式結案案件最多一筆 Closure。

必要欄位依正式 WorkCaseClosure 模型保存：

- `schemaVersion`
- `id` primary key
- `workCaseId` unique foreign key → `work_cases.id`
- `completedAt`
- `finalResult`
- `completionSummary`
- `totalCost` nullable
- `followUpNotes` nullable
- `followUpType`
- `nextScheduleId` nullable foreign key
- `nextTaskId` nullable foreign key
- `createdAt`
- `updatedAt`

限制：

- `(workCaseId)` unique。
- `totalCost` 有值時不得為負數。
- Closure 必須由使用者確認，不得由 Updates 自動猜測。
- follow-up 類型與 nextSchedule／nextTask 必須一致。
- 下一個 Schedule／Task 必須屬於同一 Item。
- 未知 follow-up 類型只能保存與阻擋，不得自動建立後續事項。
- Closure 建立與 WorkCase 狀態改為 closed 必須在同一 transaction。

## 16. `attachments`

必要欄位：

- `schemaVersion`
- `id` primary key
- `ownerType`
- `ownerId`
- `storageIdentifier`
- `mimeType`
- `contentHash` nullable
- `byteSize` nullable
- `status`
- `createdAt`
- `verifiedAt` nullable
- `missingAt` nullable
- `deletedAt` nullable
- `originalFileName` nullable

限制：

- 不保存 iOS、Web 或暫存區的易變絕對路徑作為唯一真相。
- ownerType 必須限定於正式可附加實體，例如 Item、MaintenanceRecord、WorkCaseUpdate、WorkCaseClosure。
- ownerId 的存在性由 Repository／transaction 驗證；SQLite 無法對多型外鍵直接建立單一 FK。
- 新附件不得使用空 Identifier 或空 MIME。
- `byteSize >= 0`。
- active、missing、deleted 等狀態轉換必須保留時間。
- 刪除資料列不等於刪除實體檔案；檔案刪除成功後才更新 deleted 狀態。
- Hash 用於完整性與重複檢查，不作為使用者可見檔名。

## 17. 跨表一致性契約

Foreign key 只證明「資料存在」，不足以證明「資料屬於同一生活項目」。所有建立與更新操作必須在 Repository transaction 中驗證：

```text
Task.itemId = Schedule.itemId
Task.itemId = MaintenancePlan.itemId
Task.itemId = GeneralReminder.itemId
Task.itemId = Milestone.itemId
Schedule.itemId = 正式來源.itemId
Milestone.itemId = sourcePlan.itemId
Milestone.itemId = WorkCase.itemId
WorkCase.itemId = sourceTask.itemId
WorkCase.itemId = sourceMilestone.itemId
WorkCaseClosure 的 nextSchedule／nextTask.itemId = WorkCase.itemId
MaintenanceRecord.itemId = Task／MaintenancePlan.itemId
```

任何不一致均需拒絕 transaction，不得自動改寫其中一方或猜測正確 Item。

## 18. 刪除與封存政策

- Item：優先封存；有任何正式子資料時禁止實體刪除。
- ItemCategory：被使用時只能封存。
- MaintenancePlan／GeneralReminder：已產生規則或歷史時只能封存。
- Milestone：完成、取消或開始處理後永久保留；未啟動且無引用者才可考慮實體刪除。
- Schedule：停止採 ended，不刪除既有 Task 的來源。
- Task：完成、延期、取消均保留。
- MaintenanceRecord：正式 API 不提供一般實體刪除。
- WorkCase／Update／Closure：永久保留；結案後唯讀。
- Attachment：採生命週期狀態，不因 Owner 被封存而刪除。

資料庫 FK 是最低安全線，Repository 必須實作更嚴格的封存及不可變規則。

## 19. v1 → v2 Migration 前置閘門

正式 migration 前必須先建立只讀盤點報告，至少確認：

- SharedPreferences 中 Item、Schedule、Task、MaintenanceRecord 的筆數與可解析性。
- 空字串 ID、孤兒關聯、重複 ID、未知 enum、非法日期、負數金額。
- Drift v1 `work_cases`、`work_case_updates` 的實際筆數。
- 既有附件 Identifier 與實體檔案可用性。
- 所有不可變 `backup_v1_*` 備份已建立並通過 Hash／筆數驗證。

阻擋條件：

- `work_cases` 或 `work_case_updates` 任一非空，而尚無經批准的逐筆轉換規則。
- 任一來源資料無法解析且沒有隔離保存方案。
- 備份缺漏、Hash 不一致或無法還原。
- 關聯盤點仍存在未分類的 orphan／collision。
- Migration 測試未證明完整 rollback。

不得因「理論上沒有資料」省略實際查詢。

## 20. Migration 原則與順序

所有 schema 建立、舊 Drift 表重建、資料轉換與驗證必須在可回滾 transaction 中進行；SharedPreferences 原始資料在 v2 驗收前不得刪除或覆寫。

建議順序：

```text
確認 foreign_keys=ON
→ 驗證不可變備份與 migration 准入報告
→ 檢查 v1 WorkCase／Update 阻擋條件
→ 建立 item_categories
→ 建立 items
→ 建立 maintenance_plans／steps
→ 建立 general_reminders
→ 重建 work_cases／work_case_updates
→ 建立 milestones
→ 建立 schedules
→ 建立 tasks
→ 建立 maintenance_records
→ 建立 work_case_closures
→ 建立 attachments
→ 建立索引與 unique／check constraints
→ 分階段轉換可安全對應的舊資料
→ 驗證筆數、FK、跨 Item 一致性與來源契約
→ 執行 foreign_key_check／integrity_check
→ transaction commit
→ 保留舊來源為唯讀，等待獨立切換 PR
```

任一步驟失敗必須 rollback。不得半套切換 Repository 或讓 UI 同時讀寫兩份正式來源。

## 21. 索引基線

至少建立：

- `item_categories(systemCode, status)`、`displayName`
- `items(categoryId, status)`、`createdAt`
- `maintenance_plans(itemId, status)`、`updatedAt`
- `maintenance_plan_steps(maintenancePlanId, stepOrder)` unique
- `general_reminders(itemId, status)`
- `milestones(itemId, status)`、`triggerType`、`triggerDate`、`sourcePlanId`
- `schedules(itemId, status)`、`sourceType`、各來源 FK、`nextDueDate`
- `tasks(itemId, status)`、`scheduleId`、`sourceType`、`dueDate`
- 防止同一 Schedule／週期重複 Task 的 unique key
- `maintenance_records(itemId, date)`、`taskId`
- `work_cases(itemId, status)`、`updatedAt`
- `work_case_updates(workCaseId, occurredAt)`
- `work_case_closures(workCaseId)` unique、`completedAt`
- `attachments(ownerType, ownerId, status)`、`contentHash`

## 22. Schema v2 測試要求

正式程式 PR 至少包含：

### 建立與遷移

- 全新資料庫建立測試。
- v1 → v2 正常 migration。
- 阻擋資料存在時拒絕 migration。
- transaction 任一步驟失敗完整 rollback。
- 原始 SharedPreferences 與備份未被修改。
- native／Web Drift schema 驗證。

### 關聯與限制

- ItemCategory 系統＋自訂策略。
- Item 根關聯與刪除 restrict。
- MaintenancePlan／Step 快照與 unique order。
- GeneralReminder 正式來源。
- Milestone 各 triggerType 完整性及未知值阻擋。
- Schedule 三來源互斥。
- ScheduleAnchorPolicy 的日、週、月、季、半年、年、月底、閏年與跨年測試。
- completionBased 只能由明確設定啟用。
- Task nullable scheduleId、manual source 與來源一致性。
- 同一期不得重複產生 Task。
- WorkCase 的 Item 與來源一致性。
- WorkCaseClosure 一案一結案、非負總費用及後續參照。
- Attachment 狀態轉換、owner 驗證、遺失與刪除流程。
- 所有跨表 Item 不一致均被拒絕。

### 產品邊界

- Task 不會直接變成 WorkCaseClosure 或史略摘要。
- Milestone reached 不會被當成 completed。
- MaintenanceRecord 不會偽造成 WorkCase。
- 結案內容不會由 Updates 自動猜測。
- 固定週期不因延遲完成漂移。
- 未知來源、未知 enum 與損壞資料只隔離並回報，不自動補造。

### 建置

- `flutter analyze`
- 全部測試
- Drift code generation 無未提交差異
- Web build
- WASM／worker 資產驗證

## 23. 正式施工拆分

Schema v2 不得用一個超大型 PR 同時完成所有工作。至少拆為：

1. **Schema 程式 PR**：只新增／重建 table、converter、constraint、index 與 schema tests。
2. **Migration PR**：只執行經批准的 v1 → v2 轉換與 rollback tests。
3. **Repository PR**：建立 transaction、跨表 Item 驗證、封存政策與來源契約。
4. **資料切換 PR**：在驗證後切換正式讀取來源，保留舊來源唯讀。
5. **UI 接線 PR**：最後才讓首頁、生活項目詳情與案件流程讀取正式資料。

任何 PR 都不得順便重寫已驗證 UI、導覽或產品文案。

## 24. 舊草稿處理

舊 `database/core-schema-v2` 分支只保留為稽核證據：

- 可參考欄位命名，但不得直接合併或 cherry-pick。
- 舊 Item enum、`strictPeriodMode`、模糊 Schedule source、空字串外鍵及以照片路徑為真相的設計均不得沿用。
- 正式 Schema 程式施工必須由更新後的最新 `main` 建立新分支。

## 25. 批准條件

本設計文件完成下列檢查後，才可批准下一個「Schema 程式 PR」：

- 與產品憲法、核心資料角色、Milestone、Category Strategy、ScheduleAnchorPolicy、WorkCaseClosure、Schedule／Task Source Contract、Attachment Lifecycle 及視覺架構一致。
- 沒有平行流程或第二份歷史真相。
- 沒有把提醒、完成紀錄或模板重新升格成產品核心。
- Migration 阻擋、備份與 rollback 條件可實際測試。
- 施工範圍仍維持資料層，不接 UI、不切 Repository、不修改使用者資料。

在正式審查批准前，PR #185 必須維持 Draft。