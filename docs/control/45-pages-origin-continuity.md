# Pages Origin Continuity（PR #233）

狀態：正式控制文件
版本：v0.5.32
日期：2026-07-21

## 1. 目的與邊界

本文件只處理既有 GitHub Pages origin 的舊 Flutter Service Worker 退休與 Drift 資料接續。不得清除網站資料、改變 `life_maintenance` database name、建立新資料來源，或以新 origin／無痕環境規避既有資料驗收。

本修正不改 UI、Schema、Migration、Domain、Repository 或正式生命週期。Item 仍是 Root；Task 是提醒；WorkCase 是案件；WorkCaseClosure 是正式結案；History 只作投影。

## 2. 正式退休順序

正式 Web 入口在載入 Flutter 前必須：

1. 取得目前 origin 的 Service Worker registrations。
2. 只選取 scope 與目前 App base URI 完全相同的 registration；不得影響同一 GitHub Pages origin 的其他路徑。
3. 執行 `unregister()`，不操作 IndexedDB、Local Storage 或任何正式資料。
4. 若目前頁面仍由成功解除的舊 worker 控制，重新載入一次。
5. 沒有舊控制器後才載入 `flutter_bootstrap.js`，讓 Drift 以原 `life_maintenance` database 接續既有資料。

解除失敗時不得清除資料或更換 database name；保留錯誤訊息後照常載入，讓正式 UI 呈現既有讀取錯誤，而不是破壞性自動回復。

## 3. 防回歸 Gate

- `web/index.html` 只能先載入 `service_worker_retirement.js`，不得直接搶先載入 Flutter bootstrap。
- retirement script 必須以 `document.baseURI` 限定 App scope。
- retirement script 必須在成功解除且頁面仍受控制時重新載入，再啟動 Flutter。
- 禁止 `indexedDB.deleteDatabase`、清除 Local／Session Storage、database rename 或 Legacy writer。
- Pages artifact 必須包含 retirement script，維持 `--pwa-strategy=none` 與空白 Service Worker 退出標記。

## 4. 驗收

- [ ] 在既有正式 Pages origin 確認舊 Drift 資料可讀。
- [ ] 重新整理後仍讀取同一資料，沒有重複或遺失。
- [ ] 關閉所有該站分頁後重開，資料仍存在。
- [ ] 完全結束瀏覽器程序後重啟，資料仍存在。
- [ ] 正式五入口可操作，沒有舊樣板、假資料或平行 Runtime。
- [ ] Pages artifact、CI 與部署 commit 對應同一版 `main`。

瀏覽器程序重啟必須由可真正結束該程序的環境驗證；只關閉分頁、unit test、fresh origin 或無痕視窗均不得冒充。

## 5. 回復

本 PR 沒有 Schema、Migration 或資料寫入變更。回復只能還原 retirement bootstrap、Gate、版本與文件；不得刪除 Drift 資料、清除網站資料、改名資料庫或恢復 Legacy writer。
