# 生活總覽 Drift 真實資料投影

狀態：正式控制文件
版本：v0.5.14
日期：2026-07-19
適用 PR：#215

## 1. 正式結論

生活總覽不再只是今日 Task 清單。首頁由既有 Drift 正式資料即時組合以下五個區塊：

1. 今天狀態
2. 今日提醒
3. 進行中案件
4. 階段性重點
5. 最近完成

首頁沒有獨立資料表、cache、fixture、writer 或第二套 History。所有畫面內容都能追溯至既有 Item、Task、WorkCase、WorkCaseUpdate、Milestone 與 History Projection。

## 2. 正式資料來源

| 首頁區塊 | 正式來源 | 規則 |
|---|---|---|
| 今天狀態 | 下列三組正式查詢的數量 | 顯示提醒、進行中案件、未關閉重點，不顯示完成率或評分 |
| 今日提醒 | Task Repository | 到期日不晚於今天，且狀態不是 completed／canceled |
| 進行中案件 | WorkCase Runtime | WorkCase.isOpen；最新 WorkCaseUpdate 可提供下一步或等待原因 |
| 階段性重點 | Milestone Repository | 只顯示未 completed／canceled／archived 的 Milestone |
| 最近完成 | History Projection | 只顯示正式 completed 事實，依 occurredAt 倒序 |

查詢從 Item 清單開始；跨 Item 的案件、重點與史略不得混淆所屬生活項目。

## 3. 領域邊界

- Task 只代表提醒，不因顯示在首頁而成為案件或史略。
- WorkCase 才代表正式案件；未結案案件不進最近完成。
- WorkCaseClosure 與正式 terminal facts 仍由 History Projection 組合，首頁不另存摘要。
- Milestone 與一般提醒分開呈現，不改成 MaintenancePlan。
- MaintenanceRecord 保持簡單完成事實，不補造 WorkCase 過程。
- 取消的案件、Task 或 Milestone 不得以「已完成」顯示。

## 4. 顯示與排序

- 今日提醒包含今天到期及先前到期但尚未終止的提醒；未到期提醒不顯示。
- 進行中案件依 WorkCase.updatedAt 新到舊排序，最多顯示前三筆，摘要數量仍使用全部正式資料。
- 階段性重點優先顯示處理中、已達標、已確認，再顯示 pending；最多三筆，摘要數量仍使用全部正式資料。
- 最近完成合併所有 Item 的正式 History entries，依 occurredAt 新到舊排序，最多三筆。
- 空狀態必須平靜說明目前沒有資料，不使用責備或焦慮文案。

## 5. 禁止事項

- 不得在首頁硬編假 Item、Task、WorkCase、Milestone 或完成紀錄。
- 不得讓 TodayScreen 直接操作 AppDatabase 或 Drift table。
- 不得新增 Home Repository、Home table、History writer 或平行資料真相。
- 不得把未結案 WorkCase、未完成 Task 或未完成 Milestone 放入最近完成。
- 不得因首頁顯示需要修改 Runtime、Schema、Migration 或正式資料 contract。

## 6. 防回歸 Gate

- 使用 in-memory Drift 建立正式 Item、Task、WorkCaseUpdate、Milestone 與 MaintenanceRecord，首頁必須顯示對應真實內容。
- 未到期 Task 不得出現在今日提醒。
- 查詢前後正式 Task、WorkCase、Milestone 與 MaintenanceRecord 筆數不變。
- 空資料不得出現 fixture 或示範內容。
- Item、Task、WorkCase、WorkCaseClosure 與 History 的角色檢查持續通過。
- Analyze、全部 tests、Web release build 與 GitHub Actions 全綠後才可合併。

## 7. 明確未修改

- 不修改 Runtime、Schema、Migration、Database 或 Repository／Service contract。
- 不新增寫入功能、產品功能、資料表、API、平行流程或下一個 PR。
- 不修改正式 App Shell、其他 Screen 或既有 Task 操作流程。
