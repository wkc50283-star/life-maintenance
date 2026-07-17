# 生活管理 App

`life-maintenance` 是一個 Flutter 生活管理 App，目標是管理生活項目、固定週期、到期提醒、階段性重點、突發事項與工程，並保存每一次處理從開始到結束的完整史略。

> 本 repo 不是 PMS。PMS 曾是產品演化中的偏移階段，不再作為目前的產品與開發依據。

## 核心架構

```text
生活項目
├── 保養項目
├── 固定週期
├── 到期提醒
├── 階段性重點
└── 突發事項／工程
         ↓
    處理事件卡
         ↓
    多筆處理進度
         ↓
    完修或結案
         ↓
    封存進入史略
```

重要區分：

- 保養項目：長期存在的管理規則。
- 保養／修理卡：一件實際發生、正在處理的事情。
- 史略：結案後保存的完整過程，不只是最後摘要。

## 目前狀態

專案正在進行正式產品復原與架構補強。

已完成的資料安全基礎：

- 舊 JSON 欄位與未知 enum 相容
- 逐筆解析，保留可讀資料
- 資料異常時全域禁止寫入
- 啟動前資料完整性檢查
- 不可變 `backup_v1_*` 原始 JSON 備份
- Flutter Analyze、Test、Web Build 自動 CI

後續依序進行：

1. 生活管理文案與入口復原
2. 假功能與工程欄位清理
3. 首頁與生活項目頁視覺樣板
4. 處理案件與多筆進度模型（模型基線已完成）
5. 正式資料庫 schema v1（案件表已完成，尚未接管資料）
6. 階段性重點

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
- SharedPreferences（現行過渡儲存）
- Drift + SQLite（正式資料庫已選型，尚未接管資料）
- GitHub Actions
- GitHub Pages（Web build）

Drift + SQLite schema v1 已建立，目前只包含案件與進度資料表；現有 App 尚未開啟資料庫，也沒有遷移任何 SharedPreferences 資料。

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

## 開發規則摘要

- 不得混淆 PMS 與生活管理 App。
- 不得直接修改 `main`。
- 每次只改必要的最小區塊。
- 不得建立只有外觀沒有功能的假入口。
- 資料格式變更前必須備份、測試並提供回復方案。
- UI 必須經手機真機畫面驗收。
- CI 未通過不得合併。

## 安全邊界

高風險或未知風險事項不提供 DIY 維修教學。涉及電力、瓦斯、煞車、冷媒、結構、高壓、高溫或醫療判斷時，只做提醒、紀錄與尋求專業協助的引導。
