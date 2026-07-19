# 正式 Task 提醒與開始處理流程

狀態：正式控制文件
版本：v0.5.17
日期：2026-07-19
適用 PR：#218

## 1. 正式範圍

本版本建立 Task 提醒詳情、正式來源投影、單次重新安排、暫停／恢復，以及「開始處理 → WorkCase」流程。所有讀寫只經 AppCompositionRoot 注入的 Drift Runtime，沒有第二套提醒、案件、結案或史略流程。

## 2. 領域邊界

- Task 只代表某一次需要被留意的提醒，不是案件、結案或歷史。
- Schedule 仍是時間規則；重新安排只改該次 Task 的 `dueDate`，不改 Schedule 規則或 AnchorPolicy。
- 開始處理只呼叫既有 `WorkCaseRuntime.createFromTask` 建立進行中 WorkCase。
- Task 與 WorkCase 必須屬於同一 Item，且 WorkCase 來源沿用正式 Task source contract。
- 開始處理不修改 Task 狀態、不建立 WorkCaseClosure、不建立 MaintenanceRecord，也不直接寫入 History。
- History 繼續由正式資料唯讀投影，不新增 History 寫入入口或資料表。

## 3. 提醒狀態與交易規則

- 暫停使用既有 `postponed` 狀態及 `postponedAt`，不新增 Schema 欄位。
- 恢復只允許 `postponed` Task，清除 `postponedAt`，並依提醒日與當日恢復為 `pending` 或 `overdue`。
- 重新安排只允許未終止 Task；Task 若已暫停，改日期後仍保持暫停，直到使用者明確恢復。
- `completed` 與 `canceled` Task 維持不可變。
- 所有 Task 狀態／日期更新使用 Drift transaction 與既有 Repository 同 Item／來源驗證。
- 同一 `scheduleId + dueDate` 已有 Task 時拒絕重排，transaction 完整 rollback。
- 產生器若發現同一 Schedule 仍有已移至原到期日之後的未終止 Task，不得在冷啟動重新產生原日期實例；已終止的較早實例不阻擋下一週期。

## 4. 畫面與文案

- 生活總覽的提醒可進入正式完整詳情，顯示所屬 Item、日期、狀態、來源與排程基準。
- 「查看全部」保留暫停中的提醒入口，使暫停不是遺失或刪除。
- 介面提供「重新安排」「暫停提醒／恢復提醒」與「開始處理」，不提供 Task 完成、結案或寫入史略操作。
- 「開始處理」只收集案件名稱、事情類型與可稍後補充的目前狀況，建立狀態為 `inProgress` 的 WorkCase。
- 文案保持平和，不以紅色逾期、倒數、完成率或責備方式評價生活。

## 5. 資料安全與驗收 Gate

- 不修改 Drift Schema 或 Migration，不刪除或覆蓋既有資料。
- 不讀寫 SharedPreferences、`backup_v1_*` 或 Legacy Runtime。
- Repository 測試驗證來源投影、暫停／恢復、重排唯一性與 rollback。
- 測試驗證開始處理前後 Task row 完全相同，且只新增開放中的 WorkCase。
- Widget 測試驗證正式入口、白話文案、暫停後可恢復，以及不存在 Task 完成／Closure／History 操作。
- codegen、Analyze、全部 tests、Web release build、手機尺寸預覽與 GitHub Actions 全綠後才可合併。

## 6. 明確未修改

不修改 Schema、Migration、Schedule 規則、WorkCaseUpdate／WorkCaseClosure、MaintenanceRecord、History Projection、Attachment、SharedPreferences／Legacy recovery、主導覽、其他 UI 功能或其他領域；不開始下一個 PR。
