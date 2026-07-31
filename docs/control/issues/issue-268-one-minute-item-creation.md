# Issue #268｜一分鐘建立生活項目並自動產生第一筆史略

狀態：正式 Issue 控制文件  
適用分支：`issue-268-one-minute-item-creation`  
目標版本：`0.5.53+54`

## 1. 唯一目的

提供「＋新增 → 拍照／語音／輸入 bottom sheet → 輸入 → 一分鐘建立生活項目 → 第一筆建立史略 → 成功承接」的最小正式流程。

## 2. 已批准產品決策

- Bottom sheet 關閉後留在既有「＋新增中心」，不返回原頁、不自動切換清單。
- 拍照與語音本期只誠實顯示尚未啟用，不寫入資料。
- 輸入流程只收集名稱、分類與管理週期。
- 分類可未指定，由正式「未分類」承接。
- 管理週期可為空集合，也可複選年、半年、季、月、週、日。

## 3. 正式流程

1. 使用者開啟新增中心。
2. 系統顯示拍照／語音／輸入 bottom sheet。
3. 選擇「輸入」後開啟精簡 Item 建立表單。
4. 驗證 trim 後名稱非空，建立選定分類與週期集合。
5. 畫面只呼叫 `ItemCreationRuntime.create()`。
6. Runtime 以同一 AppDatabase transaction 建立 Item、週期資料、唯一 created lifecycle event 與 event period snapshots。
7. 成功畫面顯示名稱、分類、管理週期、建立時間與「建立生活項目」史略。
8. 「完成」切換至既有生活項目清單；「繼續補充資料」進入同一 Item 的既有編輯表單。

## 4. 資料契約

- Model：既有 `Item`、`ItemManagementPeriod`、`ItemLifecycleEvent` 與 `ItemCreatedHistoryEntry`。
- Runtime：既有 `ItemCreationRuntime.create()`。
- 分類：未指定時使用正式 system unclassified category。
- 週期：零個或多個正式週期，不包含 hour 或 minute。
- History：ItemDetail 與全域 History 只讀投影 created lifecycle event。
- 舊 Item：沒有 created event 時保持沒有建立史略，不補造。
- 原子性：任一寫入失敗時全部 rollback。

## 5. UI 契約

- 保留新增中心其他既有入口。
- 不變更 Bottom Navigation 名稱與順序。
- 不改 Theme，重用既有表單、按鈕、分類表單與 Item 編輯畫面。
- 儲存期間停用重複送出，同一次操作只建立一個 Item 與一筆 created event。
- 失敗時留在表單並使用既有錯誤提示，不假裝成功。

## 6. 修改白名單

- `lib/app/app_shell.dart`
- `lib/screens/add_screen.dart`
- `lib/screens/formal_planning_screens.dart`
- `lib/screens/item_detail_screen.dart`
- `lib/screens/history_screen.dart`
- `test/item_creation_flow_test.dart`
- `test/app/app_shell_test.dart`
- `test/history_screen_test.dart`
- `test/item_detail_sheet_test.dart`
- `test/ui_v2_item_form_ux_test.dart`
- `test/platform/cross_platform_audit_test.dart`
- `test/ui_v3_foundation_shell_test.dart`
- `test/accessibility/accessibility_beta_gate_test.dart`
- 必要平台版本 Gate tests
- `pubspec.yaml`
- `docs/control/06-change-log.md`
- `docs/control/issues/issue-268-one-minute-item-creation.md`

## 7. 禁止修改

- Model、Database、Schema v4、Migration 與 Drift tables。
- Repository 契約、`ItemCreationRuntime` 公開契約或核心 transaction。
- Task、Schedule、Reminder、MaintenancePlan、Milestone、WorkCase 與 Backup／Restore。
- Bottom Navigation 名稱或順序、Theme、首頁 AI、真實拍照或語音辨識。
- 平行 Item writer、假資料或自動補造舊 Item created event。

## 8. 測試要求與結果

- Bottom sheet 三入口、關閉承接與其他新增入口回歸。
- 名稱必填與 trim、正式未分類、新分類精準選取、週期複選與略過。
- Runtime create 只呼叫一次，快速連點不重複，失敗時全部 rollback。
- 不建立 Task、Schedule、Reminder、MaintenancePlan、Milestone 或 WorkCase。
- 成功畫面、ItemDetail 與全域 History 投影 `ItemCreatedHistoryEntry`。
- 舊 Item 不補造 created event；既有 Item 編輯、History 與其他生命週期回歸保持通過。
- Security test：5 PASS。
- `flutter analyze`：PASS。
- `flutter test`：396 PASS。
- Web／Android／iOS build gate 結果待本分支最終驗證後填入 Draft PR。

## 9. Version

`0.5.52+53` → `0.5.53+54`

## 10. 停止條件

- 必須修改 Model、Schema、Migration、Repository 或 Runtime 契約。
- 無法使用 `ItemCreationRuntime.create()` 完成原子建立。
- 必須建立 Task、Schedule、Reminder、MaintenancePlan、Milestone 或 WorkCase。
- 無法防止重複 Item 或 created event。
- 全部測試或任一必要 build gate 失敗。
- 必須修改白名單外正式程式。

## 11. 未解問題

無。
