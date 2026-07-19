# 正式 App Shell

狀態：正式控制文件
版本：v0.5.13
日期：2026-07-19
適用 PR：#214

## 1. 正式結論

正式 App 使用單一 App Shell 承接五個生活管理入口：

1. 生活總覽
2. 生活項目
3. 新增
4. 史略
5. 設定

這五個入口只負責導覽至既有 Screen，不建立第二套畫面、資料來源、Repository 或生命週期。

## 2. 結構責任

- `LifeMaintenanceApp`：建立或接收唯一 AppCompositionRoot，管理其生命週期，建立 MaterialApp。
- `AppTheme`：提供全 App 共用 ThemeData。
- `AppShell`：等待既有 Composition Root initialize 完成，顯示目前入口及唯一主要 NavigationBar。
- `AppCompositionScope`：將同一個正式 Runtime dependency graph 提供給 Shell 下的既有畫面。
- Screen：維持既有功能與資料存取方式，本 PR 不調整內容。

## 3. 導覽規則

- 第一入口是生活總覽，不得以「今日任務」代表整個產品。
- 生活項目仍是 Item 的正式全域入口。
- 新增只承接既有新增畫面，不在 Shell 內建立寫入流程。
- 史略仍是正式資料的查詢投影入口，不新增 History writer。
- 設定維持既有可用內容，不加入假設定。
- 不得新增平行 NavigationBar、隱藏 route 或 Shell 專用資料存取。

## 4. Theme 規則

既有 Material 3 Theme 原值集中到 `AppTheme.light`。本 PR 只統一 Theme 來源，不進行視覺重畫、色彩改版、元件重設計或 Screen 層樣式擴散。

後續正式 UI／UX 施工若需修改 Theme，必須另立 PR 並依正式視覺驗收流程處理。

## 5. Composition Root 規則

- App 只能建立或注入一個 AppCompositionRoot。
- Shell 不自行建立 Database、Repository、Service 或 SharedPreferences。
- Screen 與 Widget 只能從既有 AppCompositionScope 取得正式 dependencies。
- AppCompositionRoot 的 Drift Runtime 建立、initialize 與 dispose 行為不屬於本 PR 修改範圍。
- Drift 仍是唯一正式資料來源與 writer。

## 6. 防回歸 Gate

- NavigationBar 必須只有五個正式入口，名稱與順序固定。
- 每個入口只顯示原有對應 Screen。
- AppShell 與其子畫面取得的 AppCompositionRoot 必須與 LifeMaintenanceApp 注入者相同。
- MaterialApp 必須使用共用 AppTheme，不得在 main 或 Shell 另建 ThemeData。
- 正式 Shell 不得 import Database、Repository、Service、SharedPreferences 或 Legacy Runtime。
- codegen、Analyze、全部 tests、Web release build 與 GitHub Actions 全綠後才可合併。

## 7. 明確未修改

- 不修改 Schema、Migration、Runtime、Repository 或資料。
- 不修改既有 Screen／Widget 功能或正式 UI 內容。
- 不新增功能、資料表、API、平行流程或下一個 PR。
