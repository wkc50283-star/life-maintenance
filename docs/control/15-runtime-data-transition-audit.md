# 生活管理 App｜正式 Runtime 資料流稽核與單一寫入控制

狀態：正式控制文件
版本：v0.5.1
日期：2026-07-19
適用範圍：正式 `lib/main.dart` Runtime、SharedPreferences 舊資料、Drift Schema v2 Repository 與後續資料切換 PR

## 1. 文件目的

本文件依 2026-07-19 的 `main` 實際程式建立證據基線，回答：

- 正式 App 現在從哪裡讀資料、向哪裡寫資料。
- 所有 SharedPreferences／LocalRepository 讀寫點在哪裡。
- Drift Schema v2 Repository 已覆蓋什麼、尚未接到什麼。
- 舊模型與正式 Schema v2 欄位如何對應，哪些內容不得猜測。
- 匯入、驗證、切換、rollback 與驗收必須依什麼順序執行。
- 如何禁止 SharedPreferences 與 Drift 同時成為正式 writer。

本文件是稽核與後續施工規格，不是執行授權。本文件合併時不得匯入、搬移、刪除或改寫任何使用者資料，也不得修改 Runtime、Repository、UI、Schema 或 Migration。

## 2. 不可改變的產品與資料角色

- `Item` 是所有生活資料的 Root。
- `MaintenancePlan` 是長期保養項目。
- `Schedule` 是時間規則。
- `Task` 只是某一次提醒。
- `WorkCase` 才是事情正式發生或開始處理的案件。
- `WorkCaseUpdate` 是不可互相覆蓋的案件過程。
- `WorkCaseClosure` 才是正式結案。
- `MaintenanceRecord` 承接舊完成紀錄與不需案件流程的簡單完成結果。
- `History`／史略是正式來源的查詢投影，不是可獨立寫入的第三份真相。

任何匯入或切換不得把舊 Task 直接變成 WorkCase、把 MaintenanceRecord 偽造成案件過程，或建立新的平行 History 流程。

## 3. 稽核結論

### 3.1 正式 Runtime 現況

正式入口 `lib/main.dart`：

1. 啟動時建立 `LocalStorageService`。
2. 對四個舊資料鍵建立缺少時才寫入的 `backup_v1_*` 原始備份。
3. 透過四個 LocalRepository 讀取並解析舊資料。
4. 發現任何完整性問題時，以記憶體內的全域 gate 阻擋所有 LocalRepository 寫入。
5. `TodayScreen`、`ItemsScreen`、`HistoryScreen`、新增表單與提醒表單仍直接建立 LocalRepository。

正式 Runtime 沒有：

- 建立 `AppDatabase.defaults()`。
- 建立 `DriftSchemaV2Repositories`。
- 注入任何 Drift Repository 到正式畫面或 service。
- 執行 `MigrationReadinessService`、`LegacyRelationAuditService` 或 `MigrationAdmissionService`；這些目前只有測試使用。
- 讀取或寫入 WorkCase、WorkCaseUpdate、WorkCaseClosure、Milestone、MaintenancePlan、GeneralReminder 或 Attachment 的正式 Runtime 流程。

因此目前唯一正式使用者資料來源與 writer 仍是 SharedPreferences；Drift Schema v2 與 Repository 是已測試但尚未接管 Runtime 的資料層基礎。

### 3.2 儲存鍵

| 角色 | 正式舊鍵 | 不可變備份鍵 | 現行模型 |
|---|---|---|---|
| 生活項目 | `items` | `backup_v1_items` | `Item` |
| 排程／舊提醒內容 | `schedules` | `backup_v1_schedules` | `Schedule` |
| 某次提醒 | `tasks` | `backup_v1_tasks` | `Task` |
| 舊完成紀錄 | `maintenance_records` | `backup_v1_maintenance_records` | `MaintenanceRecord` |

`LocalStorageService.remove()` 存在，但正式 `lib/` 目前沒有呼叫點。後續切換不得利用它提前刪除舊來源或備份。

## 4. SharedPreferences／LocalRepository 全部 Runtime 讀寫點

### 4.1 共用底層

