# 生活管理 App 目前正式狀態

狀態：正式控制文件
最後核對日期：2026-07-31
核對分支：`main`
核對 Commit：`2c3fa17b0e5563b03ed57524deb00f6d49ed083a`

## 1. 正式版本與資料基線

- App version：`0.5.52+53`
- AppDatabase schema version：`4`
- 正式資料庫：Drift + SQLite
- 正式 main CI：`quality`、`android-build`、`ios-simulator-build` 全部成功
- GitHub Pages：同一 main commit 的 build 與 deploy 成功

## 2. main 已存在的正式能力

- 生活管理 App 的產品憲法、產品規格、驗收、開發與資料治理文件。
- UI v3 Foundation、正式 App Shell、五個正式入口與共用 Theme。
- Item、分類、MaintenancePlan、GeneralReminder、Milestone、Schedule、Task、WorkCase、MaintenanceRecord、Attachment 與 History Projection 的正式 Drift 資料能力。
- Schema v4 的系統「未分類」、Item 管理週期、Item created lifecycle event 與原子 `ItemCreationRuntime` 資料基礎。
- Web／Android／iOS 自動品質與 build gates。

## 3. 尚未進入 main

- Issue #268「一分鐘建立生活項目並自動產生第一筆史略」目前只存在於 Draft PR #270。
- PR #270 的版本 `0.5.53+54`、新增 bottom sheet、精簡 Item 建立 UI 與 created history 畫面承接均不得視為 main 已完成功能。

目前進行中的正式任務以 [`CURRENT_TASK.md`](CURRENT_TASK.md) 為準。

## 4. 證據來源

- `pubspec.yaml`
- `lib/database/app_database.dart`
- GitHub main commit `2c3fa17b0e5563b03ed57524deb00f6d49ed083a`
- GitHub Actions 的 main commit checks
- 已合併 PR #269：`Add item creation history foundation`
- Draft PR #270 的 GitHub 狀態

## 5. 更新規則

- main SHA、App version、Schema version或 main 正式能力改變時，同一 PR 必須同步本文件。
- 只記錄已合併至 main 且可由程式、Git 或 GitHub 驗證的事實。
- Draft、Open 或尚未合併的內容只能列在「尚未進入 main」，不得列為已完成功能。
- 每次更新必須記錄最後核對日期與核對 commit。
