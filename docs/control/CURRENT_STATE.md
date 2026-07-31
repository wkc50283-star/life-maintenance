# 生活管理 App 目前正式狀態

狀態：正式控制文件
最後核對日期：2026-08-01
核對分支：`main`
核對 Commit：`7a2f4c35e5211d4fea9f83a185867c1bc6a4d149`

## 1. 正式版本與資料基線

- App version：`0.5.53+54`
- AppDatabase schema version：`4`
- 正式資料庫：Drift + SQLite
- 正式 main CI：PR #270 合併前 `quality`、`android-build`、`ios-simulator-build` 全部成功
- GitHub Pages：沿用正式 main workflow；部署驗收仍依 Pages 控制文件判定

## 2. main 已存在的正式能力

- 生活管理 App 的產品憲法、產品規格、驗收、開發與資料治理文件。
- UI v3 Foundation、正式 App Shell、五個正式入口與共用 Theme。
- Item、分類、MaintenancePlan、GeneralReminder、Milestone、Schedule、Task、WorkCase、MaintenanceRecord、Attachment 與 History Projection 的正式 Drift 資料能力。
- Schema v4 的系統「未分類」、Item 管理週期、Item created lifecycle event 與原子 `ItemCreationRuntime` 資料基礎。
- Issue #268「一分鐘建立生活項目並自動產生第一筆史略」已進入 main：
  - 「新增」入口開啟拍照／語音／輸入 bottom sheet。
  - 拍照與語音誠實顯示尚未啟用，不寫入正式資料。
  - 輸入流程以名稱、分類與年／半年／季／月／週／日管理週期複選建立 Item。
  - 新 Item 只透過 `ItemCreationRuntime.create()` 建立，並自然產生唯一 created lifecycle event。
  - 成功承接畫面、ItemDetail 與全域 History 顯示「建立生活項目」史略。
- Web／Android／iOS 自動品質與 build gates。

## 3. 尚未完成或不得誤認完成

- 拍照辨識、語音辨識、AI 自動填欄位與自動建立排程尚未啟用。
- Issue #268 合併不代表 iPhone 或 Android 實體裝置人工驗收已完成。
- 既有舊 Item 沒有 created event 時不補造建立史略。
- 目前沒有進行中的正式施工任務；下一個任務以 [`CURRENT_TASK.md`](CURRENT_TASK.md) 為準。

## 4. 證據來源

- `pubspec.yaml`
- `lib/database/app_database.dart`
- GitHub main commit `7a2f4c35e5211d4fea9f83a185867c1bc6a4d149`
- 已合併 PR #269：`Add item creation history foundation`
- 已合併 PR #270：`Issue #268: Add one-minute item creation flow`
- 已合併 PR #271：`Add formal current state and task controls`
- GitHub Actions run `30647489700`：`quality`、`android-build`、`ios-simulator-build` 成功

## 5. 更新規則

- main SHA、App version、Schema version或 main 正式能力改變時，同一 PR 必須同步本文件。
- 只記錄已合併至 main 且可由程式、Git 或 GitHub 驗證的事實。
- Draft、Open 或尚未合併的內容只能列在「尚未完成或不得誤認完成」，不得列為已完成功能。
- 每次更新必須記錄最後核對日期與核對 commit。