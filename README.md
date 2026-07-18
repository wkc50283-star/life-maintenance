# 生活管理 App

目前版本：**v0.5.1 Foundation Runtime Audit**

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

`v0.5.1` 是基礎架構稽核版，代表產品身分、資料安全、Drift Schema v2、v1 → v2 migration、Repository 基線與正式 Runtime 資料流控制已建立；不代表使用者功能、舊資料匯入、Repository 切換或正式 UI 已完成。

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
- 保養項目、排程、任務與案件的資料角色已重新分離
- Flutter Analyze、Test、Web Build、Drift code generation 與 Web 資產自動 CI

後續依序進行：

1. 完成舊資料 converter／dry run 與切換凍結點報告
2. 建立可回滾 importer 與逐欄、筆數、關聯比對
3. 依單一 writer 規則切換正式 Repository
4. 保養／修理卡、工程卡與多筆進度 UI
5. 階段性重點
6. 統一史略視圖
7. 正式 UI／UX 與真機驗收

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
- SharedPreferences（正式 Runtime 現行唯一資料來源與 writer）
- Drift + SQLite（Schema v2 與 Repository 已完成，尚未匯入或接管 Runtime）
- GitHub Actions
- GitHub Pages（Web build）

Drift + SQLite Schema v2 與 v1 → v2 migration 已建立；現有 App 尚未正式切換到 Drift，也沒有匯入任何 SharedPreferences 資料。

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
