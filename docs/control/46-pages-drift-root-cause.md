# Pages Drift Root Cause（PR #234）

日期：2026-07-21  
版本：v0.5.33  
狀態：正式控制文件

## 範圍

本文件只處理正式 GitHub Pages 既有 origin 無法開啟 Drift 的根因。禁止清除網站資料、改變 `life_maintenance` database name、建立平行來源，或以 fresh origin／無痕環境代替既有 origin 驗收。

## 根因與證據

1. Flutter bootstrap 正常載入，Drift 因瀏覽器能力選用 `WasmStorageImplementation.sharedIndexedDb`。
2. 首次正式 Item 查詢失敗，release Web 診斷精確記錄 `home_overview.items.load`。
3. SQLite 錯誤為 `item_categories_system_code_status_idx already exists`，造成語句是非冪等 `CREATE INDEX item_categories_system_code_status_idx ...`。
4. 將資料庫預先開啟移至 Composition Root 後，錯誤只移到 `composition_root.initialize`，證明不是 Repository 並行讀取競態。
5. 既有 Schema 採認嘗試未解除錯誤；真正阻擋點是 Drift creation path 對已存在 index 再次執行 `CREATE INDEX`。
6. GitHub Pages 對 `main.dart.js` 回應 `cache-control: max-age=600`。部署後 600 秒內，既有分頁可能仍執行上一版 bundle；以舊版才有的診斷 stage 可確認此情況。

## 正式修正

- `onCreate` 仍建立 Schema v2 的相同 tables 與 indexes，不改 Schema 定義或版本。
- tables 沿用 Drift `createTable` 的安全建立流程。
- generated index 定義原樣取用，只將建立動作改為 `CREATE INDEX IF NOT EXISTS` 或 `CREATE UNIQUE INDEX IF NOT EXISTS`。
- 不刪除、重建或改名任何既有 table／index／database，不搬移或覆蓋資料。
- Runtime 錯誤以結構化 stage、error type 與 SQLite error 輸出；不輸出使用者資料內容。

## 防回歸與驗收

- 測試建立完整 Schema v2 與既有 Item，將 version metadata 模擬為 creation path 後重開；既有 indexes 不衝突、Item 內容保留、版本回到 2。
- v1 → v2 migration、foreign key、transaction rollback 與全套既有測試必須維持通過。
- 同一 Pages origin、同一瀏覽器資料 context、未清除 site data 重整後，生活總覽與生活項目可讀，console 不得再出現 Runtime error。
- Pages deploy 後必須確認載入的是該 commit bundle；GitHub Pages 600 秒 HTTP cache 尚未到期時不得宣告失敗或成功。
- Service Worker 仍依 PR #233 精確 scope 退休；本 PR 不建立或恢復 Service Worker。

## 回復限制

程式 rollback 可還原診斷與 idempotent index 建立程式，但不得刪除 IndexedDB、網站資料或既有 indexes，不得改 database name 或恢復 Legacy writer。若 rollback 會讓既有 origin 再次無法開啟，應停止回復並保留目前安全版本。
