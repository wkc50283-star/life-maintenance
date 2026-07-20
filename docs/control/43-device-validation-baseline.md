# Device Validation Baseline（PR #231）

狀態：正式控制文件
版本：v0.5.30
日期：2026-07-20

## 1. 目的與邊界

本文件建立正式裝置驗收的可重跑基線，涵蓋安裝、原地升級、冷啟動、背景切換、強制關閉重啟、資料持久化與版本升級相容。它不修改 Schema、Migration、Domain、UI 設計或正式資料生命週期，也不得用 simulator、平台 build 或 CI 冒充實體裝置結果。

Item 仍是 Root；Task 只作提醒；WorkCase 保存案件；WorkCaseClosure 是正式結案；History 只由正式資料投影。

## 2. 驗收環境紀錄

每一輪真機驗收必須先記錄：

- 日期、驗收人、Git commit、`pubspec.yaml` 版本。
- 裝置型號、OS 版本、可用儲存空間與安裝來源。
- Android `applicationId` 或 iOS bundle identifier。
- 升級前版本、升級後版本，以及是否保留原 App sandbox。
- 測試資料識別用名稱與升級前數量；不得記錄敏感內容。

PR #231 施工環境盤點：iOS 實體裝置被開發工具列為 Offline，且沒有 Android ADB／實體裝置。可用環境只有 iPhone Simulator、macOS 與 Chrome。因此本 PR 建立並自動驗證基線，但不宣稱 iOS 或 Android 實體裝置已簽核。

同一候選程式已在 iPhone 16 Pro Simulator 完成安裝、首次啟動、系統強制終止與再次冷啟動，重啟後正式五入口 Runtime 正常顯示。Android release APK 與 iOS Simulator App 皆可建置；這些證據仍不等於實體裝置或商店簽章驗收。現行 Android release configuration 使用 debug signing，iOS distribution signing 也未在本 PR 驗證，正式發佈前必須另行完成簽章 admission。

## 3. 正式真機 Checklist

### A. 全新安裝與啟動

- [ ] 從預定發佈管道安裝，不手動植入資料庫。
- [ ] 首次啟動進入正式五入口，沒有 prototype、fixture 或舊 Runtime。
- [ ] 建立一個唯一命名的 Category、Item、MaintenancePlan 與 Schedule。
- [ ] 完全離開 App 後重新啟動，資料仍可由 Drift 讀回。

### B. 背景與程序重啟

- [ ] 建立或修改資料後切到背景至少 30 秒，再回到前景。
- [ ] 前景恢復後畫面可操作，剛才資料沒有重複或消失。
- [ ] 從系統 App Switcher 強制關閉，再由桌面圖示冷啟動。
- [ ] Task、WorkCase、Update、Closure 與 History 的角色及關聯保持正確。

### C. 原地版本升級

- [ ] 先安裝上一個已驗證建置，建立 Item → Plan → Task → WorkCase → Update，並保留一筆已結案 History。
- [ ] 記錄各正式資料數量，不匯出或修改 SQLite 檔案。
- [ ] 使用相同 application／bundle identifier 與合法簽章原地安裝新版本；禁止先卸載、清除資料或更換 App sandbox。
- [ ] 新版本第一次啟動成功，沒有回到 SharedPreferences／Legacy writer。
- [ ] 升級前 Item、Plan、Task、WorkCase、Update、Closure、MaintenanceRecord、Attachment metadata 與 History 投影均可讀。
- [ ] 新版本可新增資料，重啟後仍存在；既有資料不被刪除、覆蓋或重複匯入。

### D. 失敗與回復

- [ ] 安裝或啟動失敗時保留原 App 與資料，不用卸載重裝作為修復步驟。
- [ ] 記錄失敗階段、裝置 log、版本與可重現步驟；不得把使用者資料上傳到公開 issue。
- [ ] 若資料完整性 Gate 失敗，停止正式寫入並保留 `backup_v1_*` 唯讀回復來源。
- [ ] 回復到已驗證建置時，不執行 downgrade migration，不宣稱跨版本 downgrade 受支援。

## 4. 自動防回歸基線

CI 與本機測試必須持續驗證：

- Android `applicationId` 與 iOS bundle identifier 不會在 patch 升級中意外改變。
- Drift `schemaVersion` 維持本 PR 既有版本；PR #231 不新增 migration。
- 檔案 SQLite 在同一 Runtime 期間仍可讀，完整關閉 Composition Root 再重開後資料仍存在。
- `PRAGMA foreign_key_check` 為空，`PRAGMA integrity_check` 為 `ok`。
- Device Checklist 不得把 simulator、build success 或 Widget test 寫成實體裝置簽核。

自動 Gate 不模擬 OS 背景切換，只能阻止已知持久化回歸，不能取代觸控、OS lifecycle、簽章、安裝器與真實儲存空間下的人工真機驗收。

## 5. Admission 判定

單一平台只有在該平台 Checklist 全部完成、證據對應同一候選 commit 且沒有資料遺失時，才可標示「真機通過」。未連線、未簽章、只完成 simulator 或只完成 artifact build，一律標示「未簽核」，不可推論為通過。

本 PR 的合併條件是基線、Gate、codegen、Analyze、全部 tests、Web／Android／iOS build 與 CI 全綠；合併本身不會把尚未執行的實體裝置 Checklist 改成已通過。

## 6. 回復

本 PR 沒有 Schema、Migration 或使用者資料變更，不需要資料 rollback。回復只需還原本文件、防回歸測試、版本與發行文件；不得刪除正式 Drift 資料或恢復 Legacy writer。
