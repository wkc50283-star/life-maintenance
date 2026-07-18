# 生活管理 App 架構與資料設計書

狀態：正式控制文件  
本文件定義資料角色、關聯與遷移原則；具體資料庫選型須另行驗證。

## 1. 核心資料角色

| 模型／角色 | 正式定位 |
|---|---|
| `Item` | 生活項目，代表被長期管理的對象 |
| `MaintenanceCardCatalog` | 系統提供的建立模板與安全操作內容，不是使用者資料 |
| `MaintenancePlan` | 使用者真正建立、長期存在的保養項目 |
| `MaintenanceStep` | 模板或保養項目的標準步驟，不是實際處理進度 |
| `Schedule` | 固定週期、日期與提醒安排，只負責時間規則 |
| `Task` | 某次到期或待處理提醒實例 |
| `MaintenanceRecord` | 既有完成結果與舊版歷史資料 |
| `WorkCase` | 一件實際發生、需要持續追蹤的處理案件 |
| `WorkCaseUpdate` | 案件中每一筆不可互相覆蓋的實際處理進度 |

現有 `MaintenanceCard`／`MaintenanceCardCatalog` 只能保留為模板角色，不得再直接等同於使用者的保養項目。

完整角色、schema 修正邊界與資料限制見 `09-core-data-roles.md`。

## 2. 案件模型基線

第一版資料模型已建立；目前只定義角色與 JSON 格式，尚未接入正式 UI 寫入流程。

### `WorkCase`

代表一件實際處理中的保養、修理、工程或生活事件。

正式來源類型 `WorkCaseSourceType`：

- `maintenanceTask`：由某次保養任務開始
- `generalReminder`：由一般提醒轉入
- `milestone`：由階段性重點開始
- `manual`：使用者直接建立
- `unknown`：未來或未知來源的安全 fallback

正式案件類型 `WorkCaseType`：

- `maintenance`
- `repair`
- `construction`
- `administrative`
- `other`

正式案件狀態 `WorkCaseStatus`：

- `notStarted`
- `inProgress`
- `waiting`
- `completed`
- `canceled`

第一版欄位：

- `schemaVersion`
- `id`
- `itemId`
- `sourceType`
- `sourceId`（手動建立時可空）
- `caseType`
- `title`
- `description`
- `occurredAt`
- `startedAt`
- `status`
- `createdAt`
- `updatedAt`
- `closedAt`
- `closeResult`
- `cancellationReason`

`completed` 與 `canceled` 都屬於結案；取消案件必須能保存取消原因，不得直接消失。

### `WorkCaseUpdate`

代表案件中一筆不可被後續進度覆蓋的實際處理紀錄。

第一版欄位：

- `schemaVersion`
- `id`
- `workCaseId`
- `occurredAt`
- `description`
- `contactOrVendor`
- `result`
- `cost`
- `partsOrItems`
- `photoIdentifiers`
- `waitingReason`
- `note`
- `nextAction`
- `createdAt`

`partsOrItems` 與 `photoIdentifiers` 在模型中以不可修改清單保存。既有進度不得原地改寫；若需更正，未來應新增修正紀錄並保留原始事實。

正式中文介面名稱依情境顯示為保養／修理卡、工程卡、辦理卡或其他生活事件卡；底層角色保持一致。

## 3. 關聯原則

```text
Item 1 ── N MaintenancePlan
MaintenanceCardCatalog 1 ── N MaintenancePlan（選填模板來源）
MaintenancePlan 1 ── N Schedule
Item 1 ── N Schedule（一般提醒）
Schedule 1 ── N Task
Item 1 ── N WorkCase
WorkCase 1 ── N WorkCaseUpdate
Item 1 ── N HistoryView
```

- `MaintenancePlan` 回答「這個生活項目長期需要管理什麼」。
- `Schedule` 只表示時間規則，不得代替 MaintenancePlan。
- `Task` 只表示某次提醒已浮上檯面，不承擔完整案件過程。
- `MaintenanceCardCatalog` 是模板，不是使用者真實保養項目。
- `MaintenanceRecord` 保留支援舊資料，不直接假裝是完整案件史略。
- 一般提醒可由 Item 直接建立 Schedule／Task，不一定有 MaintenancePlan。
- 突發修理、工程或辦理事項可由 Item 直接建立 WorkCase。

## 4. 史略方案

批准方向：案件結案後封存為唯讀，史略是封存案件與舊版完成紀錄的統一查詢視圖。

原則：

- 結案後不刪除進度。
- 必要修正須留下修正紀錄，不直接改寫過去事實。
- 舊 `MaintenanceRecord` 可繼續顯示，無須偽造不存在的案件過程。
- 史略不是單一資料表名稱，而是可整合舊紀錄、結案案件與完整案件時間軸的查詢視圖。