| 檔案 | 行為 | 風險／規則 |
|---|---|---|
| `lib/services/local_storage_service.dart` | 每次呼叫重新取得 SharedPreferences instance；提供 string read／write／remove | 沒有跨鍵 transaction；`remove` 目前未使用 |
| `lib/repositories/item_local_repository.dart` | `items` 全量 JSON 讀寫 | read-modify-write 不是原子集合交易 |
| `lib/repositories/schedule_local_repository.dart` | `schedules` 全量 JSON 讀寫 | 同上 |
| `lib/repositories/task_local_repository.dart` | `tasks` 全量 JSON 讀寫 | 同上 |
| `lib/repositories/maintenance_record_local_repository.dart` | `maintenance_records` 全量 JSON 讀寫 | 同上 |
| `lib/services/local_data_integrity_service.dart` | 逐筆解析；任一鍵有問題時全域阻擋上述四個 Repository 寫入 | gate 只存在記憶體，依每次啟動 preflight 重建 |
| `lib/services/local_data_backup_service.dart` | 啟動時只在備份鍵不存在時複製原始字串 | 已存在備份不覆寫；來源不存在時不建立空備份 |

### 4.2 啟動與背景衍生寫入

| 檔案／流程 | 讀取 | 寫入 | 正式判定 |
|---|---|---|---|
| `lib/main.dart` `_runIntegrityPreflight` | 四組來源與四組備份 | 缺少時建立 `backup_v1_*` | 是正式啟動流程 |
| `lib/screens/today_screen.dart` `_loadTasks` | Item、Schedule、Task | 到期時把衍生 Task 寫回 `tasks` | 僅開啟／重新 activate Today 即可能寫入 |
| `lib/services/maintenance_task_service.dart` | 接受記憶體 Schedule／Task | 不直接存檔 | 以 `scheduleId + dueDate` 防止同一期重複，但仍依舊 `cardId` 判斷內容 |

### 4.3 Item 讀寫點

讀取：

- `lib/main.dart`：啟動完整性預檢。
- `lib/screens/today_screen.dart`：把 Task 關聯到 Item。
- `lib/screens/items_screen.dart`：生活項目清單與詳情。
- `lib/screens/history_screen.dart`：史略顯示名稱。
- `lib/widgets/preview_form_fields.dart`：新增提醒／紀錄時的 Item 下拉選單。
- `lib/widgets/reminder_list_sheet.dart`：提醒清單顯示 Item。
- `lib/widgets/add_item_preview_sheet.dart`：新增前全量讀取。

寫入：

- `lib/widgets/add_item_preview_sheet.dart`：全量讀取後 append 一筆 Item，再覆寫整個 `items` JSON。

### 4.4 Schedule 讀寫點

讀取：

- `lib/main.dart`：啟動完整性預檢。
- `lib/screens/today_screen.dart`：產生 Task、完成後推進／暫停／結束／重新安排。
- `lib/screens/items_screen.dart`：Item 詳情與恢復 paused Schedule。
- `lib/widgets/expiry_reminder_preview_sheet.dart`：新增一般提醒前全量讀取。
- `lib/widgets/reminder_list_sheet.dart`：列出、編輯、取消與恢復提醒。

寫入：

- `lib/widgets/expiry_reminder_preview_sheet.dart`：用 `cardId = manual-expiry-reminder` 建立一般提醒 Schedule。
- `lib/widgets/reminder_list_sheet.dart`：編輯 title、nextDueDate、取消、恢復 paused reminder。
- `lib/screens/items_screen.dart`：恢復 paused maintenance Schedule。
- `lib/screens/today_screen.dart`：完成 Task 後推進 nextDueDate、暫停、結束或重排 Schedule。

### 4.5 Task 讀寫點

讀取：

- `lib/main.dart`：啟動完整性預檢。
- `lib/screens/today_screen.dart`：顯示、產生與完成 Task。
- `lib/screens/items_screen.dart`：恢復 Schedule 前檢查同日未完成 Task。
- `lib/widgets/reminder_list_sheet.dart`：編輯、取消或恢復 Schedule 前檢查衝突。

寫入：

- `lib/screens/today_screen.dart` `_loadTasks`：append 到期生成的 Task。
- `lib/screens/today_screen.dart` `_completeTask`：先把 Task 標記 completed，再建立 MaintenanceRecord。

