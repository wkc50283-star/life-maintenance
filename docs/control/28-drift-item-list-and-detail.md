# 生活項目清單與完整 Item 詳情 Drift 投影

狀態：正式控制文件
版本：v0.5.15
日期：2026-07-19
適用 PR：#216

## 1. 正式結論

生活項目清單與 Item 詳情只呈現既有 Drift 正式資料。Item 詳情是完整頁面，不是主要 Bottom Sheet，也沒有專屬資料表、cache、writer 或另一套案件、史略、附件流程。

## 2. Item Root 與資料來源

| 區塊 | 正式來源 | 顯示責任 |
|---|---|---|
| 生活項目清單／主資訊 | ItemReadRepository | Item 名稱、分類、狀態、位置與正式欄位 |
| 保養項目 | MaintenancePlan Repository | 長期保養內容、風險、狀態與既有排程摘要 |
| 一般提醒 | GeneralReminder Repository | 非保養型提醒，不與 MaintenancePlan 混合 |
| 提醒與排程 | Schedule Repository | 正式時間規則、下次日期與狀態，不代替 Task |
| 階段性重點／大修 | Milestone Repository | 觸發條件、目標與狀態；大修保持 Milestone 角色 |
| 案件 | WorkCase Runtime | 分開呈現進行中與已終止案件；最新更新只屬案件過程 |
| 史略 | History Projection | 由案件、結案、MaintenanceRecord、Task、Milestone 組合的唯讀投影 |
| 附件 | History Projection／Attachment Runtime | 顯示正式 metadata 與生命週期狀態，不操作平台路徑 |

所有查詢以同一個 Item id 為邊界，不得混入其他 Item 的資料。

## 3. 導覽與 UI 邊界

- 生活項目卡使用正式 Navigator route 進入 `ItemDetailScreen`。
- 主要 Item 詳情不得呼叫 `showModalBottomSheet`。
- 詳情頁不得提供尚未接正式寫入的假按鈕或假入口。
- 空資料使用平靜文字；讀取錯誤必須明確呈現並允許重新讀取，不得把錯誤偽裝成空資料。
- 畫面不得顯示內部資料 id、附件 managed identifier 或平台實體路徑。

## 4. 領域邊界

- Item 是所有顯示內容的 Root。
- MaintenancePlan 是長期保養內容，不是某次 Task 或案件。
- GeneralReminder 與 MaintenancePlan 分離。
- Schedule 是規則，Task 是提醒實例；詳情顯示排程不改變 Task。
- Milestone／大修保持獨立角色。
- WorkCase 才是正式案件；WorkCaseUpdate 是過程；WorkCaseClosure 才是正式結案。
- History 只讀組合正式資料，不新增寫入真相。
- Attachment 只透過正式 abstraction 管理；畫面不得把 storage identifier 當檔案路徑使用。

## 5. 防回歸 Gate

- 空 Drift 顯示真實空狀態，不出現 fixture 或示範生活項目。
- 正式 Drift fixture 必須在完整 Item route 顯示所有核准區塊。
- 開啟詳情後不得存在主要 Bottom Sheet。
- 其他 Item 的資料不得出現在目前詳情。
- 投影前後 MaintenancePlan、GeneralReminder、Schedule、WorkCase、MaintenanceRecord 與 Attachment 筆數不變。
- production Screen 不得 import AppDatabase、SharedPreferences、LocalRepository 或 LocalStorageService。
- codegen、Analyze、全部 tests、Web release build、預覽與 GitHub Actions 全綠後才可合併。

## 6. 明確未修改

- 不修改 Schema、Migration、Database、Runtime、Repository／Service contract。
- 不新增正式寫入、資料表、API、產品功能、平行流程或下一個 PR。
- 不刪除 Legacy 程式或既有資料。
