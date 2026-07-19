# 生活管理 App

目前版本：**v0.5.11 Drift Safe Runtime Gate**

`life-maintenance` 是一個 Flutter 生活管理 App，目標是管理生活項目、固定週期、到期提醒、階段性重點、突發事項與工程，並保存每一次處理從開始到結束的完整史略。

> 本 repo 不是 PMS。PMS 曾是產品演化中的偏移階段，不再作為目前的產品與開發依據。

## 核心架構

```text
生活項目 Item
    ↓
保養項目 MaintenancePlan
    ↓
排程 Schedule
    ↓
本次提醒 Task
    ↓
需要持續處理時建立 WorkCase
    ↓
多筆 WorkCaseUpdate
    ↓
完修或結案後進入史略
```

一般提醒可由 Item 直接建立 Schedule／Task；突發修理、工程或辦理事項也可由 Item 直接建立 WorkCase，不必強迫經過全部階段。

重要區分：

- 保養項目：附屬於生活項目、長期存在的管理規則。
- 系統模板：協助建立保養項目，不是使用者真實資料。
- 排程：只負責時間規則，不代表保養項目本身。
- 保養／修理卡：一件實際發生、正在處理的事情。
- 史略：結案後保存的完整過程，不只是最後摘要。

## 目前狀態

`v0.5.11` 解除 Legacy Runtime writer fallback：Items／History 的 MaintenanceRecord 讀取統一由正式 Drift Repository 提供；啟動驗證失敗時進入 Drift 唯讀安全狀態，不再恢復舊 Runtime writer。SharedPreferences 與不可變 `backup_v1_*` 只保留為唯讀回復來源，不雙寫、不刪除或覆蓋；Legacy 程式本版仍保留，不執行刪除。

已完成的資料與治理基礎：

- 生活管理 App 產品定位與控制文件
- PMS 文件退出正式規格
- 舊 JSON 欄位與未知 enum 相容
- 逐筆解析，保留可讀資料
- 資料異常時全域禁止寫入
- 啟動前資料完整性檢查
- 不可變 `backup_v1_*` 原始 JSON 備份
- WorkCase／WorkCaseUpdate 模型
- Drift + SQLite 正式選型
- Drift Schema v2、v1 → v2 migration 與 Repository 邊界
- 舊資料只讀盤點、關聯稽核與遷移准入閘門
- 正式 Runtime SharedPreferences 讀寫稽核與禁止雙寫規則
- SharedPreferences → Drift v2 dry-run、原子匯入、重跑保護與 rollback 測試
- AppDatabase、Drift Schema v2 Repository、現行 LocalRepository 與必要 Service 由單一 AppCompositionRoot 建立及注入
- 啟動時受控匯入、失敗 rollback、重啟零寫入驗證與 ItemCategory／Item Drift 讀取切換
- MaintenancePlan、GeneralReminder、Milestone、Schedule 的 Drift Runtime Repository、source contract、anchor policy 與 transaction 切換
- 保養項目、排程、任務與案件的資料角色已重新分離
- 正式唯讀 History Projection 與 Attachment managed identifier／owner／生命週期 Runtime
- MaintenanceRecord 正式 Drift Runtime、簡單 Task 完成 transaction 與 WorkCaseClosure 邊界
- Legacy Runtime 全量引用稽核、唯一 writer／冷啟動／rollback 防回歸 Gate
- Items／History 的 MaintenanceRecord Drift read cutover 與啟動失敗 Drift 唯讀安全狀態
- Flutter Analyze、Test、Web Build、Drift code generation 與 Web 資產自動 CI

後續依序進行：

1. 完成真實裝置來源唯讀與匯入預覽驗收
2. 保養／修理卡、工程卡與多筆進度 UI
3. 階段性重點
4. 擴充正式史略畫面的案件、附件與排序呈現
5. 正式 UI／UX 與真機驗收

## 支援週期

- 每日
- 每週
- 每月
- 每季
- 每半年
- 每年
- 自訂

原則：日歸日、週歸週、月歸月、季歸季、半年歸半年、年歸年。

## 技術

- Flutter
- Dart
- Material 3
- SharedPreferences（受控匯入成功後永久唯讀保留為回復來源）
- Drift + SQLite（Schema v2、Repository、安全 importer 與正式資料 Runtime）
- GitHub Actions
- GitHub Pages（Web build）

Drift + SQLite Schema v2、v1 → v2 migration 與受控 importer 已建立；Runtime 只在完整驗證通過後切換，MaintenanceRecord 只承接不需要案件過程的簡單完成事實。

## 本機執行

```bash
flutter pub get
flutter run
```

## 驗證

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart compile js -O4 web/drift_worker.dart -o web/drift_worker.dart.js
python3 tool/prepare_drift_web_assets.py
flutter analyze
flutter test
flutter build web --release
```

所有 PR 都會由 GitHub Actions 執行相同品質檢查。

## 正式控制文件

開發前必須先閱讀：

1. [產品憲法](docs/control/01-product-constitution.md)
2. [產品功能規格書](docs/control/02-product-specification.md)
3. [架構與資料設計書](docs/control/03-architecture-and-data.md)
4. [開發與 Codex 規範](docs/control/04-development-rules.md)
5. [驗收清單](docs/control/05-acceptance-checklist.md)
6. [變更與決策紀錄](docs/control/06-change-log.md)
7. [正式資料庫選型決策](docs/control/07-database-decision.md)
8. [版本管理規則](docs/control/08-versioning.md)
9. [核心資料角色修正案](docs/control/09-core-data-roles.md)
10. [修正版 Drift schema v2 設計](docs/control/10-corrected-schema-v2-design.md)
11. [地基缺口修正計畫](docs/control/11-foundation-gap-corrections.md)
12. [生活項目類別策略](docs/control/12-item-category-strategy.md)
13. [正式產品名詞表](docs/control/13-product-terminology.md)
14. [首頁與生活項目詳情視覺架構](docs/control/14-home-and-item-detail-visual-architecture.md)
15. [正式 Runtime 資料流稽核與單一寫入控制](docs/control/15-runtime-data-transition-audit.md)
16. [SharedPreferences → Drift Schema v2 安全匯入控制](docs/control/16-sharedpreferences-drift-v2-import.md)
17. [受控 Runtime 匯入與 Item 讀取切換](docs/control/17-controlled-runtime-import-and-item-read-cutover.md)
18. [Planning Repository Drift 切換](docs/control/18-planning-repository-drift-cutover.md)

`docs/control/` 內標示為「正式控制文件」的文件共同生效，不再以固定「六份文件」限制控制範圍。

## 開發規則摘要

- 不得混淆 PMS 與生活管理 App。
- 不得直接修改 `main`。
- 每次只改必要的最小區塊。
- 不得建立只有外觀沒有功能的假入口。
- 資料格式變更前必須備份、測試並提供回復方案。
- UI 必須經手機真機畫面驗收。
- CI 未通過不得合併。
- 正式版本唯一來源是 `pubspec.yaml`。
- Schedule 不得代替 MaintenancePlan。
- 「限－工程」只是假名；正式介面依情境使用突發事項、工程／修繕或辦理事項，底層使用 WorkCase。

## 安全邊界

高風險或未知風險事項不提供 DIY 維修教學。涉及電力、瓦斯、煞車、冷媒、結構、高壓、高溫或醫療判斷時，只做提醒、紀錄與尋求專業協助的引導。
