# Product Constitution Audit

狀態：正式控制文件

版本：v0.5.23

日期：2026-07-20

適用 PR：#224

## 1. 稽核目的

正式 Runtime 的畫面、文案與狀態必須協助使用者記住生活事項、開始處理、保留過程並回顧結果。介面不得用催促、責備、評分、KPI、打卡、焦慮倒數或待辦完成率管理使用者。

「承接責任」是產品行為原則，不是使用者介面的抽象名稱。依產品憲法，正式畫面仍使用生活項目、提醒、案件、結案與史略等直接白話用語。

## 2. 逐頁稽核

| 畫面 | 承接責任與正式角色 | 催促／KPI／To-do 風險 | 結論 |
|---|---|---|---|
| App Shell | 以生活總覽、生活項目、新增、史略與設定承接完整生活資料 | 無評分、打卡或待辦入口 | 通過 |
| 生活總覽 | 分開呈現提醒、案件、階段性重點與最近完成 | 將「待處理／已逾期」改為「已安排／日期已過」 | 已修正 |
| 生活項目與詳情 | Item 保持所有保養、提醒、排程、案件、史略與附件的 Root | Milestone「目標／達標」帶有 KPI 語感，改為中性條件描述 | 已修正 |
| 新增與規劃 | 允許先建立 Item，再逐步補上管理內容 | 不要求一次填完所有生活資料，無完成率 | 通過 |
| Task 提醒 | 可重排、暫停、恢復或開始案件；提醒本身保留 | 移除共用 Task 卡殘留的直接「完成」按鈕 API | 已修正 |
| WorkCase／Closure | 多筆 Update 保存過程，唯一 Closure 正式結案 | 無以 Task 打勾取代案件或結案 | 通過 |
| 史略 | 由正式事實投影完成過程與結果 | 無獨立打卡、積分或完成率 | 通過 |
| 設定與錯誤狀態 | 說明本機資料、安全界線與可重試狀態 | 不責備使用者、不以資料錯誤製造恐慌 | 通過 |

## 3. 防回歸 Gate

`product_constitution_gate_test.dart` 鎖定正式 App／Screen 與其主要共用元件：

- 禁止完成率、達成率、連續打卡、KPI、績效、評分及焦慮化狀態文案。
- 禁止把 Milestone 顯示為達標評分。
- 禁止共用 Task 卡重新提供直接完成 action。

Gate 只保護正式 Runtime UI，不把歷史封存文件或未接入正式入口的舊預覽元件誤當成現行產品畫面。

## 4. PR #230 正式 Flutter Web 部署 Gate

PR #230 必須部署當時 `main` 的最新版正式 Flutter Web。GitHub Pages 若仍顯示舊樣板、靜態假畫面或假資料，PR #230 不得標記完成或合併。

PR #230 至少必須提供以下驗收證據：

1. Pages 部署來源是最新版 `flutter build web --release` 產物，而非 repo 內舊 HTML 樣板。
2. 公開網址可進入正式五入口 App Shell，且空資料狀態不以 fixture／假資料冒充正式資料。
3. 以手機尺寸實際開啟公開網址，逐頁確認生活總覽、生活項目、新增、史略與設定。
4. 公開頁面不得出現舊樣板標題、舊導航或已知展示資料；部署 commit 必須可追溯至 PR #230 驗收的最新版 commit。
5. GitHub Pages workflow、Flutter Web 資產及瀏覽器 console 均通過；任何 stale deployment 或舊快取仍可見時不得完成。

本 PR 只記錄這項後續阻擋條件，不執行部署、不修改 Pages workflow，也不提前施工 PR #230。

## 5. 資料與生命週期影響

- 不修改 Schema、Migration、Domain、Repository、Runtime 資料行為或正式資料。
- Item 仍是 Root；Task 只作提醒；WorkCase 保存案件過程；WorkCaseClosure 是唯一正式結案；History 只作投影。
- 不新增 writer、資料表、平行提醒／完成／案件／史略流程。
- 回復只需還原本 PR 的顯示文案、Task 卡 API、Gate、文件與版本，不需要資料 rollback。

## 6. 驗收

- Product Constitution Gate。
- 既有 Task／WorkCase／Closure／History 流程測試。
- Drift code generation 無非預期差異。
- Flutter Analyze。
- 全部 Flutter tests。
- Web release build。
- 正式手機尺寸預覽。
- GitHub Actions 全綠後才可 squash merge。
