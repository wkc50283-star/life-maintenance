# 生活管理 App 正式資料庫選型決策

狀態：已批准；實作已完成
決策日期：2026-07-18  
最後證據檢查：2026-07-18  
下次例行檢查：2026-10-18，或在加入 dependency／升級主要版本前重新檢查

> 現行 Runtime 基線（v0.5.20）：本 ADR 的分階段施工限制保留為決策歷史。Drift Schema v2、Repository、受控匯入與 Legacy Runtime 退休已完成；正式 Runtime 現況以 `25-legacy-runtime-retirement.md` 與 `33-architecture-audit.md` 為準。

## 1. 決策

生活管理 App 的正式本機資料庫選擇：

- 資料層：Drift
- 底層引擎：SQLite
- iOS／Android／macOS／Windows／Linux：`NativeDatabase`
- Flutter Web：`WasmDatabase`

本決策只確立技術方向。此文件合併時不得同時加入 dependency、建立正式 schema、搬移 SharedPreferences 資料或切換現有讀寫來源。

## 2. 為什麼需要正式資料庫

目前 SharedPreferences 只用四組 JSON 字串保存：

- `items`
- `schedules`
- `tasks`
- `maintenance_records`

它可暫時承接 MVP，但新的正式資料角色包含：

- `Item`
- `Schedule`
- `Task`
- `MaintenanceRecord`
- `WorkCase`
- `WorkCaseUpdate`
- 未來的照片／附件索引
- 統一史略查詢

這些資料需要一對多關聯、狀態查詢、日期排序、原子交易、版本化 schema、可驗證 migration 與跨 iOS／Web 的一致資料規則。繼續把更多集合塞進獨立 JSON 字串，會提高部分寫入、關聯斷裂、遷移不可驗證與大量資料讀寫成本。

## 3. 必要條件

候選方案必須同時滿足：

1. Flutter iOS 與 Flutter Web 都是正式支援目標。
2. 能表達 `Item → WorkCase → WorkCaseUpdate` 等關聯。
3. 支援交易，案件、進度與後續提醒的複合操作不得部分完成。
4. 有明確 schema version 與 migration 機制。
5. migration 可以在 CI 中以舊 schema 驗證。
6. 可在測試中建立隔離或記憶體資料庫。
7. 能保存穩定照片識別碼，但照片檔本身仍由檔案層管理。
8. 不把 Web 當成未測試或實驗性附加功能。
9. 長期維護規則必須可被 repo 文件與測試約束，而不是只靠人工記憶。

## 4. 候選比較

| 候選 | iOS | Web | 關聯與查詢 | 交易 | migration 與測試 | 判定 |
|---|---:|---:|---|---|---|---|
| Drift + SQLite | 是 | 是，WASM | 關聯式、型別安全查詢 | 支援，含常用實作的巢狀交易 | schemaVersion、逐版本 migration、schema 快照與 migration tests | 採用 |
| Hive CE | 是 | 是 | key-value／NoSQL；複雜關聯需由 App 自行維護 | 不作為本專案多表原子流程的主要保證 | 型別 adapter 可用，但正式關聯 schema 與 migration 驗證需自行建立 | 不採用 |
| Isar 原始穩定版 | 是 | 有 Web 支援資料 | NoSQL links 可表達關聯 | ACID | schema 變更部分自動，資料 migration 版本與流程由 App 自行管理 | 不採用 |
| ObjectBox | 是 | 官方 Dart／Flutter 平台文件未列 Web | 物件關聯與查詢 | ACID | 有 schema 模型 | 不符合 Web 必要條件 |
| sqflite | 是 | Web 實作標示 experimental | 原生 SQL | 支援 | 版本管理需自行建立較多規則 | 不採用 |

### 工程判斷

Hive CE 與 Isar 並非不能保存案件資料，但本專案的核心不是單一物件快取，而是多層關聯、完整史略、可回復 migration 與跨平台一致性。選擇 Drift 是基於資料角色與驗證成本，不是基於熱門度或效能宣傳。

## 5. Drift 符合需求的證據

官方文件確認：

- Drift 是 Dart／Flutter 的關聯式 persistence library，提供型別安全查詢、stream queries、transactions 與 migration utilities。
- `NativeDatabase` 支援 Android、iOS、Windows、Linux、macOS。
- `WasmDatabase` 支援 Web；`WasmDatabase.open` 是目前穩定 Web API。
- Web 會依瀏覽器能力使用 OPFS 或 IndexedDB 等儲存策略。
- schema 變更以 `schemaVersion` 與逐版本 migration 管理。
- `make-migrations` 可保存 schema 版本、產生 migration steps 與 migration tests。
- migration schema 驗證可用於 native，也可在 Web 執行。
- `NativeDatabase` 與 `WasmDatabase` 支援交易，常用實作也支援巢狀交易。

## 6. 已知成本與風險

### Web 部署資產

Flutter Web 必須正確部署：

- `sqlite3.wasm`
- Drift worker JavaScript

不得只確認 Web build 成功。部署驗收還必須確認：

- 資產 URL 可取得
- 瀏覽器能載入 WASM 與 worker
- 新增資料後重新整理仍存在
- 多分頁或 worker fallback 不造成資料異常
- GitHub Pages 實際回應與快取行為正常