## 5. 排程來源與類型

現有程式以特殊 `cardId` 字串辨識一般提醒，這是過渡技術債。

正式 Schedule 必須能明確表達來源，例如：

- `maintenancePlan`
- `generalReminder`
- `expiry`
- `milestone`

並保存可被驗證的 `sourceId` 或等效關聯。

原則：

- 保養排程應指向 MaintenancePlan。
- 一般提醒可以直接屬於 Item。
- 不得用空字串假裝不存在的外鍵。
- 遷移前不刪除舊 `cardId`，保持舊資料可讀。
- 遷移後才可逐步停止依靠特殊字串。

## 6. 固定週期計算

週期基準必須保留原時間尺度：

- 日、週、月、季、半年、年各自計算
- 月底、閏年、跨年需有測試
- 延遲完成預設從原到期基準推進，不從實際完成日任意漂移
- 使用者主動重新排程除外

## 7. 現有儲存

現況：SharedPreferences 以四組 JSON 字串保存：

- `items`
- `schedules`
- `tasks`
- `maintenance_records`

已建立：

- 舊 JSON 安全預設
- 逐筆解析
- 資料異常寫入鎖
- `backup_v1_*` 不可變原始備份

SharedPreferences 可暫時承接現有 MVP，但不適合作為大量案件、進度、照片與史略的長期正式儲存。

## 8. 正式資料庫遷移

正式選型已批准：Drift + SQLite；native 使用 `NativeDatabase`，Flutter Web 使用 `WasmDatabase`。完整證據、候選比較、風險與重新評估條件見 `07-database-decision.md`。

這項決策不代表可以直接搬移資料。遷移順序仍為：

```text
定義最終資料角色
→ 比較候選資料庫（已完成）
→ 建立 schema 與版本（案件 schema v1 已完成）
→ 補齊 MaintenancePlan 與正式 Schedule 來源角色
→ 保留原始備份
→ 新舊雙讀驗證
→ 匯入資料
→ 比對筆數與關聯
→ 真機驗收
→ 確認可回復
→ 才停止舊儲存
```

案件資料庫 schema v1 已建立，只包含 `work_cases` 與 `work_case_updates`。現有 App 尚未正式切換到 Drift，SharedPreferences 仍是運作中的舊資料來源。

`database/core-schema-v2` 目前只包含 enum converter、Items 草稿與 Schedules 草稿；因缺少 MaintenancePlan 與正式 Schedule 來源角色，暫停合併與後續施工。

正式 schema v2 應依序建立：

1. `items`
2. `maintenance_plans`
3. 重設計後的 `schedules`
4. `tasks`
5. `maintenance_records`
6. `work_cases.itemId` 正式關聯保護
7. schema v1 → v2 migration 與 rollback tests

在 schema v2 完整、migration 可回復、准入閘門通過前：

- 不匯入 SharedPreferences
- 不切換現有 Repository
- 不讓 UI 使用新核心表
- 不將舊 MaintenanceRecord 轉成 WorkCase

正式資料庫實作必須持續驗證：

- Flutter／iOS／Web 支援
- schema migration
- 查詢與關聯
- 照片識別管理
- 備份與匯出
- 長期維護性
- 測試便利性
- Web WASM 與 worker 實際部署

## 9. 資料格式原則

正式資料層需具備：

- schema version
- migration version
- 建立與更新時間
- 穩定 ID
- 明確 enum fallback
- 交易或原子寫入能力
- 備份與回復紀錄
- 欄位限制與外鍵策略

至少必須驗證：

- `MaintenancePlan.itemId` 指向存在的 Item。
- `Schedule.interval > 0`。
- `Item.expectedLifeYears` 若有值，必須大於 0。
- `Task.scheduleId` 可空時必須使用真正的 nullable 欄位，不得使用空字串。
- `MaintenanceRecord.taskId` 可空，支援補登完成紀錄。
- WorkCase、Schedule、Task、MaintenanceRecord 的刪除與封存政策需分開定義。

## 10. 照片與附件

照片不得只依靠容易失效的臨時路徑。

正式設計需包含：

- 穩定識別碼
- App 管理的檔案位置
- 新增、讀取、遺失、刪除生命週期
- 刪除資料時的孤兒檔案處理
- 備份與匯出
- iOS 與 Web 差異

## 11. 不可違反的資料安全規則

- 一筆資料失敗不得摧毀整組資料。
- 解析失敗不得偽裝成正常空清單。
- 異常狀態下不得覆寫來源。
- 未備份前不得進行格式遷移。
- 遷移失敗不得部分完成後繼續正常寫入。
- 不得用 UI 顯示方便作為破壞資料相容的理由。
- 不得讓舊 MVP 欄位結構反向決定正式產品角色。
