# 生活管理 App 架構與資料設計書

狀態：正式控制文件  
本文件定義資料角色、關聯與遷移原則；具體資料庫選型須另行驗證。

## 1. 現有可保留模型

| 現有模型 | 正式角色 |
|---|---|
| `Item` | 生活項目 |
| `MaintenanceCard` | 保養項目與標準操作內容 |
| `MaintenanceStep` | 標準保養步驟，不是實際處理進度 |
| `Schedule` | 固定週期、日期與提醒安排 |
| `Task` | 某次到期或待處理提醒實例 |
| `MaintenanceRecord` | 既有完成結果與舊版歷史資料 |

現有模型不得僅因名稱不完美而全部推翻。任何重構必須先證明資料角色衝突與最小遷移方案。

## 2. 案件模型基線

第一版資料模型已建立；目前只定義角色與 JSON 格式，尚未接入 Repository、正式資料庫或 UI 寫入流程。

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
Item 1 ── N MaintenanceCard
Item 1 ── N Schedule
Schedule 1 ── N Task
Item 1 ── N WorkCase
WorkCase 1 ── N WorkCaseUpdate
Item 1 ── N HistoryView
```

- `Task` 只表示提醒已浮上檯面，不承擔完整案件過程。
- `MaintenanceCard` 是標準規則，不承擔某次事件狀態。
- `MaintenanceRecord` 保留支援舊資料，不直接假裝是完整案件史略。

## 4. 史略方案

批准方向：案件結案後封存為唯讀，史略是封存案件與舊版完成紀錄的統一查詢視圖。

原則：

- 結案後不刪除進度。
- 必要修正須留下修正紀錄，不直接改寫過去事實。
- 舊 `MaintenanceRecord` 可繼續顯示，無須偽造不存在的案件過程。

## 5. 排程類型

現有程式以特殊 `cardId` 字串辨識一般提醒，這是過渡技術債。

目標新增正式類型欄位，例如 `scheduleKind`：

- maintenance
- generalReminder
- expiry
- milestone

遷移前：

- 不刪除舊 `cardId`
- 集中特殊字串判斷
- 保持舊資料可讀

遷移後才可逐步停止依靠特殊字串。

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
→ 建立 schema 與版本
→ 保留原始備份
→ 新舊雙讀驗證
→ 匯入資料
→ 比對筆數與關聯
→ 真機驗收
→ 確認可回復
→ 才停止舊儲存
```

下一個資料庫批次只允許建立空的 schema v1、`work_cases`／`work_case_updates` tables、transaction tests 與 native／web 開啟基礎；不得同時匯入舊 SharedPreferences 資料。

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