### Web 與 native 差異

- Web 不支援 SQLite WAL 模式。
- Web 儲存依瀏覽器能力選擇 OPFS 或 IndexedDB fallback。
- 不得假設 iOS 真機結果等同 Web；兩邊都要有整合驗收。

### Code generation

Drift 依賴 code generation。生成檔、schema snapshots 與 migration tests 必須納入明確 repo 規則，禁止只在開發者本機存在。

### 套件升級

加入 dependency 時需鎖定相容版本，主要版本升級前重新檢查：

- Flutter／Dart SDK 要求
- `drift`、`drift_dev`、`drift_flutter`、`sqlite3` 相容性
- Web WASM 與 worker 建置方式
- migration 工具行為

## 7. 不採用方案說明

### Hive CE

優點：純 Dart、跨平台、Web WASM、簡單直覺。  
不採用原因：官方定位是 key-value NoSQL。對本專案而言，案件、進度、生活項目、提醒與史略的關聯、跨集合交易、schema evolution 與 migration 驗證需建立更多自訂基礎，長期風險高於 Drift。

### Isar

優點：型別查詢、ACID、links、Web。  
不採用原因：官方資料 migration 指引需要 App 另行保存版本並自行執行資料 migration；原始穩定版發布時間較久，近期活躍替代方案多為社群 fork。對需要長期 migration 證據鏈的本專案，維護與版本治理不如 Drift 直接。

### ObjectBox

優點：物件資料庫、關聯、交易與效能。  
不採用原因：官方 Dart／Flutter 支援平台列出 iOS、Android 與桌面，未列 Flutter Web，直接不符合必要條件。

### sqflite

優點：成熟 SQLite API、交易與版本管理。  
不採用原因：官方文件仍將 Web 支援標示為 experimental，且 Web 實作自行列出 slow、not fully tested 與 bugs。Web 是本專案正式平台，不接受以實驗性實作作為基礎。

## 8. 實作順序

```text
資料庫 ADR 合併
→ 鎖定 dependency 版本
→ 建立空的 Drift schema v1
→ 只建立新 WorkCase／WorkCaseUpdate tables
→ repository interface 與 transaction tests
→ native／web 開啟與部署測試
→ SharedPreferences 與 Drift 雙讀比對工具
→ 原始備份與筆數／關聯驗證
→ 才開始匯入舊資料
→ 真機與 Web 驗收
→ 確認可回復
→ 才逐步切換正式寫入
```

第一個 schema PR 不得同時遷移既有四組 JSON，也不得讓現有 UI 改用未驗證的新資料庫。

## 9. 第一版 schema 邊界

第一個實作批次只建立：

- database metadata／schema version 基礎
- `work_cases`
- `work_case_updates`
- 外鍵與必要索引
- 建立／查詢／交易／刪除限制測試
- native 與 Web 開啟介面

第一版不得建立：

- 舊資料自動匯入
- SharedPreferences 刪除
- Item／Schedule／Task／MaintenanceRecord 全面搬移
- 照片檔案搬移
- 雲端同步
- UI 案件建立流程

## 10. 回復原則

- Drift 尚未接管現有資料前，回復方式是移除新資料庫功能，舊 SharedPreferences 繼續運作。
- 開始雙讀後，任何比對失敗都必須停止切換，不得修改來源 JSON。
- 開始匯入前，`backup_v1_*` 必須存在且可讀。
- 匯入完成不等於可以刪除舊資料；必須經筆數、關聯、查詢、真機與 Web 驗收。
- 正式切換後仍需保留一個可驗證版本週期的回復能力。

## 11. 證據來源

最後檢查日期：2026-07-18

### Drift 官方文件

- [Supported platforms](https://drift.simonbinder.eu/platforms/)
- [Web / WasmDatabase](https://drift.simonbinder.eu/platforms/web/)
- [Migrations](https://drift.simonbinder.eu/migrations/)
- [Testing migrations](https://drift.simonbinder.eu/migrations/tests/)
- [Transactions](https://drift.simonbinder.eu/dart_api/transactions/)

### 其他候選官方文件

- [Hive CE package](https://pub.dev/packages/hive_ce)
- [Isar links](https://isar.dev/links.html)
- [Isar data migration](https://isar.dev/recipes/data_migration.html)
- [Isar stable versions](https://pub.dev/packages/isar/versions)
- [ObjectBox supported platforms](https://docs.objectbox.io/faq#on-which-platforms-does-objectbox-run)
- [sqflite API](https://pub.dev/documentation/sqflite/latest/)
- [sqflite web implementation](https://pub.dev/packages/sqflite_common_ffi_web)

## 12. 重新評估條件

出現以下任一情況，必須重新比較候選方案：

- Drift 停止支援 Flutter Web 或 iOS。
- Web WASM／worker 無法在正式部署環境可靠運作。
- migration tests 無法涵蓋實際 schema 演進。
- 套件主要版本造成無法接受的相容或維護成本。
- 產品改成雲端為唯一資料來源，且本機資料庫角色根本改變。
- 新證據顯示其他方案能以更低風險完整滿足所有必要條件。
