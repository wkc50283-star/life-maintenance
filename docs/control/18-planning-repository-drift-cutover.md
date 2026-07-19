# Planning Repository Drift 切換

狀態：正式控制文件
版本：v0.5.5
日期：2026-07-19
適用 PR：#206

## 1. 正式範圍

只有當 AppCompositionRoot 驗證舊來源與不可變備份一致，且匯入器回報 `imported` 或 `alreadyImported`，MaintenancePlan、GeneralReminder、Milestone 與 Schedule 才切換為 Drift Repository。

本版本不切換 Task、MaintenanceRecord、WorkCase 或 WorkCaseClosure writer，不修改 Schema、Migration、Domain lifecycle 或 UI 視覺設計。

## 2. Repository 與轉換邊界

- MaintenancePlan 使用現有 Domain model 與 ordered MaintenancePlanStep mapper。
- GeneralReminder 使用 Schema v2 正式 row contract，不回寫舊 Schedule JSON。
- Milestone 使用現有 Domain model，且必須隸屬同一 Item。
- Schedule Runtime adapter 只對現有畫面暴露 Domain `Schedule`，UI 不接觸 Drift row。
- Schedule 必須有且只有一個 MaintenancePlan、GeneralReminder 或 Milestone source；`unknown` 只能保留舊資料，不得新建。

## 3. ScheduleAnchorPolicy

- `fixedCalendarPeriod` 是非 custom 新 Schedule 的正式預設。
- `completionBased` 只能保留已經明確存在的正式選擇；Runtime 轉換不得由舊 `strictPeriodMode = false` 自行推論。
- `userDefined` 必須同時保存 `userDefinedNextDate`，custom cycle 不得使用其他 anchor policy。
- 更新週期或下次日期時，必須保留既有 completion-based 選擇。

## 4. Transaction 與約束

新增一般提醒的寫入順序為 GeneralReminder → Schedule，全部位於同一 Drift transaction。整批 Runtime Schedule 更新也使用單一 transaction。

必須阻擋：

- 重複 Schedule ID。
- Schedule 跨 Item 移動。
- 沒有可驗證正式 source 的新 Schedule。
- 透過整批 list 寫入隱式刪除正式 Schedule。
- 修改已結束 Schedule、已封存 Plan／Reminder 或已結案 Milestone。
- 關聯 Task 或 closure follow-up 的資料被物理刪除。

任一驗證或寫入失敗時，GeneralReminder 與 Schedule 一起 rollback，不允許部分完成。

## 5. 單一 writer 與重啟驗證

- 切換後 planning 資料的唯一 writer 是 Drift。
- SharedPreferences 與 `backup_v1_*` 繼續唯讀，不刪除、覆蓋、mirror 或 fallback 寫入。
- 冷啟動可接受 planning 正式欄位的已批准變更，但 ID、Item、source type、source FK、legacy card 證據與 createdAt 必須與原匯入身分一致。
- Item、Task、MaintenanceRecord 與 Attachment 仍使用嚴格逐欄匯入比對，不因 planning 切換放寬。
- 身分不一致、FK 錯誤或 database integrity 失敗時，Runtime 不得進入 planning cutover。

## 6. 未切換角色

Task 仍只是某次提醒，本 PR 不開啟 Task writer。WorkCase 仍是事情正式發生，WorkCaseClosure 仍是正式結案，History 仍只是投影。Planning Repository 不得建立或代替這些流程。

## 7. 驗收

- MaintenancePlan／Step、GeneralReminder、Milestone 與 Schedule CRUD／mapper／constraint 測試。
- GeneralReminder／Schedule 原子 transaction 與中途失敗 rollback。
- 三種 Schedule source、ScheduleAnchorPolicy、結束不可變與禁止隱式刪除測試。
- 修改 planning 資料後的冷啟動／重啟驗證。
- SharedPreferences 與備份原文零寫入。
- codegen、Analyze、全部 tests、Web release build、CI 與 Web 預覽通過。