提醒清單目前不會同步取消既有 Task，只在存在未完成 Task 時阻止部分 Schedule 操作。

### 4.6 MaintenanceRecord 讀寫點

讀取：

- `lib/main.dart`：啟動完整性預檢。
- `lib/screens/today_screen.dart`：Task 完成時檢查是否已有相同 `taskId` 紀錄。
- `lib/screens/items_screen.dart`：Item 詳情的完成紀錄。
- `lib/screens/history_screen.dart`：目前 History Runtime 的唯一事實來源。
- `lib/widgets/maintenance_record_preview_sheet.dart`：補登前全量讀取。

寫入：

- `lib/screens/today_screen.dart` `_completeTask`：Task 完成後 append 一筆紀錄。
- `lib/widgets/maintenance_record_preview_sheet.dart`：補登不含 `taskId` 的簡單完成紀錄。

### 4.7 已存在但未接入正式 Runtime 的只讀稽核點

- `lib/services/migration_readiness_service.dart`：讀取四組來源、四組備份，並查詢 Drift WorkCase／Update 筆數；不寫來源。
- `lib/services/legacy_relation_audit_service.dart`：讀取四組來源，檢查逐筆解析、duplicate ID 與 Item／Schedule／Task 關聯；不寫來源。
- `lib/services/migration_admission_service.dart`：組合上述兩份報告形成 blocker；本身不直接讀寫儲存。

這三個 service 目前只有測試呼叫，不等於正式啟動流程已執行 migration admission。

## 5. 現行 Runtime 資料風險

### R1：跨集合部分完成（高）

Task 完成流程依序：

```text
save tasks
→ load records
→ save records
→ load/save schedules
```

SharedPreferences 沒有跨鍵 transaction。可能結果：

- Task 已 completed，但 MaintenanceRecord 建立失敗。
- Task 與 MaintenanceRecord 已完成，但 Schedule 推進／暫停／結束失敗。
- App 顯示「後續安排未更新」，但資料已形成部分提交。

正式切換後必須用單一 Drift transaction 承接對應操作，不能沿用此順序逐表提交。

### R2：全量 read-modify-write 遺失更新（高）

四個 LocalRepository 都讀取整份清單、在記憶體修改、再覆寫整個 JSON。兩個畫面或非同步流程若基於不同舊快照存檔，後寫者可能覆蓋先寫者。

### R3：一般提醒與排程混為同一舊模型（高）

`manual-expiry-reminder` 特殊 `cardId` 同時承擔 GeneralReminder 身分與 Schedule 來源；title 也存在 Schedule。匯入時必須拆成 GeneralReminder + Schedule，不能只把舊 Schedule row 原樣搬入。

### R4：舊保養內容與 Schedule 混合（高）

非 `manual-expiry-reminder` 的 `cardId` 可能指向舊模板。舊資料沒有正式 MaintenancePlan。只有能確定對應到既有 catalog 的資料，才可用快照建立 MaintenancePlan；未知或空值必須阻擋／隔離並保留 `legacyCardId`，不得依 title 猜測。

### R5：舊 nullable 關聯以空字串表示（高）

舊 Task 的 `cardId`、`scheduleId` 缺值時 fallback 為空字串；Schema v2 使用真正 nullable FK 與 source contract。空字串不得直接寫入正式 FK。

### R6：舊分類與正式 ItemCategory 不同（高）

舊 Item 只有五值 enum；Schema v2 使用 `item_categories` 關聯。匯入前必須建立確定的系統分類種子與 ID mapping。未知舊值保留於報告，不依 Item 名稱猜測。

### R7：舊照片不是正式 Attachment（高）

Item `photoPath` 與 MaintenanceRecord `photos` 可能是平台路徑或舊識別字串；不得直接當 `Attachment.storageIdentifier` 的永久真相。需先驗證檔案存在、owner、MIME、hash 與可搬移識別；無法驗證者保留來源證據並標記 missing，不可靜默丟棄。

### R8：ID collision（中）

