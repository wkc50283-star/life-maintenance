# History Experience Validation

狀態：正式控制文件

版本：v0.5.36

日期：2026-07-21

適用 PR：#237

## 1. 正式結論

正式「史略」入口持續由 `HistoryProjectionRepository` 即時查詢 Drift 正式事實。History 沒有獨立資料表、cache 或 writer，也不提供 create、save、update 或 delete；本次驗收沒有發現需要修改 production code 的阻擋問題。

Item 仍是所有投影的 Root；Task 只代表提醒；WorkCase 保存案件；WorkCaseUpdate 保存多筆過程；WorkCaseClosure 是唯一正式結案來源。History 只組合並呈現上述事實，不改寫或補造來源。

## 2. 畫面狀態

- Loading：Item 與各 Item History 尚未全部讀取完成前顯示載入狀態，不得先顯示空史略。
- Empty：正式查詢完成且沒有 History entry 時，顯示平靜的空狀態，不放入 fixture 或假資料。
- Error：任一正式讀取失敗時顯示可理解的錯誤狀態，不洩漏技術細節。
- Retry：使用者重新讀取後，再次從同一 Item Repository 與 History Projection 查詢；成功時移除錯誤狀態並顯示正式內容。

本 PR 只驗收既有狀態與行為，不修改正式 UI 設計、Theme、版面或導覽。

## 3. 投影與排序一致性

- 只投影 terminal WorkCase；進行中案件不得進入史略。
- WorkCase entry 保存多筆 WorkCaseUpdate、唯一 WorkCaseClosure 與正式相關 Task；不得將 Task 重複投影成另一筆案件事實。
- 舊 terminal WorkCase 沒有 Closure 時誠實保留缺漏，不補造結案。
- MaintenanceRecord 保留簡單完成事實，不轉造成 WorkCase。
- terminal Task 與 Milestone 只有在未被其他正式 entry 承接時才獨立呈現。
- 全部 History entry 依 `occurredAt` 新到舊排列；同一時間以 `sourceId` 穩定排序。
- 跨 Item 關聯不一致時阻擋投影，不混合不同生活項目的資料。

## 4. 唯讀與冷啟動 Gate

- 查詢前後 Item、Task、WorkCase、WorkCaseUpdate、WorkCaseClosure、MaintenanceRecord、Milestone 與 Attachment row count 必須一致。
- History Repository interface 只保留 `projectForItem` 查詢，不得新增寫入 API。
- 以檔案 Drift database 完整關閉並重新開啟後，同一 Item 的案件、Updates、Closure、相關 Task 與 History entry 必須一致。
- 冷啟動不得切回 SharedPreferences、LocalRepository、fixture 或其他平行 read model。

## 5. 資料與回復

本 PR 不操作正式使用者資料，不修改 Schema、Migration、Domain、Runtime 或 Repository contract。程式回復只還原 tests、版本與文件；不得刪除、搬移或覆蓋 Drift、SharedPreferences 或 `backup_v1_*`。

## 6. 防回歸驗收

- History Loading 與 Empty 明確分離。
- Error 後 Retry 可恢復正式 History entry。
- WorkCase／Update／Closure、MaintenanceRecord、Task、Milestone 的組合與事件排序正確。
- History 查詢前後正式來源列數不變。
- 檔案資料庫跨日冷啟動後投影一致。
- Drift codegen 無差異、Analyze、全部 tests、Web／Android／iOS build 與 GitHub Actions 全綠後才可合併。

## 7. 明確未修改

- 不新增功能、History writer、table、cache、API 或平行真相。
- 不修改 UI 設計、Domain、Schema、Migration、正式生命週期或資料格式。
- 不開始下一個 PR。
