# 正式 History Projection 與 Attachment Runtime

狀態：正式控制文件
版本：v0.5.8
日期：2026-07-19
適用 PR：#209

## 1. 正式範圍

本版本建立唯讀 History Projection 與 Attachment Runtime。只有 AppCompositionRoot 完成舊來源備份、完整性檢查及 Drift 匯入驗證後，兩者才可被注入。

本版本不接 UI、不修改 Schema 或 Migration、不新增 History table、cache 或 writer，也不寫入 SharedPreferences。

## 2. History 只有一份正式真相

History 由下列正式資料即時組合：

- 已終止的 WorkCase
- 多筆 WorkCaseUpdate
- 唯一 WorkCaseClosure；舊案件沒有 Closure 時保持缺漏，不補造
- MaintenanceRecord 舊完成事實
- terminal Task 的提醒事實
- terminal Milestone 的階段事實
- 各正式 Owner 的 Attachment metadata

Projection 依 Item 查詢並按事件時間倒序排列。Task 仍是提醒、WorkCase 仍是案件、WorkCaseClosure 仍是結案；MaintenanceRecord 不轉造成案件，History 不提供 create、save、update 或 delete API。

## 3. Attachment 正式 abstraction

- 新附件必須使用穩定 managed identifier，不接受絕對平台路徑、`file:`、`content:` 或平台照片 URI。
- Identifier、MIME、Hash、byte size、ownerType、ownerId、狀態與生命週期時間由 Attachment abstraction 管理。
- Owner 必須是存在的 Item、MaintenanceRecord、WorkCaseUpdate、WorkCaseClosure 或 Milestone；不存在或 unknown Owner 會阻擋 transaction。
- 新附件只能從 available 開始；missing 必須保存 missingAt，重新驗證後回到 available 並清除 missingAt。
- deleted 必須保存 deletedAt，且一旦 deleted 不得恢復、重複刪除或改寫。
- `recordStorageDeleted` 只可在 managed storage 已確認實體內容刪除後呼叫；資料列不作實體刪除，避免孤兒 metadata 與歷史斷裂。

## 4. Runtime 與資料安全

- AppCompositionRoot 是 History／Attachment 正式實例的唯一建立與注入位置。
- 匯入或驗證失敗時不注入新 Runtime，並維持既有 rollback 行為。
- SharedPreferences 與 `backup_v1_*` 全程唯讀，不新增 key、不雙寫、不刪除或覆蓋。
- Projection 查詢不修改 WorkCase、Update、Closure、Record、Task、Milestone 或 Attachment。

## 5. 驗收

- 完整案件、簡單 MaintenanceRecord、terminal Task、terminal Milestone 與各 Owner Attachment 組合查詢。
- open WorkCase 不進入完成史略；舊 terminal WorkCase 沒有 Closure 時不補造資料。
- Projection 前後正式來源列數與內容不變。
- Attachment platform path、unknown／orphan Owner、非法狀態轉換與倒退時間被阻擋。
- missing → available、available／missing → deleted 與 deleted 後不可變有測試。
- codegen、Analyze、全部 tests、Web release build、CI 與 Web 預覽通過。