新增 Item／Schedule／MaintenanceRecord 使用 `millisecondsSinceEpoch`。快速或並行新增可能碰撞。匯入需先做跨來源與目標 ID collision 報告，不能讓 upsert 靜默覆蓋。

### R9：備份只保留第一次快照（中）

`backup_v1_*` 是首次存在來源時的不可變副本；後續 SharedPreferences 正常寫入不會更新備份。因此正式匯入前除驗證不可變備份外，仍須另外取得「切換凍結點」來源快照與 hash。不得把第一次備份誤當成當前來源鏡像。

### R10：readiness／admission 尚未進入 Runtime（中）

已有只讀 service 與測試，但正式 App 不會執行 admission gate。未來 importer 不得只因 service 存在就假設已通過；必須在同一受控流程取得、保存並驗證報告。

### R11：Drift 與 SharedPreferences 可各自成功但沒有權威來源標記（高）

目前沒有已批准、持久化且可驗證的 active-store／cutover 狀態。若直接接線，不同畫面可能各自建立 Repository，造成雙來源或雙寫。正式切換 PR 必須先定義單一 composition root 與持久化切換狀態；本文件不批准新增 table、key 或 API。

## 6. Drift Repository 覆蓋與 Runtime 差距

| 正式角色 | Schema v2 Repository | Domain 轉換 | Runtime 使用 | 主要差距 |
|---|---|---|---|---|
| ItemCategory | find/list/save/archive/deleteUnused | 只使用 Drift row | 無 | 缺正式 Runtime boundary 與 legacy category mapper |
| Item | find/list/save/archive/deleteUnused | 只使用 Drift row | 無 | 缺舊 `Item` ↔ ItemRow／Category／Attachment mapper |
| MaintenancePlan／Step | find/list/save/archive/deleteUnused | 完整 Domain mapper | 無 | 舊 Schedule/card catalog → Plan 規則未實作 |
| GeneralReminder | find/list/save/archive/deleteUnused | 只使用 Drift row | 無 | 沒有獨立 Domain model；舊特殊 Schedule 拆分規則未實作 |
| Milestone | find/list/save/deleteUnused | 完整 Domain mapper | 無 | 舊來源沒有對應資料，不得自動補造 |
| Schedule | find/list/save/end/deleteUnused | 只使用 Drift row | 無 | 缺舊 Schedule → source contract／anchor policy mapper |
| Task | find/list/save | 只使用 Drift row | 無 | 缺舊 Task → nullable FK／source mapper；Runtime 仍自行生成舊 Task |
| MaintenanceRecord | find/list/create | 只使用 Drift row | 無 | 缺 list／photos／parts 的正式 mapper 與 import contract |
| WorkCase／Update | find/list/save/append/transactional create | 完整 Domain mapper | 無 | 正式 UI／service 尚未建立；不屬舊四組資料匯入 |
| WorkCaseClosure | find/close/cancel transaction | 完整 Domain mapper | 無 | 正式結案 Runtime 尚未建立 |
| Attachment | find/list/create/verify/missing/deleted | 完整 Domain mapper | 無 | 檔案層與 legacy photo importer 尚未建立 |
| History | 無 writable Repository，符合正式設計 | 應由查詢投影組成 | Runtime 只讀舊 MaintenanceRecord | 缺統一 projection；禁止新增 History writer |

Repository 完成不等於 Runtime 已切換。正式接線前仍缺：composition root、舊資料 converter、dry-run report、import transaction、切換狀態、read projection、rollback gate 與跨平台驗收。

## 7. 舊模型到 Schema v2 欄位對應

### 7.1 Item

| 舊欄位 | v2 目標 | 規則 |
|---|---|---|
| `id` | `items.id` | 原值保留；先查 collision |
| `name` | `items.name` | trim 後不可空；不自動改名 |
| `category` | `item_categories` + `items.categoryId` | 僅確定 enum mapping；未知值保留報告，不猜測 |
| `photoPath` | 未直接對應；候選 Attachment | 必須經檔案驗證流程；不可直接當永久 identifier |
| `createdAt` | `items.createdAt` | 原值保留 |
| `purchaseDate` | 同名欄位 | 原值保留 |
| `warrantyEndDate` | 同名欄位 | 原值保留 |
| `expectedLifeYears` | 同名欄位 | 必須 > 0，否則阻擋／隔離 |
| `location` | 同名欄位 | 原值保留 |
| `note` | 同名欄位 | 原值保留 |
| `status` | `items.status`、`archivedAt` | enum 確定映射；舊資料沒有 archivedAt 時不得猜日期 |
| 無 | `updatedAt` | 需正式批准 deterministic fallback；不可用匯入時間冒充使用者更新時間 |

