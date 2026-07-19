# UI Audit

狀態：正式控制文件

版本：v0.5.22

日期：2026-07-19

適用 PR：#223

## 1. 稽核結論

本次逐頁檢查 overflow、SafeArea、Loading／Empty／Error、字級、間距、圖示與深色系統環境，只修正三個會阻擋或誤導使用者的狀態問題：

1. AppCompositionRoot 初始化失敗時原本沒有 Error／Retry，畫面會停在 Loading。
2. 生活總覽尚未載入時原本先顯示零筆空資料；讀取失敗則沒有 Error／Retry。
3. 史略尚未載入時原本先顯示空史略；讀取失敗會成為未處理錯誤。

修正後三處均清楚區分 Loading、Empty 與 Error，錯誤畫面說明資料未被刪除或提供重新讀取，不顯示技術例外。

## 2. 逐頁矩陣

| 畫面 | Overflow／SafeArea | Loading／Empty／Error | 字級／間距／圖示 | 結論 |
|---|---|---|---|---|
| App Shell | AppBar、Scaffold、NavigationBar 正確承接系統區域 | 補上初始化 Error／Retry | 五個入口圖示與白話標籤一致 | 阻擋項已修正 |
| 生活總覽 | ListView 可滾動，小尺寸卡片無 overflow | 補上真實 Loading 與 Error／Retry；原有分區 Empty 保留 | 主視覺、標題與卡片層級清楚 | 阻擋項已修正 |
| 生活項目 | 可滾動，底部間距不被 NavigationBar 遮擋 | 原有 Loading／Empty／Error／Retry 完整 | 項目圖示、狀態與卡片間距一致 | 通過 |
| Item 詳情 | 完整 Scaffold 頁面與 ListView；不是 Bottom Sheet | 原有 Loading／分區 Empty／Error／Retry 完整 | 區塊標題與資料層級可辨識 | 通過 |
| 新增／Planning | 長表單可滾動，儲存區使用 SafeArea | 管理清單與來源載入已有 Loading／Empty／Error | 表單字級、間距與圖示可讀 | 通過 |
| Task | 清單、詳情與操作區可滾動 | 原有 Loading／Empty／Error／Retry 完整 | 提醒與開始案件入口角色清楚 | 通過 |
| WorkCase／Closure | 時間軸與表單可滾動，底部操作使用 SafeArea | 原有 Loading／Empty／Error／Retry 完整 | 案件、進度、附件與結案層級清楚 | 通過 |
| 史略 | ListView 可滾動，小尺寸空狀態無 overflow | 補上真實 Loading 與 Error／Retry；Empty 保留 | 標題、月份與紀錄卡層級清楚 | 阻擋項已修正 |
| 設定 | ListView 與 Bottom Sheet 安全區完整 | 靜態可用內容不需要非同步狀態 | 安全圖示與高風險說明清楚 | 通過 |

## 3. 深色系統環境

目前正式視覺只核准完整暖色 light palette，許多既有元件仍使用該固定 palette。App 在系統深色環境會一致維持 light theme，不會只切換 Scaffold 而造成深底深字、卡片對比破壞或不可讀狀態。

320×568 Widget Gate 已在 `Brightness.dark` 環境驗證五個主分頁無 overflow 或例外。建立真正 dark palette 需要逐元件 token 化、對比與手機畫面批准，屬正式 UI 改版，不得在本次「只修阻擋項」PR 擅自展開。

## 4. 手機預覽證據

- 390×844：生活總覽、生活項目、新增、史略、設定逐頁實際 Web preview。
- 320×568：小尺寸生活總覽與五個 NavigationBar 標籤。
- 放大字體：Widget test 使用 1.3 text scale 驗證五個主分頁。
- 預覽結果：無 RenderFlex overflow、文字截斷、底部遮擋或瀏覽器 warning／error。
- 空資料：所有主分頁使用空 Drift database 驗證，不以假資料代替。

## 5. 資料與回復影響

- 不修改 Schema、Migration、Domain、Repository 或資料。
- 不新增功能或改變 Task／WorkCase／Closure／History 生命週期。
- UI Error handling 只捕捉既有讀取／初始化錯誤並提供重試，不 fallback、不寫 Legacy source。
- 回復只需還原本 PR 的 UI state、tests、文件與版本變更；不需要資料 rollback。

## 6. 明確未修改

- 不重畫 UI、不建立新功能或新導覽。
- 不改 Schema、Migration、Domain、Repository contract 或 CompositionRoot 行為。
- 不做完整 dark palette 改版、無關元件 token 化或全面色彩重構。
- 不修改已通過的畫面只為統一風格。
- 不開始下一個 PR。

## 7. 驗收

- 小尺寸、放大字體、深色系統環境與 Error／Retry Widget tests。
- Drift code generation 無差異。
- Flutter Analyze。
- 全部 Flutter tests。
- Web release build。
- 390×844 與 320×568 手機預覽。
- GitHub Actions 全綠後才可 squash merge。
