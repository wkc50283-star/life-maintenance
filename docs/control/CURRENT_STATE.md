# 生活管理 App 目前正式狀態

狀態：正式控制文件
最後核對日期：2026-08-09
核對分支：`main`
核對 Commit：`8ebffb99ea877ad76931c5d77aa56dbf7f5e3765`

## 1. 正式版本與資料基線

- App version：`0.5.53+54`
- AppDatabase schema version：`10`
- 正式資料庫：Drift + SQLite
- Backup format version：`10`
- 最新已合併功能 PR：#288 `Add FutureMatter amendment foundation`
- PR #288 GitHub Actions：`quality`、`android-build`、`ios-simulator-build` 全部成功

App version 與 Schema version 必須分開管理。Schema 升版不代表 App version 自動升版；目前 `pubspec.yaml` 仍正式為 `0.5.53+54`。

## 2. main 已存在的正式能力

### 2.1 既有生活管理資料能力

- Item、分類、MaintenancePlan、GeneralReminder、Milestone、Schedule、Task、WorkCase、MaintenanceRecord、Attachment 與 History Projection 的正式 Drift 資料能力。
- 系統「未分類」、Item 固定管理週期、Item created lifecycle event 與原子 `ItemCreationRuntime`。
- 一分鐘生活項目建立的既有正式輸入路徑與建立履歷基礎。
- Web／Android／iOS 自動品質與 build gates。

### 2.2 Schema v5～v6｜管理週期資料能力

- Schema v5：自訂管理週期資料基礎；使用結構化 `intervalValue + intervalUnit`，保留既有固定週期 enum。
- 固定與自訂週期可以並存；等價週期有正式防重複規則。
- Schema v6：既有生活項目的管理週期修改資料基礎與不可變 before／after 履歷事件。
- 管理週期本身不自動建立 Reminder、Schedule 或 Task。

### 2.3 Schema v7～v10｜FutureMatter 正式資料能力

- Schema v7／PR #285：FutureMatter 主資料與不可變 created event；支援 later、specifiedDate、recurring、condition 四種時間方式。
- Schema v8／PR #286：FutureMatter change history runtime；正式修改保留 before／after 快照並進入 History Projection。
- Schema v9／PR #287：FutureMatter completion runtime；完成事件不可變，完成前完整快照保留，完成後主資料 lifecycle 轉為 completed。
- Schema v10／PR #288：FutureMatter supplement／correction amendment foundation；支援補充與更正、原子 transaction、有效事實 fold、來源 reference、History Projection、Backup／Restore 與不可變 amendment history。
- FutureMatter 目前資料層不得被誤認為四入口 UI 已完成。

## 3. 已批准但尚未完整進入 main UI 的產品方向

手動建立第一層正式方向為四個生活目的入口：

1. 建立要長期管理的內容
2. 安排未來要注意或處理的事情
3. 記錄正在處理的事情
4. 補記已完成的事情

共通原則：四入口只負責新增；最低成立後可先正式記錄，後續是否補充由使用者決定；正式建立與正式補充必須可追溯；不得未經確認自動建立下一步；未經真實 App 操作的文案、版面、步驟與互動一律視為待實機驗證。

正式產品規劃見 [`issues/issue-manual-create-four-purpose-plan.md`](issues/issue-manual-create-four-purpose-plan.md)。

## 4. 尚未完成或不得誤認完成

- 四個生活目的入口的完整 UI／導航尚未全部完成並實機驗收。
- 入口 2 雖已有 FutureMatter v7～v10 正式資料基礎，不代表使用者介面已完成。
- 入口 3 對 WorkCase／事件／工程的最終工程映射仍需依批准規格確認。
- 入口 4 的補登完成、既有排程關聯與後續週期計算規則仍需逐項批准後施工。
- 拍照辨識、語音辨識、AI 自動填欄位與 AI 正式寫入尚未因本次資料層 PR 自動啟用。
- 所有尚未真機操作驗證的 UI 文案、版面、流程不得標記為完成。
- PR #280 `Plan four-purpose manual creation and formalize engineering authority` 仍為舊基準的 OPEN PR，未進 main；本次控制文件同步完成後應由新版文件取代，不得直接把 #280 舊 branch 合入目前 main。

## 5. 證據來源

- `pubspec.yaml`：App version `0.5.53+54`
- `lib/database/app_database.dart`：Schema version `10`
- GitHub main commit `8ebffb99ea877ad76931c5d77aa56dbf7f5e3765`
- PR #281：custom management period foundation
- PR #283：management period change foundation
- PR #285：FutureMatter creation foundation
- PR #286：FutureMatter change history runtime
- PR #287：FutureMatter completion runtime
- PR #288：FutureMatter amendment foundation
- PR #288 Actions run #399：quality、Android、iOS 全部成功

## 6. 更新規則

- main SHA、App version、Schema version、Backup format 或 main 正式能力改變時，必須同步本文件。
- 版本判定優先讀取實際 main：App version 以 `pubspec.yaml` 為準；Schema version 以 `AppDatabase.schemaVersion` 為準。
- 只記錄已合併至 main 且可由程式、Git 或 GitHub 驗證的工程事實；已批准但尚未施工的產品方向必須明確標示。
- Draft、Open 或尚未合併的 PR 不得描述成 main 已完成功能。
- CI 全綠不等於 UI／UX 實機驗收完成。
