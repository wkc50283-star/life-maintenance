# Web Long-term Validation（PR #232）

狀態：正式控制文件
版本：v0.5.31
日期：2026-07-21

## 1. 目的與邊界

本文件建立正式 Flutter Web 的長期使用驗收基線，涵蓋重新整理、關閉分頁後重開、瀏覽器重啟、背景恢復、Drift 持久化與 GitHub Pages 正式部署。此 PR 不修改 UI、Schema、Migration、Domain 或正式資料生命週期；iPhone／Android 實體裝置仍依 Device Validation Baseline 延後驗收。

Item 仍是 Root；Task 只作提醒；WorkCase 保存案件；WorkCaseClosure 是正式結案；History 只由正式資料投影。

## 2. 已確認的阻擋風險與修正

PR #232 稽核發現 Pages build 仍產生 Flutter 已棄用的 Service Worker。長期部署時，舊 Service Worker 可能保留不同世代的 `main.dart.js`、`drift_worker.dart.js` 與 `sqlite3.wasm`，使正式 Runtime 載入不一致的執行資產。

Pages workflow 因此固定使用 `--pwa-strategy=none`，並由 Gate 確認 artifact 只留下 Flutter 用於退出舊註冊的空白 `flutter_service_worker.js`，且 bootstrap 不再設定 `serviceWorkerVersion`。這只移除不安全的應用程式資產快取，不變更 Drift database name、Schema 或任何正式資料。

既有瀏覽器若曾註冊舊 Service Worker，第一次載入新版部署仍可能受舊 worker 控制；必須完全關閉該站分頁後重開並再重新整理，讓瀏覽器取得已移除 worker 的部署。不得以清除網站資料或更換 database name 作為驗收方式，因為那會避開既有資料持久化驗證。

## 3. 正式 Web Checklist

每輪必須記錄日期、瀏覽器與版本、候選 commit、公開 Pages deployment run、測試資料唯一名稱，以及驗證前後正式資料筆數。不得記錄敏感資料。

### A. Drift 持久化

- [ ] 在正式五入口建立唯一命名的 Category 與 Item。
- [ ] 重新整理同一頁面，資料仍由 Drift 讀回且沒有重複。
- [ ] 關閉所有該站分頁，再從正式網址重開，資料仍存在。
- [ ] 完全結束瀏覽器程序後重啟，資料仍存在。
- [ ] 不清除 site data、不使用新的 database name，也不回到 SharedPreferences／Legacy writer。

### B. 背景恢復

- [ ] 建立或修改正式資料後切換至其他分頁至少 30 秒。
- [ ] 回到生活管理分頁後可繼續操作，資料沒有消失或重複。
- [ ] 作業系統休眠／喚醒後重新聚焦頁面，Drift 讀取保持正常。
- [ ] 若頁面已被瀏覽器回收，重新載入後仍從同一 Drift database 讀回。

### C. Pages 正式部署

- [ ] deployment 來源為最新版 `main` commit，artifact 為正式 `flutter build web build/web`。
- [ ] 正式網址顯示生活總覽、生活項目、新增、史略、設定五入口，沒有 prototype 或假資料。
- [ ] `main.dart.js`、`drift_worker.dart.js` 與 `sqlite3.wasm` 均成功回應。
- [ ] artifact 的 `flutter_service_worker.js` 是空白退出標記，bootstrap 不註冊有版本的 Flutter Service Worker。
- [ ] Safari、Chrome 與隔離／無痕載入驗證成功；隔離／無痕只驗證全新來源啟動，不可代替既有資料持久化。

## 4. 自動防回歸 Gate

CI 持續鎖定：

- Drift Web database name 維持 `life_maintenance`，避免無聲建立另一套資料。
- SQLite WASM 與 Drift worker 使用相對 URL，能配合 Pages base href。
- Pages build 使用 `--pwa-strategy=none`，artifact Gate 拒絕 Flutter Service Worker。
- Pages artifact 仍包含正式 Flutter 入口、Drift worker、WASM 與正確 `/life-maintenance/` base href。
- 版本與本控制文件保持一致。

自動 Gate 無法真正終止瀏覽器程序、模擬 OS 休眠或證明瀏覽器已保留使用者資料；這些項目必須依 Checklist 以同一候選 commit 人工驗證，不得用 unit test、build success 或無痕新來源冒充。

## 5. PR #232 驗證紀錄

- 相同 release build 在全新本機 Web origin 建立 Category 與 Item 後，重新整理、關閉分頁重開及切至其他分頁 30 秒後返回，均可讀回同一筆 Drift 資料。
- PR 施工前公開 Pages 可顯示正式五入口，但既有受控瀏覽器 origin 的 Drift 查詢失敗；全新 origin 正常，形成舊快取世代風險的阻擋證據。
- 瀏覽器程序重啟、作業系統休眠、Safari 與 Chrome 的最終公開網址驗收，必須在合併後 Pages deployment 對同一 `main` commit 完成才可簽核。
- iPhone／Android 實體裝置不在本 PR 範圍，維持未簽核。

## 6. 回復

本 PR 沒有資料格式或正式使用者資料變更，不需要 Migration 或資料 rollback。回復只能還原 workflow、Gate、控制文件與版本；不得刪除 Drift 資料、改名資料庫、清除網站資料或恢復 Legacy writer。
