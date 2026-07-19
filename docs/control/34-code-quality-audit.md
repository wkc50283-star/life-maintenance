# Code Quality Audit

狀態：正式控制文件

版本：v0.5.21

日期：2026-07-19

適用 PR：#222

## 1. 稽核結論

本次掃描 production Dart、tests、dependencies 與平台／工具檔案。Analyzer 與 `dart fix --dry-run` 均未回報 lint、unused import 或可自動修正項目；production Dart 沒有 TODO、FIXME、HACK 或 DEBUG 標記，也未找到可證明且能安全移除的重複程式。

確認並修正兩項必要品質問題：

1. `drift_safe_read_only_runtime.dart` 是 v0.5.11 admission failure 過渡 adapter；v0.5.12 已正式退休該 Runtime，且全 repo 零引用，因此移除。
2. `reminder_list_sheet_test.dart` 直接 import `shared_preferences_platform_interface`，原本依賴 transitive package 並 suppress `depend_on_referenced_packages`；改列正式 dev dependency 並移除 suppression。

## 2. 保留項目

- `sqlite3` 維持直接鎖定 `3.4.0`，因 Drift Web 資產工具與正式控制文件要求 `sqlite3.wasm` 版本必須匹配，不視為 unused dependency。
- `cupertino_icons` 雖沒有 repo 內的直接 symbol 引用，Web compiler 仍會解析 `packages/cupertino_icons/CupertinoIcons` font family；移除會產生缺少字型警告，因此維持直接 dependency。
- Android、Linux 與 Windows runner 的 TODO／DEBUG 字樣來自 Flutter 平台樣板或編譯條件，不是 App dead code 或臨時診斷；本 PR 不改產生式平台設定。
- `tool/prepare_drift_web_assets.py` 的 `print` 是 CI 資產準備結果，不是 production debug output。
- prototype entrypoint 有專屬測試且由 Pages review build 使用，不是 dead code。
- Legacy LocalRepository、backup、import、audit 與 recovery 工具依 v0.5.20 allowlist 保留，不是 dead Runtime。

## 3. 防回歸

- 新增 Code Quality Gate，阻擋 production Dart 引入 TODO、FIXME、HACK 或 DEBUG。
- Gate 鎖定已退休 safe-read-only transition adapter 不得重新加入。
- `flutter analyze` 持續負責 unused import、dead local declaration 與 lint 檢查。
- dependency 直接引用與保留理由需在後續 audit 重新驗證，不得以 transitive dependency 配合 lint suppression 隱藏。

## 4. 資料與回復影響

- 不修改 Schema、Migration、Domain、Runtime 行為或任何資料。
- 不讀寫、搬移、刪除 SharedPreferences、`backup_v1_*` 或 Drift row。
- 回復只需還原本 PR 的 dead adapter、dependency、Gate、文件與版本變更；不需要資料 rollback。

## 5. 明確未修改

- 不新增功能、UI、資料表、API 或產品流程。
- 不改 Schema、Migration、Domain model、CompositionRoot 或正式 Repository contract。
- 不刪 Legacy recovery 程式或舊資料。
- 不進行無證據的重構或 duplicate code 合併。
- 不開始下一個 PR。

## 6. 驗收

- Code Quality／Architecture／Legacy retirement Gates。
- Drift code generation 無差異。
- Flutter Analyze。
- 全部 Flutter tests。
- Web release build。
- GitHub Actions 全綠後才可 squash merge。