### 7.2 Schedule

| 舊欄位 | v2 目標 | 規則 |
|---|---|---|
| `id` | `schedules.id` | 原值保留 |
| `itemId` | 同名 FK | Item 必須先存在 |
| `cardId` | `legacyCardId` + 正式來源 | 特殊提醒拆 GeneralReminder；已知 catalog 建 Plan；未知不得猜 |
| `title` | GeneralReminder／MaintenancePlan title | 不留在正式 Schedule；依可證明來源搬移 |
| `cycleType` | 同名欄位 | `custom` 必須同時取得合法 userDefined 日期策略 |
| `interval` | 同名欄位 | 必須 > 0 |
| `startDate` | 同名欄位 | 原值保留 |
| `nextDueDate` | 同名欄位 | 原值保留並驗證 |
| `reminderTime` | 同名欄位 | 格式需驗證 |
| `status`／`enabled` | `status`、`endedAt` | active/paused/ended 確定映射；無 endedAt 不猜日期 |
| `strictPeriodMode` | `anchorPolicy` | `true` 可確定映射 fixedCalendarPeriod；`false` 不能自動視為使用者選擇 completionBased，需依正式 legacy policy 決定 |
| 無 | source FK、createdAt、updatedAt | 必須由正式 converter 規則提供；不得以空字串填 FK |

### 7.3 Task

| 舊欄位 | v2 目標 | 規則 |
|---|---|---|
| `id` | `tasks.id` | 原值保留 |
| `itemId` | 同名 FK | 必須與 Schedule／正式來源同 Item |
| `cardId` | `legacyCardId` + 正式來源 FK | 跟隨 Schedule 的已驗證來源，不自行推論 |
| `scheduleId` | nullable `scheduleId` | 空字串轉 null；非空必須存在 |
| `title` | 同名欄位 | 原值保留 |
| `dueDate` | 同名欄位 | 原值保留；同 schedule + dueDate 不得重複 |
| `status` | 同名欄位 | 確定 enum mapping |
| `completedAt` | 同名欄位 | completed 狀態需一致 |
| `postponedAt` | 同名欄位 | postponed 狀態需一致 |
| `overdue` | 不作永久真相 | 由 dueDate + status 重算；只列比對差異 |
| 無 | `sourceType`、來源 FK、`canceledAt`、createdAt、updatedAt | 依已驗證 Schedule mapping；缺失時間不得任意偽造 |

### 7.4 MaintenanceRecord

| 舊欄位 | v2 目標 | 規則 |
|---|---|---|
| `id`、`itemId` | 同名欄位／FK | 原值保留，Item 必須存在 |
| `taskId` | nullable FK | 空值保留；非空必須存在且同 Item |
| 無 | `maintenancePlanId` | 只有 Task／Schedule 來源能確定時才填，否則 null |
| `recordType`、`date`、`title` | 同名欄位 | enum／必填驗證 |
| `issueDescription`、`workDescription` | 同名欄位 | 原值保留 |
| `partsChanged` | v2 serialized text | 使用正式可逆 converter；round-trip 必須逐筆相等 |
| `cost` | 同名欄位 | 非負；負值阻擋／隔離 |
| `vendorName`、`warrantyUntil`、`result`、`note` | 同名欄位 | 原值保留 |
| `photos` | 不在 v2 record row；候選 Attachment | 逐筆 owner 驗證；不可靜默丟棄或直接保存平台路徑 |
| `createdAt` | 同名欄位 | 舊缺值 parser 以 `date` fallback；報告需標示 fallback 使用量 |

### 7.5 沒有舊來源的正式角色

