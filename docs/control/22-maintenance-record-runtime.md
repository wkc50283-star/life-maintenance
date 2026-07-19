# 正式 MaintenanceRecord Runtime

狀態：正式控制文件
版本：v0.5.9
日期：2026-07-19
適用 PR：#210

> 歷史基線：本文件記錄 v0.5.9／PR #210 建立正式 MaintenanceRecord Runtime 時的注入策略。自 v0.5.11／PR #212 起，Items／History 統一讀取 Drift，啟動失敗改進入 Drift 唯讀安全狀態；現行規則以 `24-drift-safe-runtime-and-maintenance-record-read-cutover.md` 為準。

## 1. 正式角色

MaintenanceRecord 是已完成的簡單處理事實，不是案件、案件進度或正式案件結案。

- 舊匯入紀錄維持原本事實，不補造 WorkCase 或 WorkCaseClosure。
- 新事件只有在不需要等待、多筆進度、廠商協調或正式結案時，才可建立 MaintenanceRecord。
- 需要處理過程的事件必須走 WorkCase → WorkCaseUpdate → WorkCaseClosure。
- WorkCaseClosure 不複製為 MaintenanceRecord；History 從兩種正式來源投影。

## 2. 正式寫入入口

- `createSimpleRecord`：建立沒有 Task 的手動簡單完成事實。
- `completeSimpleTask`：在單一 Drift transaction 內建立紀錄並把 Task 更新為 completed。
- 不提供 generic update、delete 或 WorkCaseClosure → MaintenanceRecord writer。
- 同一 Task 最多建立一筆 MaintenanceRecord；terminal Task、已進入 WorkCase 的來源及跨 Item 關聯一律阻擋。

## 3. 關聯與附件

- MaintenanceRecord 必須隸屬有效 Item。
- Task、MaintenancePlan 若存在，必須與紀錄屬於同一 Item。
- 新附件只能透過 Attachment Runtime 寫入 stable managed identifier；MaintenanceRecord Runtime 不接受平台路徑或 legacy photo identifier。
- 舊匯入附件 metadata 仍按既有 Attachment 狀態保存，不覆寫來源。

## 4. Runtime 與資料安全

- AppCompositionRoot 只在備份、完整性檢查及匯入驗證成功後注入正式 Repository。
- 匯入或啟動驗證失敗時不注入 Repository，維持既有 rollback 與 Legacy Runtime。
- SharedPreferences 與 `backup_v1_*` 僅作唯讀回復來源，不雙寫、不刪除、不覆蓋。
- 任一驗證或資料庫寫入失敗時，Task 與 MaintenanceRecord transaction 完整 rollback。

## 5. History Projection 驗收

- 舊匯入與新簡單紀錄均由相同 domain mapping 讀取並進入 History Projection。
- MaintenanceRecord 不產生 WorkCaseClosure；WorkCaseClosure 不產生 MaintenanceRecord。
- Projection 不寫入第三套 History 真相。
- codegen、Analyze、全部 tests、Web release build、CI 與預覽驗證必須通過。
