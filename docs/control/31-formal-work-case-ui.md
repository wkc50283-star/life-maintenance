# 正式 WorkCase UI 控制規格

狀態：正式控制文件

版本：v0.5.18

適用範圍：PR #219

## 1. 正式定位

WorkCase UI 承接已經開始處理的生活事件。Task 仍只是提醒；WorkCaseUpdate 保存每一次過程；WorkCaseClosure 是唯一正式終止來源；History 只由正式資料投影。

## 2. 畫面與入口

- 案件清單分為進行中與已結案件。
- 首頁生活總覽及 Item 詳情的案件卡片進入同一正式案件詳情。
- 案件詳情呈現 Item、案件類型、來源、建立／開始時間、說明、目前狀態及全部 Update。
- 每筆 Update 呈現日期、說明、廠商／聯絡人、結果、費用、零件／品項、等待原因、下一步、備註及附件數量。

## 3. 正式寫入邊界

- 新增進度只呼叫正式 WorkCase Runtime；Update 與案件狀態在同一 transaction 中寫入。
- 正式結案只呼叫 `close`，由唯一 WorkCaseClosure 與 completed 狀態在同一 transaction 中寫入。
- 取消案件只呼叫 `cancel`，由唯一 WorkCaseClosure 與 canceled 狀態在同一 transaction 中寫入。
- 終止後主資訊、Update 與 Closure 全部唯讀。
- UI 不直接操作 Drift table，也不建立 History 或 MaintenanceRecord 平行寫入。

## 4. 附件邊界

本畫面只查詢 Attachment Runtime 中正式屬於 WorkCaseUpdate 或 WorkCaseClosure 的附件，顯示原始檔名、種類與生命週期狀態。UI 不保存或顯示平台實體路徑，也不把 storage identifier 當成檔名。

本 PR 不新增檔案選擇、複製、雜湊或 managed storage ingestion service；在正式匯入服務存在前，不得以文字路徑或只寫 metadata 的假上傳替代。

## 5. 禁止事項

- 不修改 Schema、Migration 或 Domain model。
- 不讓 Task 直接結案或寫入 History。
- 不另建案件、進度、結案、附件或歷史流程。
- 不直接改 WorkCase 終止狀態冒充 Closure。
- 不允許終止案件繼續新增或修改進度。
