# Architecture Audit

狀態：正式控制文件

版本：v0.5.20

日期：2026-07-19

適用 PR：#221

## 1. 稽核結論

正式 Runtime 的 Domain、Repository、Runtime 與 AppCompositionRoot 邊界一致；Drift 是唯一正式資料來源，Legacy Runtime 已退休。未發現需要修改 production code 的阻擋性架構問題。

本次唯一阻擋項是早期核心控制文件仍以「SharedPreferences 尚在運作／Drift 尚未實作」描述現況，會與 v0.5.12 以後的正式控制文件衝突。PR #221 只加入現行基線註記，保留原始決策與遷移歷史，不重寫歷史內容。

## 2. 正式角色證據

| 角色 | Domain／Repository／Runtime 證據 | 結論 |
|---|---|---|
| Item | `ItemReadRepository` 由 `DriftItemReadRepository` 注入；所有正式資料仍經 Item 關聯 | Root 未改變 |
| MaintenancePlan／Step | Schema v2 Repository 與正式 planning UI 經 Composition Root 使用 | 長期保養內容與實例分離 |
| GeneralReminder | 與 MaintenancePlan 分離，Schedule 依正式來源契約關聯 | 無平行提醒流程 |
| Milestone | 獨立 Repository 與 Schedule／Task source | 不等同一般保養 |
| Schedule | `ScheduleRepository` 由 Drift adapter 注入；AnchorPolicy 留在正式模型 | 只表示時間規則 |
| Task | `TaskRepository` 與 `TaskReminderRuntime` 不提供直接結案或 History 寫入 | 只表示提醒實例 |
| WorkCase／Update | `WorkCaseRuntime` 維護案件、追加過程與 transaction | 唯一案件流程 |
| WorkCaseClosure | 唯一 Closure Repository；結案與 terminal status 原子寫入 | 唯一正式結案來源 |
| MaintenanceRecord | 只承接不需案件過程的簡單完成事實 | 不取代 Closure |
| Attachment | 經 `AttachmentRuntime` 管理 stable identifier、owner 與狀態 | UI 不直接保存平台路徑 |
| History | `HistoryProjectionRepository` 只有 `projectForItem` 查詢 | 無 writer、table 或平行真相 |

## 3. Composition Root 與資料來源

- `lib/main.dart` 只建立 `AppCompositionRoot.production()`。
- AppCompositionRoot 只建立一個 AppDatabase，並由同一 Drift Schema v2 repository 組合正式 read、write、transaction 與 projection runtime。
- 正式入口、`lib/app`、screen 與 widget 沒有 SharedPreferences、LocalStorageService 或 LocalRepository 依賴，也沒有自行建立 Database／Repository。
- 正常啟動不執行 Legacy admission、import 或 fallback；`initialize()` 直接回報 Drift mode。
- SharedPreferences business keys 與 `backup_v1_*` 不刪除、不覆蓋，也不作為正常 Runtime read model。

## 4. Legacy 保留邊界

Legacy 程式只保留在明確受控的 recovery 範圍：

- 四個 LocalRepository：唯讀相容解析。
- LocalStorageService：讀取舊字串，以及只寫入尚不存在的 `backup_v1_*`。
- backup、import、relation audit 與 migration readiness：受控匯入／稽核／災難回復工具。

防回歸 Gate 以完整 allowlist 鎖定上述 production 檔案；任何新的 LocalStorageService 或 SharedPreferences 引用都必須先修改正式控制文件並通過架構審查。測試可使用 SharedPreferences mock 驗證 recovery 與來源不變性，但不得成為 production dependency。

## 5. 資料與回復影響

- 不修改 Schema、Migration、mapping、transaction 或任何資料列。
- 不讀寫、搬移、刪除或覆蓋 SharedPreferences business keys、`backup_v1_*` 或 Drift 資料。
- 本 PR 的程式回復方式是還原文件與 Gate 變更；資料不需要 rollback。
- 若未來 recovery 工具需要執行匯入，仍須依既有 dry-run、transaction、FK、完整性與人工准入規則，不能由正常啟動自動執行。

## 6. 明確未修改

- 不新增功能、UI、資料表、API 或領域角色。
- 不修改 Schema、Migration、匯入 mapping 或正式 Runtime 行為。
- 不建立 Task、WorkCase、Closure、History、Attachment 或分類的平行流程。
- 不刪除 Legacy recovery 程式或舊使用者資料。
- 不開始下一個 PR。

## 7. 驗收

- Architecture／Legacy retirement Gate。
- Drift code generation 無差異。
- Flutter Analyze。
- 全部 Flutter tests。
- Web release build。
- GitHub Actions 全綠後才可 squash merge。
