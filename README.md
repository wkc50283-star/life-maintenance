# 生活管理 App

目前版本：**v0.5.53+54 一分鐘建立生活項目**

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

目前 main 為 `0.5.53+54`、AppDatabase Schema v4。正式現況以 [CURRENT_STATE](docs/control/CURRENT_STATE.md) 為準；目前施工任務以 [CURRENT_TASK](docs/control/CURRENT_TASK.md) 為準。

Issue #268／PR #270 已合併，main 已具備「一分鐘建立生活項目」流程與第一筆建立史略。拍照、語音與 AI 自動填欄位尚未啟用。

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
- Drift + SQLite（Schema v4、Repository、安全 importer 與正式資料 Runtime）
- GitHub Actions
- GitHub Pages（Web build）

實體裝置驗收依 [Device Validation Baseline](docs/control/43-device-validation-baseline.md) 逐項簽核；未連線或只完成 simulator 的平台維持「未簽核」。

Web 長期使用驗收依 [Web Long-term Validation](docs/control/44-web-long-term-validation.md) 執行；瀏覽器程序重啟、背景／休眠與既有資料持久化不得以 unit test 或無痕新來源代替。

既有 Pages origin 接續依 [Pages Origin Continuity](docs/control/45-pages-origin-continuity.md) 驗收；禁止清除 site data 或以 fresh origin 規避。

Pages Drift 根因與驗收證據依 [Pages Drift Root Cause](docs/control/46-pages-drift-root-cause.md) 管理；部署後須辨識 GitHub Pages 的 600 秒 HTTP asset cache，不得把舊 bundle 當作新 commit 的驗收結果。

正式 SQLite 備份／還原安全邊界依 [Backup and Restore Core Safety](docs/control/47-backup-restore-core-safety.md) 驗收；呼叫前必須關閉 Drift，且不得把資料庫 metadata 備份冒充 Attachment 檔案內容備份。

Attachment metadata 完整性依 [Attachment Metadata Integrity Validation](docs/control/48-attachment-metadata-integrity.md) 驗收；不得把 metadata 狀態驗收冒充實體檔案 storage 能力。

Drift + SQLite Schema v4 與受控 importer 已建立；Runtime 只在完整驗證通過後切換，MaintenanceRecord 只承接不需要案件過程的簡單完成事實。

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

- [目前正式狀態](docs/control/CURRENT_STATE.md)
- [目前正式任務](docs/control/CURRENT_TASK.md)

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