`Milestone`、`WorkCase`、`WorkCaseUpdate`、`WorkCaseClosure` 與新的 Attachment 生命週期沒有可由四組舊 JSON 完整還原的來源。匯入器不得創造它們。既有 Drift v1→v2 WorkCase／Update 由已完成的 Schema migration 保留，必須與四組舊資料匯入分開驗證。

## 8. 禁止雙寫正式規則

### 8.1 單一 writer 原則

任何已發布 Runtime、任何資料角色、任何時間點，只能有一個正式 writer：

```text
切換前：SharedPreferences writer；Drift 只可被只讀稽核或受控 importer 寫入
切換門檻：所有使用者 mutation 暫停
切換後：Drift writer；SharedPreferences 與 backup_v1_* 永久唯讀
```

禁止：

- 同一使用者操作先寫 SharedPreferences、再寫 Drift。
- 一邊寫 Drift，一邊以「保險」名義回寫 SharedPreferences。
- Today 使用 SharedPreferences、Items 使用 Drift，或任何依畫面分流資料來源。
- 失敗時 fallback 到另一個 writer。
- 背景 task generation 寫舊 `tasks`，前景操作寫新 `tasks`。
- 以 History cache、同步表或 mirror table 建立第二份不可重建真相。

### 8.2 允許的雙讀

只允許在明確 read-only validation mode 中雙讀：

- UI 與所有 mutation 必須仍指向單一來源，或全部 mutation 被 gate 阻擋。
- Drift 與 SharedPreferences 比對結果只形成報告，不自動修正任何一方。
- 比對失敗立即阻擋切換。
- 雙讀程式不得長期留在一般 Runtime 路徑。

### 8.3 受控匯入不是雙寫

受控 importer 可在 SharedPreferences 已凍結唯讀、所有 Runtime mutation 關閉時，於單一 Drift transaction 寫入目標。此時 SharedPreferences 不是 writer。匯入成功後仍不得立即開啟 Drift 寫入，必須先完成比對與切換驗收。

## 9. 正式匯入、切換與驗收順序

每個箭頭都是 admission gate，不得合併成一個 PR：

```text
本 Runtime 稽核控制文件
→ 純 converter／dry-run 規格與測試
→ 真實來源只讀盤點（含切換凍結點 hash）
→ importer（預設關閉，單一 transaction）
→ SharedPreferences mutation gate 全關
→ 執行匯入
→ count／ID／欄位／關聯／hash／FK／integrity 比對
→ Drift read-only shadow 驗收
→ 持久化且單一的 repository composition root 切換
→ 冷啟動、重啟、背景恢復、Web refresh、iOS／Android 真機驗收
→ 明確人工批准
→ 才開啟 Drift mutation
→ SharedPreferences 與 backup 永久唯讀保留至少一個可驗證版本週期
```

### 9.1 匯入前 admission

- 四組來源與備份可解析。
- 建立切換凍結點的 exact raw snapshot、hash、byte length 與 entry count。
- 無 duplicate ID、空 ID、非法日期、負值、orphan 或跨 Item mismatch。
- `manual-expiry-reminder`、已知 catalog cardId、未知 cardId 分類完成。
- ItemCategory seed 與 legacy enum mapping 已批准。
- `strictPeriodMode = false` 的正式 legacy policy 已批准。
- 所有缺少 createdAt／updatedAt／endedAt／canceledAt 的處置已批准。
- 目標 Drift 的既有 WorkCase／Update 及 Item collision 已逐筆盤點。
- importer 重複執行、任一步驟失敗 rollback 與 app 中斷測試通過。

### 9.2 匯入後比對

- 每組來源 raw count、valid count、imported count、isolated count 守恆。
- 每個 ID 一對一；沒有 silent upsert 或 overwrite。
- 每一可逆欄位 round-trip 相等。
- 所有 FK 與跨 Item contract 通過。
- `PRAGMA foreign_key_check` 與 `integrity_check` 通過。
- 同 Schedule + dueDate Task unique 通過。
- Item、Record 照片每個 identifier 都有「已轉換／missing／隔離」結論。
- History projection 顯示舊 MaintenanceRecord，但不產生虛構 WorkCase。

### 9.3 切換驗收

