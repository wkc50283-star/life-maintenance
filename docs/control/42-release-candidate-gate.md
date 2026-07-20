# Release Candidate Gate（PR #230）

狀態：正式控制文件
版本：v0.5.29
日期：2026-07-20

## 1. RC 判定

本候選版整合 PR #221～#229 的既有證據，不重新定義產品、Domain 或資料生命週期。Item 仍是 Root；Task 只作提醒；WorkCase 保存案件；WorkCaseClosure 是唯一正式結案；History 只由正式事實投影。

PR #230 發現並修正唯一發佈阻擋：Pages workflow 雖持續成功，實際入口卻指定 review-only `lib/prototype_main.dart`，公開網址因此不是正式 Runtime。workflow 現改由 Flutter 預設 `lib/main.dart` 建置，並只上傳該次 `build/web`。

## 2. #221～#229 整合矩陣

| Gate | 正式證據 | RC 條件 |
|---|---|---|
| Architecture #221 | Domain／Repository／Runtime／CompositionRoot、Drift 唯一資料源 | 不得出現 Legacy writer 或平行流程 |
| Code Quality #222 | 品質標記、dead／duplicate code、lint／dependency Gate | Analyze 零問題，正式碼無臨時標記 |
| UI #223 | SafeArea、overflow、Loading／Empty／Error、字級與深色環境 | 五入口跨尺寸無阻擋 exception |
| Product Constitution #224 | 中性文案、Task 禁止直接完成、Pages 後續 Gate | 不得 To-do／KPI／催促化；Pages 必須正式化 |
| Data Integrity #225 | transaction／rollback、FK／UNIQUE、import／backup／restore | `foreign_key_check` 空、`integrity_check` 為 ok |
| Performance #226 | 大量 Item／Task／History／Attachment 基準 | 索引、載入、捲動與記憶體 Gate 持續通過 |
| Security #227 | SQLite binding、Attachment identifier、WASM hash、權限 | Pages build/deploy 最小權限不放寬 |
| Cross Platform #228 | iPhone／iPad／Android／Web 與主要瀏覽器 | Web／Android／iOS build 全綠 |
| Real User #229 | 跨日冷啟動、備份／還原、Closure → History | Task／案件／結案／史略角色不可混用 |

## 3. Pages Admission Gate

1. workflow 只可執行正式 `flutter build web --release --base-href /life-maintenance/`，不得指定 `prototype_main.dart`。
2. 上傳來源必須是同一 job 產生的 `build/web`，並包含 `index.html`、Flutter entry bundle、`drift_worker.dart.js` 與 pinned `sqlite3.wasm`。
3. artifact 出現「生活管理樣板審查」或「首頁樣板」即失敗。
4. deploy job 才可取得 `pages: write`／`id-token: write`；build job 只保留 read 權限。
5. 正式網址必須顯示生活總覽、生活項目、新增、史略、設定五個入口；空資料不得顯示 fixture。
6. 部署 SHA 必須等於合併 PR #230 後的 `main` SHA。舊快取、舊樣板或部署失敗均不得宣告 RC 完成。

## 4. 瀏覽器驗收

- Chrome：一般視窗實際載入公開網址、逐一開啟五入口、檢查 console。
- Safari：實際載入同一公開網址並確認五入口與正式空狀態。
- 隔離／無痕：使用全新 origin storage context 驗證首次啟動，不借用既有 IndexedDB 或快取；不得以清除使用者資料作正式流程。
- 瀏覽器缺少可操作環境時必須如實標示，不得以共同引擎推論冒充實際驗證。

## 5. 合併與部署順序

Pages workflow 只接受 `main` push，因此 PR CI 全綠後先 squash merge；合併本身不等於完成。必須等待該 merge SHA 的 Pages build/deploy 全綠並完成公開網址驗收，才可對外回報 PR #230 完成。若部署或公開驗收失敗，只能在 PR #230 的完成處理中修復，不得開始下一個 PR。

## 6. 回復與殘餘限制

本 PR 不修改資料，不需要 Migration／rollback。workflow 回復不可重新部署 prototype；若正式 Pages 無法安全部署，應停止公開 RC 而非切回假資料。真實裝置匯入、Attachment 檔案內容跨裝置回復與正式 UI／UX 改版仍是後續限制，不在本 PR 冒充完成。
