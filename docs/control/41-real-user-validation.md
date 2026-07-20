# Real User Validation（PR #229）

狀態：正式控制文件
版本：v0.5.28
日期：2026-07-20

## 1. 範圍與結論

本次只用既有 Domain、Schema v2、Repository、Runtime 與 UI 驗證真實生活事項能從建立 Item、保養計畫與提醒，進入正式案件、留下多筆進度、正式結案，最後由 History Projection 查回完整史略。未修改 Schema、Migration、Domain 或 UI 設計。

稽核發現一項阻擋性問題：App Shell 的正式「史略」頁仍只讀 MaintenanceRecord，WorkCaseClosure 雖已存在於 History Projection，使用者卻無法在史略入口看到正式案件結果。此頁已最小切換至既有 HistoryProjectionRepository；History 仍為唯讀投影，沒有新增資料表、writer 或平行流程。

## 2. 真實生命週期 Gate

測試以檔案 SQLite 資料庫執行下列流程：

1. 第一天建立 Item、MaintenancePlan、Schedule 與依來源契約產生的 Task。
2. 從 Task 開始 WorkCase；Task 只保留提醒角色，不直接完成、不建立 Closure 或 History。
3. 關閉資料庫後於第二天冷啟動，加入第一筆 WorkCaseUpdate 並進入等待狀態。
4. 再次關閉資料庫後於第五天冷啟動，加入第二筆 Update，並以唯一 WorkCaseClosure 正式結案。
5. 驗證 Task 原始內容未被案件結案改寫，History Projection 組合案件、兩筆進度、唯一結案與來源 Task。

此 Gate 同時鎖定 Item 為 Root、Task 為提醒、WorkCase 為案件、WorkCaseClosure 為正式結案、History 為投影。

## 3. 備份、還原與完整性

- 只在資料庫關閉且一致時複製正式 SQLite 檔案，模擬既有安全備份與災難回復邊界。
- 從備份建立還原資料庫後重新初始化 AppCompositionRoot。
- 逐項驗證 Item、MaintenancePlan、兩筆 Update、唯一 Closure 與 History Projection。
- 原資料庫執行 `PRAGMA foreign_key_check`，還原資料庫執行 `PRAGMA integrity_check`；任一異常均使測試失敗。
- 測試暫存資料於結束後移除，不接觸正式使用者資料。

## 4. Web 與手機操作

- 手機 Widget Gate 使用 390×844 尺寸，驗證正式史略可呈現案件摘要、結果、進度數量，並可進入案件詳情查看完整 Update 與 Closure；內部識別碼不顯示給使用者。
- Web 驗收使用 release artifact 與正式 Drift Web worker／WASM，實際以既有 UI 建立 Category、Item 與 MaintenancePlan，重新整理後由 Item 詳情確認資料仍由 Drift 讀回；其後的 Task → WorkCase → Update → Closure → History 操作由同一正式 Runtime 的 Widget／檔案資料庫生命週期 Gate 覆蓋，不以文件冒充瀏覽器人工操作。
- Android 與 iOS 以正式平台 build 加既有跨平台輸入、導覽、尺寸與完整主流程測試共同驗收；沒有為特定平台建立另一套資料流程。

## 5. 資料角色與回復

- `HistoryScreen` 只讀既有 HistoryProjectionRepository，沒有直接寫入 History。
- MaintenanceRecord 仍只表示不需要案件過程的簡單完成紀錄；需要過程與結案的事件維持 WorkCase → WorkCaseClosure。
- 本 PR 沒有 Schema、Migration 或資料格式變更，不需要資料 rollback。
- 若需回復本 PR，只還原史略讀取接線、測試、版本與文件；既有 Drift 資料不刪除、不覆蓋。

## 6. 合併 Gate

codegen 必須無差異，Analyze、全部 tests、Web release、Android release、iOS Simulator build 與 GitHub Actions 必須全綠。實際環境無法提供的裝置或簽章項目必須明確記錄，不得以自動測試冒充真機結果。
