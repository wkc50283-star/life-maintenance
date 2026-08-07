# 生活管理 App 目前正式狀態

狀態：正式控制文件
最後核對日期：2026-08-08
核對分支：`main`
核對 Commit：`0fd7a53df785880ead03bea01d4d118389c4a806`

## 1. 正式版本與資料基線

- App version：`0.5.53+54`
- AppDatabase schema version：`4`
- 正式資料庫：Drift + SQLite
- 最新 main：已合併 PR #278 `Add compact today focus to home`
- GitHub Pages／CI／build gates 仍依正式 workflow 與各 PR Gate 判定。

## 2. main 已存在的正式能力

- 生活管理 App 的產品憲法、產品規格、驗收、開發與資料治理文件。
- UI v3 Foundation、正式 App Shell、底部導航與共用 Theme。
- Item、分類、MaintenancePlan、GeneralReminder、Milestone、Schedule、Task、WorkCase、MaintenanceRecord、Attachment 與 History Projection 的正式 Drift 資料能力。
- Schema v4 的系統「未分類」、Item 管理週期、Item created lifecycle event 與原子 `ItemCreationRuntime` 資料基礎。
- Issue #268「一分鐘建立生活項目並自動產生第一筆建立履歷」已進入 main：
  - 輸入流程可用名稱、分類與年／半年／季／月／週／日管理週期複選建立 Item。
  - 新 Item 只透過 `ItemCreationRuntime.create()` 建立，並產生唯一 created lifecycle event。
  - 成功承接畫面、ItemDetail 與全域 History 已能顯示建立事件。
- `AddScreen` 目前仍以系統功能名稱排列正式建立能力；formal editor 路徑可到達分類、保養項目與步驟、一般提醒、階段性重點、提醒排程、突發事項／工程、補登完成紀錄。
- PR #275～#278 已進入 main 的 UI 收斂能力，包括新增入口層級調整、履歷用語調整、極端 Dynamic Type 版面修正與首頁今日焦點。
- Web／Android／iOS 自動品質與 build gates。

## 3. 尚未完成或不得誤認完成

- 拍照辨識、語音辨識、AI 自動填欄位與 AI 正式建立尚未啟用。
- 手動建立「四個生活目的入口」是 2026-08-08 前後完成的新產品定案，尚未進入 main。
- 四入口與現有 Model／Repository／Runtime／History 的正式工程映射尚待完成。
- 四入口相關文案、版面、步驟與互動尚未經真實 App／非設計參與者情境操作驗收，不得標記 UI／UX 完成。
- PR #279 `Toggle home quick capture actions` 仍為 OPEN／Draft；不屬於 main 正式能力，也尚未核對是否符合新的四入口規劃。
- 既有舊 Item 沒有 created event 時不補造建立履歷。
- 設定中的「使用說明與常見問題」已批准為產品方向，但尚未施工。

## 4. 證據來源

- `pubspec.yaml`
- `lib/database/app_database.dart`
- `lib/screens/add_screen.dart`
- `docs/control/04-development-rules.md`
- GitHub main commit `0fd7a53df785880ead03bea01d4d118389c4a806`
- 已合併 PR #269、#270、#275、#276、#277、#278
- OPEN／Draft PR #279

## 5. 更新規則

- main SHA、App version、Schema version 或 main 正式能力改變時，同一 PR 必須同步本文件。
- 只記錄已合併至 main 且可由程式、Git 或 GitHub 驗證的事實。
- Draft、Open 或尚未合併的內容只能列在「尚未完成或不得誤認完成」，不得列為已完成功能。
- 每次更新必須記錄最後核對日期與核對 commit。
