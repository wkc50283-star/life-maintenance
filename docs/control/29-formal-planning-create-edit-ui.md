# 正式規劃資料新增與編輯 UI

狀態：正式控制文件
版本：v0.5.16
日期：2026-07-19
適用 PR：#217

## 1. 正式範圍

本版本為 Item、ItemCategory、MaintenancePlan／MaintenancePlanStep、GeneralReminder、Milestone 與 Schedule／ScheduleAnchorPolicy 提供正式新增與編輯畫面。畫面只透過既有 AppCompositionRoot 建立的 Drift Schema v2 Repository 寫入，不建立第二套儲存、服務或生命週期。

## 2. 使用者入口

- 「新增」主入口以白話區分生活項目、分類、保養項目與步驟、一般提醒、階段性重點與提醒排程。
- 每一類入口先顯示既有正式資料，再提供新增與編輯。
- Item 詳情可編輯主資訊，並可從保養、一般提醒、排程與階段性重點區塊進入同一套正式管理畫面。
- 不顯示 Domain class 名稱、資料庫欄位、內部 ID 或平台路徑。

## 3. 領域與資料邊界

- Item 仍是所有規劃內容的 Root；表單不得跨 Item 建立關聯。
- MaintenancePlan 是長期保養內容，Step 只保存標準流程，不保存某次完成狀態。
- GeneralReminder 與 MaintenancePlan 分離。
- Milestone 保持階段性重點／大修角色，不代替一般保養。
- Schedule 必須且只能選擇一個既有 MaintenancePlan、GeneralReminder 或 Milestone；建立後來源不可由 UI 更換。
- `fixedCalendarPeriod` 是一般週期預設；`completionBased` 必須由使用者明確選擇；custom 週期只能使用 `userDefined` 並保存指定日期。
- 本版本不建立或修改 Task、WorkCase、WorkCaseClosure、MaintenanceRecord、History 或 Attachment。

## 4. 寫入與安全規則

- UI 不直接執行 SQL，也不建立 AppDatabase 或 Repository。
- Presentation editor 只轉換表單值，真正寫入仍由既有 Drift Repository 執行。
- MaintenancePlan 與全部 Step 使用既有單一 transaction 保存。
- Milestone 與 Schedule 使用既有 transaction、同 Item 與來源契約驗證。
- 已封存 Category、Item、MaintenancePlan、GeneralReminder、已結案 Milestone 與已結束 Schedule 維持唯讀。
- 舊 `unknown` Schedule 來源只保留，不允許由 UI 新建或改寫。
- UI 不提供物理刪除，不刪除、覆蓋或改寫 SharedPreferences／`backup_v1_*`。

## 5. 驗收 Gate

- 六個正式管理入口使用一般生活語言，沒有技術模型名稱。
- Category／Item／Plan／Step／Reminder／Milestone／Schedule 可經正式 Repository round-trip。
- Schedule 保留唯一 source 與 AnchorPolicy。
- Item 詳情使用正式完整頁面管理入口，不增加 Bottom Sheet 流程。
- production Screen 不 import AppDatabase、SharedPreferences、LocalRepository 或 LocalStorageService。
- codegen、Analyze、全部 tests、Web release build、手機尺寸預覽與 GitHub Actions 全綠後才可合併。

## 6. 明確未修改

不修改 Schema、Migration、AppCompositionRoot／AppRuntimeDependencies contract、Legacy import／recovery、Task／案件／結案／史略流程、主導覽、資料表、API 或其他產品功能；不開始下一個 PR。