- 全 App 只從單一 composition root 取得 Repository，不再由 widget 直接 new LocalRepository。
- `rg` 證明正式 Runtime 沒有 LocalRepository／SharedPreferences writer；只允許明確 legacy read-only／recovery 模組。
- Today 的 task generation、Task 完成、簡單 MaintenanceRecord 與 Schedule follow-up 由 Drift transaction 保證全成或全退。
- Item、Schedule、Task、Record 的空／少量／大量與異常資料結果一致。
- WorkCase、Closure 與 History 角色沒有被舊流程混用。
- Web worker／WASM、refresh persistence、iOS／Android 冷啟動與 app upgrade 真機驗收通過。
- analyze、全部 tests、Web release build 與 CI 全綠。

## 10. Rollback 規則

### 10.1 匯入 transaction commit 前

任一錯誤整批 rollback；SharedPreferences 與 `backup_v1_*` 不得改變。App 繼續使用舊 Runtime。

### 10.2 匯入完成、Drift mutation 尚未開啟

可把 active repository 切回 SharedPreferences，因來源仍是凍結點原文且未被修改。匯入產生的四組目標資料只能依可識別 import batch 整批撤回；不得刪除原先已存在並由 v1→v2 migration 保留的 WorkCase／Update。若無法區分 import batch，禁止執行破壞性清除，只能重建隔離測試資料庫或採 roll-forward 修正。

### 10.3 Drift mutation 開啟後

這是自動回切的不可逆門檻。SharedPreferences 無法表達 MaintenancePlan、GeneralReminder、Milestone、WorkCase、Closure、Attachment 與正式來源契約；禁止直接把 active store 切回舊 Runtime，否則會遺失新事實。

此後只能：

- 保持 Drift 為唯一 writer。
- 進入資料保護／唯讀模式。
- 從不可變來源、Drift transaction／database backup 與稽核報告 roll-forward 修復。
- 若未來需要 reverse migration，必須是獨立、經批准且可證明不遺失資料的 PR；不得以雙寫達成。

## 11. 治理衝突與未決阻擋

- `README.md`、`03-architecture-and-data.md`、`07-database-decision.md` 與 `08-legacy-migration-scope.md` 部分段落仍描述 Schema v1／尚未建立 Schema v2；它們是歷史施工狀態，不得用來否定目前已合併的 Schema v2、v1→v2 migration 與 Repository 基線。本文件記錄目前 Runtime 真相，後續治理同步應另開文件 PR。
- `12-item-category-strategy.md` 的候選段落曾主張 v2 不建立 `item_categories`，但目前已合併 Schema v2。PR #203 依最新 Schema 與正式授權，已在 `16-sharedpreferences-drift-v2-import.md` 收斂 legacy enum → category row mapping；舊候選段落不得反向否定已合併 Schema。
- PR #203 依禁止 Schema 變更的範圍，採確定性 ID、逐列內容比對與 partial-import blocker 完成重複匯入保護，不新增 durable marker。這只批准 importer 的 idempotency，不等於批准 Runtime cutover marker 或切換。
- GeneralReminder、Item、Schedule、Task、MaintenanceRecord 的 Repository 邊界目前使用 Drift row，而不是完整 Domain mapper。正式 Runtime 接線前必須決定 boundary，不得讓 UI 直接操作 Database row。

上述阻擋不影響本稽核文件成立，但任何一項未解決都阻擋正式匯入或切換。

## 12. 本 PR 明確不做

- 不修改 Dart 程式、Repository、service、widget 或 UI。
- 不修改 Drift table、schemaVersion 或 migration。
- 不建立 importer、converter、cutover flag、API 或新資料表。
- 不執行 SharedPreferences 或 Drift 資料搬移。
- 不讀取任何使用者真機資料。
- 不刪除或覆寫來源與 `backup_v1_*`。
- 不開始下一個 PR。

## 13. 本文件驗收

- 所有正式 Runtime LocalRepository 讀寫點均有列出。
- Drift Repository coverage 與 Runtime gap 均有列出。
- 四組舊模型欄位有逐欄對應與不可推論規則。
- 已建立單一 writer、受控雙讀、切換與 rollback 紅線。
- 已定義不可合併的 admission gates 與驗收順序。
- 文件沒有批准 UI、Migration、匯入、切換或新功能施工。
