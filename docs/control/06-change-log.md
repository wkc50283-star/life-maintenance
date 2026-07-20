# 生活管理 App 變更與決策紀錄

狀態：正式控制文件

## 使用規則

每一筆正式變更至少記錄：

- 日期
- 變更編號
- 類型
- 問題與原因
- 修改內容
- 明確未修改內容
- 資料影響
- 驗收結果
- 批准狀態
- PR 或 commit

---

## LM-001：恢復生活管理 App 主線

日期：2026-07-17  
類型：產品治理

### 問題

`life-maintenance` 原本是生活維護／生活管理 App，後續被 PMS 的責任承接理念、抽象文案與規格文件控制，造成產品身分、入口、資料角色與使用者理解走偏。

### 決策

- `life-maintenance` 正式恢復為生活管理 App。
- PMS 與生活管理 App 分開。
- PMS 文件退出正式規格地位，保留為歷史資料。
- 正式核心改為生活項目、保養項目、固定週期、階段性重點、突發事項／工程、處理事件卡與完整史略。

### 批准

已由專案負責人批准。

---

## LM-002：關閉 PMS v0.13 規格 PR

日期：2026-07-17  
類型：文件治理

### 問題

PR #155 只新增 PMS v0.13.0 規格凍結文件，與已恢復的生活管理主線衝突。

### 結果

- PR #155 正式關閉。
- 未合併到 `main`。
- 可保留的歷史內容後續移至 PMS 歷史區。

### PR

#155

---

## LM-003：建立 Flutter 自動品質關卡

日期：2026-07-17  
類型：CI／治理

### 問題

過去 PR 常在文字中宣稱 Analyze／Test 通過，但 GitHub 沒有可確認的自動品質關卡。

### 修改

加入自動執行：

- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `flutter build web --release`

### 驗收

第一輪 CI 全部通過。

### PR／commit

- PR #165
- squash commit `e3668c933587b815d842d1f4e246e072c7a01faf`

---

## LM-004：舊 JSON 欄位相容

日期：2026-07-17  
類型：資料安全

### 問題

舊資料缺少新欄位或包含未知 enum 時，模型解析可能失敗，使整組資料無法顯示。

### 修改

為 `Item`、`Schedule`、`Task` 與 `MaintenanceRecord` 增加安全預設與未知 enum fallback，並新增相容測試。

### 未修改

- 儲存鍵
- 現行輸出格式
- UI
- 排程計算

### 驗收

Analyze、Test、Web release build 全部通過。

### PR／commit

- PR #164
- squash commit `cac0211c2588c46ec7d59129676a6c1c70ab42cc`

---

## LM-005：資料異常寫入保護

日期：2026-07-17  
類型：資料安全

### 問題

任一 JSON 解析失敗時，Repository 原本直接回傳空清單；使用者後續新增資料可能把原始內容覆蓋。

### 修改

- 逐筆解析並保留可讀資料
- 偵測資料異常
- 異常時鎖住所有 Repository 寫入
- 啟動時執行完整性檢查
- 顯示全域資料保護警告
- 暫停可能寫入的「今日」與「新增」入口
- 新增原始資料不被覆蓋測試

### 驗收

Analyze、Test、Web release build 全部通過。

### PR／commit

- PR #166
- squash commit `18fbc24abe565371550e3b55958a08dd12f58719`

---

## LM-006：建立不可變原始資料備份

日期：2026-07-17  
類型：資料安全／遷移準備

### 問題

未來新增案件模型與更換正式資料庫前，需要保存現有四組原始 JSON，包含可能損壞但仍有復原價值的內容。

### 修改

- App 啟動時先建立 `backup_v1_*` 原始備份
- 原始字串不解析、不改寫
- 已存在的備份永不覆蓋
- 備份失敗時啟動寫入鎖
- 新增備份不可變性測試

### 驗收

Analyze、Test、Web release build 全部通過。

### PR／commit

- PR #167
- squash commit `4b2d01043b44beb73b7b9faa8ede91add6ec0307`

---

## LM-007：PMS 規格文件正式降級封存

日期：2026-07-17  
類型：文件治理

### 問題

`docs/pms-v0.14.0-history-timeline-specification-freeze.md` 仍位於正式文件區，且文件內寫有「正式凍結」、「不得破壞」與「禁止偏移」等指令。這會讓後續開發者或 AI 誤認它仍能控制目前的生活管理 App。

### 修改

- 將 PMS v0.14.0 履歷時間軸規格移至 `docs/archive/`。
- 在封存文件開頭加入明確的歷史與失效聲明。
- 新增 `docs/archive/README.md`，定義封存文件沒有現行產品控制力。
- 現行需求、開發與驗收只以 `docs/control/` 六份文件為準。

### 明確未修改

- 不刪除 PMS 歷史內容。
- 不修改 Flutter 產品程式。
- 不修改資料模型或儲存格式。
- 不在本批次變更使用者介面文案。

### 資料影響

無。

### 驗收

- 原正式路徑不再保留具有指導語氣的 PMS 文件。
- 封存副本完整保留原始歷史內容。
- PR 差異只包含文件。

### 批准

依 LM-001 已批准的「PMS 文件退出正式規格地位」決策執行。

### PR／commit

- PR #169
- squash commit `574f1604229dea01ffcba8eb07800cd60071ab86`

---

## LM-008：恢復直接易懂的生活管理文案

日期：2026-07-17  
類型：文案／產品治理

### 問題

App 仍保留 PMS 時期的抽象用語，例如「先放著」、「需要你記住的事」與「承接責任」；同時以「物品」代表所有內容，也無法涵蓋證件、合約、健康、家庭、財務與其他生活項目。這些文字使使用者難以直接理解入口功能，也與現行生活管理 App 規格不一致。

### 修改

- 底部導覽與頁面名稱由「物品」調整為「我的項目」或「生活項目」。
- 新增頁三個既有入口直接命名為「新增生活項目」、「新增提醒」與「補登完成紀錄」。
- 同步調整相關表單、提示訊息、空狀態、提醒清單、今日頁、履歷頁與項目詳情的顯示文字。
- 手動提醒缺少自訂名稱時，統一顯示「提醒事項」。
- 更新對應 Widget 與 Service 測試的文字期待值。
- 完成 `lib/` 主動掃描，禁止殘留「先放著」、「需要你記住的事」、「承接」與「物品」等舊用語。

### 明確未修改

- 不修改資料模型、enum、Repository 或儲存鍵。
- 不遷移、不刪除，也不改寫使用者資料。
- 不修改排程產生、任務完成或紀錄儲存流程。
- 不新增功能，不重排既有畫面。

### 資料影響

無。這一批只修改使用者可見文字與對應測試。

### 驗收

- 所有入口名稱符合現行產品規格。
- `lib/` 不再包含指定的 PMS 舊用語。
- `flutter analyze`、`flutter test` 與 Web release build 全部通過後才合併。

### 批准

依 LM-001 恢復生活管理 App 主線，以及產品功能規格書第 13 節的正式入口命名執行。

### PR／commit

- PR #170
- squash commit `4fe81132fc7a143a3c9cc1bd54d4b8568f7a8902`

---

## LM-009：移除假操作元件與工程資訊

日期：2026-07-18  
類型：UI／產品治理

### 問題

「我的項目」與「履歷」頁顯示看似可選的分類膠囊，但實際不能操作；設定頁列出尚不存在的預設提醒時間與資料匯出功能；完成紀錄詳情直接顯示內部 ID。這些內容會讓使用者誤以為 App 已具備功能，或暴露不必要的工程資訊。

### 修改

- 移除「我的項目」與「履歷」頁的非功能性分類膠囊。
- 移除尚未實作的「預設提醒時間」與「匯出資料」設定卡。
- 設定頁保留本機資料說明、安全界線與目前版本資訊。
- 移除完成紀錄詳情中的紀錄 ID、生活項目 ID 與任務 ID。
- 新增 Widget 測試，確認假操作元件與內部 ID 不會出現在一般畫面。

### 明確未修改

- 不新增真正的分類篩選、提醒時間設定或匯出功能。
- 不修改資料模型、Repository、儲存鍵或既有資料。
- 不修改排程、提醒、完成與紀錄流程。
- 不重做整體視覺設計。

### 資料影響

無。內部 ID 仍保留在資料模型與儲存內容中，只是不再直接顯示給一般使用者。

### 驗收

- 兩頁不再顯示不可操作的分類膠囊。
- 設定頁不再宣稱尚未存在的功能。
- 完成紀錄詳情不顯示工程 ID。
- `flutter analyze`、`flutter test` 與 Web release build 全部通過後才合併。

### 批准

依產品憲法「只做真的功能」與產品功能規格書的直接、誠實介面原則執行。

### PR／commit

- PR #171
- squash commit `7d2b27b7039453712d729471c3a518491d3a981b`

---

## LM-010：移除舊定位與不可信的畫面版號

日期：2026-07-18  
類型：文案／產品治理

### 問題

首頁仍顯示「軍規邏輯，民用保養」，無法涵蓋目前的生活項目、提醒、證件、合約與完整處理紀錄。畫面另外手寫 `v0.14.0`，但 `pubspec.yaml` 建置版本為 `1.0.0+1`，repo 尚未建立唯一版本來源與正式發版規則，因此使用者看到的版號並不可信。

### 修改

- 首頁副標改為「管理生活項目、提醒與處理紀錄」。
- 首頁盾牌圖示改為一般生活管理圖示。
- 移除首頁手寫 `v0.14.0` 徽章。
- 移除設定頁手寫的版本資訊卡。
- 修正 `pubspec.yaml` 的 Flutter 範本描述，改為本 App 的實際用途。
- 更新測試，防止「軍規邏輯，民用保養」與舊手寫版號再次出現在一般畫面。

### 明確未修改

- 不更改 App 名稱「生活維護管家」。
- 不擅自猜測或建立新的公開版本號。
- 不修改 `pubspec.yaml` 的建置版本。
- 不修改任何資料、提醒、排程或紀錄功能。
- 不重做首頁版面與配色。

### 資料影響

無。

### 後續版本原則

未來若要重新顯示版本資訊，必須先建立單一可信來源，讓建置版本、設定頁、首頁與發版紀錄一致，不得再於多個 Widget 手寫不同版號。

### 驗收

- 一般畫面不再出現「軍規邏輯，民用保養」。
- 一般畫面不再出現手寫 `v0.14.0` 或 `v0.9.0`。
- 首頁直接說明生活管理用途。
- `flutter analyze`、`flutter test` 與 Web release build 全部通過後才合併。

### 批准

依產品憲法的直接、誠實與不製造假功能原則執行。

### PR／commit

- PR #172
- squash commit `c7594515937ea8bcc2b4fd4750d994d492db2764`

---

## LM-011：將假資料檔改為正式保養卡目錄

日期：2026-07-18  
類型：架構／資料治理

### 問題

`TodayScreen` 仍從 `MockData.maintenanceCards` 取得保養卡步驟、預估時間與風險資訊。原 `mock_data.dart` 同時包含假生活項目、假排程、假任務與假履歷，而且保養卡模板綁著假的 `itemId`。即使假生活項目目前沒有直接顯示，正式流程仍依賴混雜假資料的來源，未來很容易誤接回正式畫面或錯誤關聯使用者資料。

### 修改

- 新增 `MaintenanceCardCatalog` 作為正式保養卡模板目錄。
- 保留四張目前仍被既有任務卡 ID 使用的模板與原有步驟、風險、時間資料。
- 解析模板時以任務真正的 `itemId` 建立卡片，不再沿用假生活項目關聯。
- 未知 `cardId` 維持安全回傳 `null`。
- `TodayScreen` 改由正式目錄解析卡片。
- 刪除包含假生活項目、排程、任務與履歷的 `mock_data.dart`。
- 生活項目下拉選單只讀本機真實項目；沒有資料時保持停用，不再支援假資料 fallback。
- 新增目錄解析與真實 `itemId` 綁定測試。

### 明確未修改

- 不修改既有保養卡 ID，避免舊任務失去對應。
- 不修改 Task、Schedule、Item 或 MaintenanceRecord 的資料格式。
- 不遷移、不刪除任何使用者本機資料。
- 不修改今日任務產生、完成與後續排程邏輯。
- 不新增保養卡編輯功能。

### 資料影響

無持久化資料變更。這一批只清理程式內建目錄來源；既有本機 JSON 不會被讀寫或轉換。

### 驗收

- repo 不再存在 `MockData` 或 `mock_data.dart`。
- 新增提醒與補登紀錄表單不會在缺少真實項目時顯示假選項。
- 已知卡片 ID 仍可取得相同步驟、風險與預估時間。
- 解析後的卡片使用任務真正的 `itemId`。
- 未知卡片維持安全降級。
- `flutter analyze`、`flutter test` 與 Web release build 全部通過後才合併。

### 批准

依產品憲法「只做真的功能」與架構文件「正式資料不得依賴展示假資料」原則執行。

### PR／commit

- PR #173
- squash commit `cacb0b718dda835ee1ba5e954373ccce0adf970c`

---

## LM-012：建立處理案件與多筆進度模型基線

日期：2026-07-18  
類型：架構／資料模型

### 問題

現有 `Task` 只能表示某次提醒浮上檯面，`MaintenanceRecord` 主要保存已完成結果；兩者都無法表達一件修理、工程或辦理事項從發生、開始、等待、多次處理到結案的完整過程。若直接把進度塞回 Task 或完成紀錄，會再次混淆提醒、規則、實際事件與史略。

### 修改

- 新增 `WorkCaseSourceType`、`WorkCaseType` 與 `WorkCaseStatus`。
- 新增 `WorkCase`，保存來源、案件類型、標題、發生／開始時間、狀態、更新時間、結案結果與取消原因。
- 新增 `WorkCaseUpdate`，保存每一筆處理內容、店家／人員、判斷結果、費用、零件、照片識別、等待原因、備註與下一步。
- 兩個模型的 JSON 都加入 `schemaVersion`。
- 未知 enum 採安全 fallback；未知來源保留為 `unknown`，未知案件類型保留為 `other`，未知狀態回到 `notStarted`。
- `WorkCaseUpdate` 的零件與照片清單採不可修改清單，強化進度不可被後續內容原地覆蓋的原則。
- 新增完整 round-trip、未知 enum、結案、取消原因、nullable 清除、清單不可修改與舊格式安全預設測試。
- 架構文件由「建議欄位」更新為第一版正式模型基線。

### 明確未修改

- 不修改現有 Item、MaintenanceCard、Schedule、Task 或 MaintenanceRecord。
- 不建立案件 Repository 或 SharedPreferences 儲存鍵。
- 不執行舊資料遷移。
- 不讓任何現有 UI 建立或修改案件。
- 不更換正式資料庫。

### 資料影響

無。新模型目前尚未接入持久化層，不會讀寫任何既有本機 JSON。

### 驗收

- 案件與進度資料角色明確分離。
- 五種正式案件狀態可安全序列化。
- 未知 enum 不會造成整筆模型失敗。
- 手動案件可沒有 `sourceId`。
- 已完成與已取消案件可正確判斷為結案。
- 取消原因可被保存。
- 進度清單不可原地修改。
- `flutter analyze`、`flutter test` 與 Web release build 全部通過後才合併。

### 批准

依產品功能規格書第 7 至 11 節及架構文件已批准的 `WorkCase`／`WorkCaseUpdate` 方向執行。

### PR／commit

- PR #174
- squash commit `b8e880469e951d0970f9411a11a10961edd95d6e`

---

## LM-013：正式資料庫選擇 Drift + SQLite

日期：2026-07-18  
類型：架構／技術選型／資料安全

### 問題

SharedPreferences 的四組 JSON 可承接現有 MVP，但不適合長期保存 `Item → WorkCase → WorkCaseUpdate` 關聯、大量史略、照片識別與需要原子交易的複合操作。案件模型完成後，必須先以目前正式資料角色比較候選資料庫，不能先加入套件再硬套產品。

### 證據檢查

以官方文件比較 Drift、Hive CE、Isar、ObjectBox 與 sqflite，必要條件包括 iOS／Web、關聯查詢、交易、schema version、可驗證 migration、測試與長期維護。

### 決策

- 正式資料層採 Drift + SQLite。
- native 使用 `NativeDatabase`。
- Flutter Web 使用 `WasmDatabase`。
- Web 部署必須驗證 `sqlite3.wasm`、worker、持久化與瀏覽器 fallback。
- 完整選型依據、候選比較、已知成本、實作順序與重新評估條件記錄於 `07-database-decision.md`。

### 不採用重點

- Hive CE：跨平台，但 key-value／NoSQL 需要自行補足本專案的關聯、交易與 migration 證據鏈。
- Isar：有 ACID 與 links，但資料 migration 版本與流程需由 App 自行管理，原始穩定版與社群 fork 的長期治理風險較高。
- ObjectBox：官方 Dart／Flutter 平台文件未列 Web。
- sqflite：Web 實作仍標示 experimental。

### 明確未修改

- 不加入任何資料庫 dependency。
- 不建立正式 schema 或生成程式碼。
- 不新增資料庫檔案。
- 不讀寫、匯入或刪除任何 SharedPreferences 資料。
- 不讓 UI 或 Repository 改用 Drift。

### 資料影響

無。本批次只有架構決策與控制文件。

### 下一步邊界

下一個 PR 只允許鎖定相容 dependency、建立空 schema v1、`work_cases`／`work_case_updates` tables、必要索引、foreign keys、transaction tests 與 native／web 開啟基礎。不得同時遷移舊資料。

### 驗收

- 選型條件與證據來源可追溯。
- 已知 Web 成本與回復原則沒有被隱藏。
- README、架構文件與封存區的控制文件清單一致。
- PR 差異只包含文件。
- 現有 Analyze、Test 與 Web build 仍通過。

### 批准

依架構文件第 8 節的候選評估條件與產品資料角色執行。

### PR／commit

- PR #175
- squash commit `4c00bf4084aca2b9c1faaa57ad2580a97e3baf02`

---

## LM-014：建立 Drift 案件 schema v1

日期：2026-07-18  
類型：架構／資料庫／安全／CI

### 問題

案件與多筆進度模型已定義，但尚無可驗證的正式關聯式 schema。若直接把新模型塞進 SharedPreferences，會延續多組 JSON、部分寫入與關聯無法驗證的問題；若同時建立 schema 又搬移舊資料，則風險範圍過大且難以回復。

### 修改

- 鎖定 `drift 2.34.2`、`drift_flutter 0.3.1`、`sqlite3 3.4.0`、`drift_dev 2.34.4` 與 `build_runner 2.15.1`。
- 建立 `AppDatabase` schema version 1。
- 建立 `work_cases` 與 `work_case_updates` 兩張表。
- 建立案件狀態、來源、更新時間與案件進度時間索引。
- `work_case_updates.work_case_id` 使用 foreign key；有進度的案件不得直接刪除。
- 日期採 ISO 8601 文字儲存，保留微秒與 UTC 資訊。
- enum converter 對未知值保留安全 fallback。
- 零件與照片識別清單以 JSON 文字保存；格式異常時安全回傳空清單。
- native 使用 Drift SQLite 開啟基礎；Web 指向 matching `sqlite3.wasm` 與 worker。
- 加入可重現的 Web WASM 準備腳本與 worker 原始碼。
- CI 在 Analyze 前執行 code generation、worker 編譯、matching WASM 準備與資產驗證。
- 新增建表、日期精度、foreign key、限制刪除與 transaction rollback 測試。

### 明確未修改

- 不讓 `main.dart` 開啟 `AppDatabase`。
- 不建立正式案件 Repository。
- 不讀寫、匯入、轉換或刪除 `items`、`schedules`、`tasks`、`maintenance_records`。
- 不修改現有 SharedPreferences 儲存鍵。
- 不新增案件 UI。
- 不切換正式資料來源。

### 資料影響

無現有資料影響。schema v1 雖已可建立，但目前沒有被 App 啟動或寫入；現行 SharedPreferences 仍照原流程運作。

### 生成與資產原則

- `app_database.g.dart`、worker JavaScript 與 `sqlite3.wasm` 是可重現產物，不直接提交。
- `pubspec.lock` 必須提交，確保套件版本可重現。
- Web build 除了成功編譯，還必須確認 worker 與 matching WASM 實際存在於輸出。

### 驗收

- dependency resolution 與 code generation 通過。
- schema v1 建立兩張正確資料表。
- ISO 日期可保留微秒與 UTC。
- 孤兒進度被 foreign key 阻止。
- 有進度的案件不可直接刪除。
- transaction 失敗不留下部分案件或進度。
- Analyze、全部測試、Web release build 與 Web 資產驗證全部通過。

### 批准

依 `07-database-decision.md` 的第一版 schema 邊界執行。

### PR／commit

- PR #176
- squash commit `6c3ff4fdf1de5a8d08c50b56189465493c0177a9`

---

## LM-015：建立案件 Repository 邊界

日期：2026-07-18  
類型：架構／資料／治理

### 問題與原因

建立案件查詢、模型轉換與原子寫入邊界。

### 修改

依 PR #177 的核准範圍完成對應模型、服務、測試或控制文件。

### 明確未修改

不接 UI、不建立全域資料庫、不遷移 SharedPreferences。

### 資料影響

無既有使用者資料寫入、刪除或遷移。

### 驗收結果

Drift code generation、Analyze、全部測試、Web release build 與 Drift Web 資產驗證均通過。

### 批准狀態

已依產品憲法、資料安全與最小變更原則批准並合併。

### PR／commit

- PR #177
- squash commit `43d3442b7543c69d7c5628a78a6bcb3dae9f6d24`

---

## LM-016：建立只讀遷移準備盤點

日期：2026-07-18  
類型：架構／資料／治理

### 問題與原因

盤點四組來源、不可變備份與 Drift 目標表狀態。

### 修改

依 PR #178 的核准範圍完成對應模型、服務、測試或控制文件。

### 明確未修改

不修復、不補備份、不匯入，也不呼叫儲存或刪除。

### 資料影響

無既有使用者資料寫入、刪除或遷移。

### 驗收結果

Drift code generation、Analyze、全部測試、Web release build 與 Drift Web 資產驗證均通過。

### 批准狀態

已依產品憲法、資料安全與最小變更原則批准並合併。

### PR／commit

- PR #178
- squash commit `ed90a0a0e5b546e3bbbc82c09a4fbbfc796071e0`

---

## LM-017：建立舊資料關聯稽核

日期：2026-07-18  
類型：架構／資料／治理

### 問題與原因

檢查逐筆解析、重複 ID 與斷裂關聯。

### 修改

依 PR #179 的核准範圍完成對應模型、服務、測試或控制文件。

### 明確未修改

不修復舊資料、不寫入 Drift、不接 UI。

### 資料影響

無既有使用者資料寫入、刪除或遷移。

### 驗收結果

Drift code generation、Analyze、全部測試、Web release build 與 Drift Web 資產驗證均通過。

### 批准狀態

已依產品憲法、資料安全與最小變更原則批准並合併。

### PR／commit

- PR #179
- squash commit `f3cfd329c717a0f753ff20a8a704a7eee5b1a255`

---

## LM-018：建立遷移准入閘門

日期：2026-07-18  
類型：架構／資料／治理

### 問題與原因

整合備份、解析、重複 ID、關聯與目標表狀態。

### 修改

依 PR #180 的核准範圍完成對應模型、服務、測試或控制文件。

### 明確未修改

通過准入不代表匯入，本批次沒有寫入能力。

### 資料影響

無既有使用者資料寫入、刪除或遷移。

### 驗收結果

Drift code generation、Analyze、全部測試、Web release build 與 Drift Web 資產驗證均通過。

### 批准狀態

已依產品憲法、資料安全與最小變更原則批准並合併。

### PR／commit

- PR #180
- squash commit `99a492132459dcf61417ede2cab4182f97e4aaf6`

---

## LM-019：鎖定舊資料遷移範圍

日期：2026-07-18  
類型：架構／資料／治理

### 問題與原因

確認 schema v1 尚無舊四組資料的合法目標表。

### 修改

依 PR #181 的核准範圍完成對應模型、服務、測試或控制文件。

### 明確未修改

不新增 schema、不建立 mapper、不執行轉換預演。

### 資料影響

無既有使用者資料寫入、刪除或遷移。

### 驗收結果

Drift code generation、Analyze、全部測試、Web release build 與 Drift Web 資產驗證均通過。

### 批准狀態

已依產品憲法、資料安全與最小變更原則批准並合併。

### PR／commit

- PR #181
- squash commit `db97c41a38dbcbb34b476131ea2c6d4b05eeb12b`

---

## LM-020：正式標示 v0.5.0 Foundation

日期：2026-07-18  
類型：架構／資料／治理

### 問題與原因

建立三碼版本唯一來源與版本規則。

### 修改

依 PR #182 的核准範圍完成對應模型、服務、測試或控制文件。

### 明確未修改

不在 Widget 手寫版號，不修改功能或資料格式。

### 資料影響

無既有使用者資料寫入、刪除或遷移。

### 驗收結果

Drift code generation、Analyze、全部測試、Web release build 與 Drift Web 資產驗證均通過。

### 批准狀態

已依產品憲法、資料安全與最小變更原則批准並合併。

### PR／commit

- PR #182
- squash commit `35c097fdd02302d595739a71b6c2733c64f89ca6`

---

## LM-021：正式分離保養項目與模板／排程／案件

日期：2026-07-18  
類型：架構／資料／治理

### 問題與原因

補回 MaintenancePlan 正式角色，禁止 Schedule 代替保養項目。

### 修改

依 PR #183 的核准範圍完成對應模型、服務、測試或控制文件。

### 明確未修改

不修改資料庫、不接 UI、不搬移舊資料。

### 資料影響

無既有使用者資料寫入、刪除或遷移。

### 驗收結果

Drift code generation、Analyze、全部測試、Web release build 與 Drift Web 資產驗證均通過。

### 批准狀態

已依產品憲法、資料安全與最小變更原則批准並合併。

### PR／commit

- PR #183
- squash commit `b0b840bfff04d352b5c24e2c421df3662e79548c`

---

## LM-022：建立 MaintenancePlan 模型基線

日期：2026-07-18  
類型：架構／資料／治理

### 問題與原因

建立可序列化並保存步驟快照的保養項目模型。

### 修改

依 PR #184 的核准範圍完成對應模型、服務、測試或控制文件。

### 明確未修改

不建立 Repository、Drift table 或 UI。

### 資料影響

無既有使用者資料寫入、刪除或遷移。

### 驗收結果

Drift code generation、Analyze、全部測試、Web release build 與 Drift Web 資產驗證均通過。

### 批准狀態

已依產品憲法、資料安全與最小變更原則批准並合併。

### PR／commit

- PR #184
- squash commit `cab5af9d5e5f23bbffb5162f43c6ac83f2c8572e`

---

## LM-023：建立地基缺口修正計畫

日期：2026-07-18  
類型：架構／資料／治理

### 問題與原因

正式阻擋缺少 Milestone、週期基準、結案與附件等角色的 schema v2 草稿。

### 修改

依 PR #186 的核准範圍完成對應模型、服務、測試或控制文件。

### 明確未修改

PR #185 維持 Draft，不開始 schema v2 程式施工。

### 資料影響

無既有使用者資料寫入、刪除或遷移。

### 驗收結果

Drift code generation、Analyze、全部測試、Web release build 與 Drift Web 資產驗證均通過。

### 批准狀態

已依產品憲法、資料安全與最小變更原則批准並合併。

### PR／commit

- PR #186
- squash commit `e0e9d7fe406a9e50c2f6393d10258d6686823eac`

---

## LM-024：建立 Milestone／大修模型基線

日期：2026-07-18  
類型：架構／資料／治理

### 問題與原因

承接第六年大修、里程、次數、日期與人生階段等條件。

### 修改

依 PR #187 的核准範圍完成對應模型、服務、測試或控制文件。

### 明確未修改

不接 Drift、Repository、UI 或舊資料。

### 資料影響

無既有使用者資料寫入、刪除或遷移。

### 驗收結果

Drift code generation、Analyze、全部測試、Web release build 與 Drift Web 資產驗證均通過。

### 批准狀態

已依產品憲法、資料安全與最小變更原則批准並合併。

### PR／commit

- PR #187
- squash commit `f5a40777130d8116882c0d77f9c128e89fddc56d`

---

## LM-025：正式生活項目類別策略

日期：2026-07-18  
類型：架構／資料／治理

### 問題與原因

採系統大類加使用者自訂名稱，避免產品被限縮為設備維護。

### 修改

依 PR #188 的核准範圍完成對應模型、服務、測試或控制文件。

### 明確未修改

不修改 Item 模型、資料庫或既有分類。

### 資料影響

無既有使用者資料寫入、刪除或遷移。

### 驗收結果

Drift code generation、Analyze、全部測試、Web release build 與 Drift Web 資產驗證均通過。

### 批准狀態

已依產品憲法、資料安全與最小變更原則批准並合併。

### PR／commit

- PR #188
- squash commit `c3ad904bc26e56586497b83e49b2eba00a1baa55`

---

## LM-026：建立固定週期基準策略

日期：2026-07-18  
類型：架構／資料／治理

### 問題與原因

建立日不移日、週不移週等固定曆期計算基線。

### 修改

依 PR #189 的核准範圍完成對應模型、服務、測試或控制文件。

### 明確未修改

不修改舊 Schedule、任務完成流程或既有排程。

### 資料影響

無既有使用者資料寫入、刪除或遷移。

### 驗收結果

Drift code generation、Analyze、全部測試、Web release build 與 Drift Web 資產驗證均通過。

### 批准狀態

已依產品憲法、資料安全與最小變更原則批准並合併。

### PR／commit

- PR #189
- squash commit `39c43874f5f5cd5f1d1915d90bb5bac58bd553fc`

---

## LM-027：建立正式案件結案模型

日期：2026-07-18  
類型：架構／資料／治理

### 問題與原因

將案件生命週期、處理過程與人工確認的正式結案摘要分離。

### 修改

依 PR #190 的核准範圍完成對應模型、服務、測試或控制文件。

### 明確未修改

不修改 WorkCase／WorkCaseUpdate、不接 Drift 或 UI。

### 資料影響

無既有使用者資料寫入、刪除或遷移。

### 驗收結果

Drift code generation、Analyze、全部測試、Web release build 與 Drift Web 資產驗證均通過。

### 批准狀態

已依產品憲法、資料安全與最小變更原則批准並合併。

### PR／commit

- PR #190
- squash commit `ec640244a60124941a30e85aaabf606cbb79d1aa`

---

## LM-028：建立 Schedule／Task 來源一致性契約

日期：2026-07-18  
類型：架構／資料／治理

### 問題與原因

禁止空字串假外鍵、來源矛盾與跨生活項目錯配。

### 修改

依 PR #191 的核准範圍完成對應模型、服務、測試或控制文件。

### 明確未修改

不修改舊 Schedule／Task、不建立資料表或遷移。

### 資料影響

無既有使用者資料寫入、刪除或遷移。

### 驗收結果

Drift code generation、Analyze、全部測試、Web release build 與 Drift Web 資產驗證均通過。

### 批准狀態

已依產品憲法、資料安全與最小變更原則批准並合併。

### PR／commit

- PR #191
- squash commit `494b32a200c672bf02260778c71544258aa748fa`

---

## LM-029：建立附件／照片生命週期模型

日期：2026-07-18  
類型：架構／資料／治理

### 問題與原因

補上附件所有權、檔案狀態、遺失與刪除生命週期。

### 修改

依 PR #192 的核准範圍完成對應模型、服務、測試或控制文件。

### 明確未修改

不搬動現有照片、不接檔案系統、Drift 或 UI。

### 資料影響

無既有使用者資料寫入、刪除或遷移。

### 驗收結果

Drift code generation、Analyze、全部測試、Web release build 與 Drift Web 資產驗證均通過。

### 批准狀態

已依產品憲法、資料安全與最小變更原則批准並合併。

### PR／commit

- PR #192
- squash commit `0be21cd8ebb3b17ea37addf886a1121cee62a086`

---

## LM-030：v0.5.1 正式 Runtime 資料流稽核與單一寫入控制

日期：2026-07-19
類型：資料／架構／安全／治理

### 問題與原因

Schema v2、v1 → v2 migration 與 Repository 已建立，但正式 Runtime 仍由 SharedPreferences／LocalRepository 讀寫。若沒有先完整盤點呼叫點、欄位差距與切換紅線，後續接線可能形成雙寫、部分完成、錯誤欄位推論或無法安全 rollback。

### 修改

- 建立正式 Runtime 讀寫證據清單。
- 列出 Drift Repository coverage、模型欄位 mapping 與資料風險。
- 凍結單一 writer、只讀雙讀、匯入、切換、rollback 與驗收順序。
- 將 Foundation patch 版本更新為 v0.5.1。

### 明確未修改

不修改 Dart 程式、Schema、Migration、Repository、SharedPreferences 資料或 UI；不執行匯入與切換。

### 資料影響

無使用者資料讀寫、刪除或搬移。

### 驗收結果

以 PR #202 的 codegen、Analyze、全部測試、Web release build 與 GitHub Actions 結果為準。

### 批准狀態

本條目只批准稽核控制與 v0.5.1 文件基線，不批准下一階段施工。

### PR

- PR #202

---

## LM-031：v0.5.2 SharedPreferences → Drift v2 安全匯入器

日期：2026-07-19
類型：資料／安全／測試

### 問題與原因

正式 Runtime 仍以 SharedPreferences 為單一 writer，但 Schema v2 尚缺少可先 dry-run、完整比對並於失敗時整批 rollback 的安全匯入機制。直接接線或逐筆寫入會形成雙寫、部分完成與既有資料覆蓋風險。

### 修改

- 建立來源唯讀的 SharedPreferences adapter、逐組不可變備份比對與 SHA-256 摘要。
- 建立 Item、Category、MaintenancePlan／Step、GeneralReminder、Schedule、Task、MaintenanceRecord 與 Attachment 的確定 mapping。
- 以單一 Drift transaction 寫入，commit 前後驗證逐列內容、foreign key 與 database integrity。
- 建立 dry-run、重複匯入 no-op、partial／conflict blocker 與中途失敗 rollback。
- 保留 v1 → v2 migration 的 WorkCase／Update；只允許把可證明的 placeholder Item 更新為原 SharedPreferences Item。
- 將版本更新為 v0.5.2。

### 明確未修改

不修改 Runtime composition、Repository 接線、UI、Drift Schema、database migration 或 SharedPreferences 內容；不執行真機匯入，不開始下一個 PR。

### 資料影響

匯入器目前沒有 Runtime 呼叫點。dry-run 零寫入；execute 要求來源 writer 已停用。任何失敗整筆 transaction rollback，來源與 `backup_v1_*` 永遠不被匯入器修改。

### 驗收結果

以 PR #203 的 codegen、Analyze、全部測試、Web release build 與 GitHub Actions 結果為準。

### PR

- PR #203

---

## LM-032：v0.5.3 正式 Runtime Composition Root

日期：2026-07-19
類型：架構／安全／測試

### 問題與原因

正式畫面各自建立 LocalRepository 或 LocalStorageService，且 AppDatabase、Drift Schema v2 Repository 與必要 Service 尚未由單一 Runtime 入口管理。這會妨礙後續受控切換，也可能形成不同生命週期或資料來源。

### 修改

- 建立唯一 `AppCompositionRoot`，統一擁有 AppDatabase、完整 Drift Schema v2 Repository 組、現行 LocalRepository 與必要 Service。
- 以 `AppCompositionScope` 注入正式畫面，移除畫面與 widget 內的 Repository、LocalStorageService 建構。
- App 啟動前備份與完整性檢查改用同一 Root 依賴。
- 提供外部 AppDatabase／LocalStorageService 測試注入，並以記憶體 Drift executor 驗證 Root 與 Scope。
- 將版本更新為 v0.5.3。

### 明確未修改

不執行 SharedPreferences → Drift 匯入，不切換 UI 的正式資料來源，不修改 Schema、Migration、Domain、功能或畫面設計，不新增雙寫或平行流程。

### 資料影響

SharedPreferences 仍是正式 Runtime 唯一資料來源與 writer。Drift Repository 只由 Root 建立，未注入現行 UI、未執行匯入或寫入；本 PR 不搬移、刪除或覆蓋任何使用者資料。

### 驗收結果

以 PR #204 的 codegen、Analyze、全部測試、Web release build 與 GitHub Actions 結果為準。

### PR

- PR #204

---

## LM-033：v0.5.4 受控匯入與 Item 讀取切換

日期：2026-07-19
類型：資料／架構／安全／測試

### 問題與原因

安全 importer 與 Composition Root 已建立，但正式啟動流程尚未執行匯入，ItemCategory／Item 仍由 SharedPreferences 讀取。若未先凍結來源、驗證目標與定義失敗 rollback，直接切換會形成部分資料或雙寫風險。

### 修改

- AppCompositionRoot 啟動時建立備份、執行完整性預檢並以單一 transaction 執行既有安全 importer。
- `imported`／`alreadyImported` 後將 ItemCategory／Item read repository 切換至 Drift。
- 建立底層 SharedPreferences 唯讀 gate，匯入成功後禁止所有 save／remove。
- blocked 或例外時保持 legacy Item reader、恢復舊 writer 並確保 Drift rollback。
- 首頁生活總覽、生活項目清單／詳情與 Item 名稱投影改用共同 `ItemReadRepository`。
- 更新版本為 v0.5.4。

### 明確未修改

不切換 Task、Schedule、MaintenanceRecord 或 WorkCase writer，不修改 UI 設計、Schema、Migration、Domain 或功能，不刪除、覆蓋或回寫 SharedPreferences 與備份。

### 資料影響

只有完整驗證成功時 importer 才寫入 Drift；成功後 SharedPreferences 永久唯讀。任何 blocker 或 transaction 失敗整批 rollback，來源原文保持不變且 Runtime 回到舊來源。

### 驗收結果

以 PR #205 的匯入／rollback、codegen、Analyze、全部測試、Web release build、預覽與 GitHub Actions 結果為準。

### PR

- PR #205

---

## LM-034：v0.5.5 Planning Repository Drift 切換

日期：2026-07-19
類型：資料／架構／安全／測試

### 問題與原因

PR #205 已完成匯入與 Item 讀取切換，但 MaintenancePlan、GeneralReminder、Milestone 與 Schedule 尚未由正式 Runtime 注入 Drift writer。若繼續使用舊 ScheduleLocalRepository，成功匯入後會觸發唯讀 gate，也無法以單一 transaction 維持 GeneralReminder／Schedule source contract。

### 修改

- 建立 Schedule Runtime Repository boundary 與 Drift adapter。
- 以單一 transaction 建立／更新 GeneralReminder 與 Schedule，禁止隱式刪除、跨 Item 移動與未驗證 source。
- 保留 MaintenancePlan、GeneralReminder、Milestone 的正式 Drift CRUD，由 AppCompositionRoot 在匯入驗證後統一注入。
- 正式映射 fixedCalendarPeriod、completionBased 與 userDefined，更新時不把完成基準誤改為曆法基準。
- 冷啟動重驗時，只接受不可變 planning 身分一致的正式欄位變更；Item、Task、Record 與 Attachment 繼續嚴格逐欄比對。
- 版本更新為 v0.5.5。

### 明確未修改

不切換 Task、MaintenanceRecord、WorkCase 或 WorkCaseClosure writer；不修改 Schema、Migration、正式畫面設計或產品功能，不建立 History writer 或其他平行流程。

### 資料影響

SharedPreferences 與 `backup_v1_*` 維持唯讀，不刪除、覆蓋或回寫。Planning 資料只寫入 Drift；任一轉換、約束或寫入失敗時整個 transaction rollback。

### 驗收結果

以 PR #206 的 codegen、Analyze、全部測試、Web release build、預覽與 GitHub Actions 結果為準。

### PR

- PR #206

---

## LM-035：v0.5.6 Task Repository Drift 切換

日期：2026-07-19
類型：資料／架構／安全／測試

### 問題與原因

PR #206 已完成 planning repository 切換，但正式 Runtime 仍以 TaskLocalRepository 讀寫提醒，首頁也保留 Task 直接完成並建立 MaintenanceRecord 的舊流程。這會混淆提醒、案件與結案角色，並在 SharedPreferences 唯讀後阻止正式到期 Task 產生。

### 修改

- 建立 Task Runtime Repository boundary 與 Drift adapter。
- Task 依 Schedule 的 MaintenancePlan、GeneralReminder 或 Milestone source contract 產生。
- 以單一 transaction 寫入一批 Task，阻擋缺失來源、跨 Item、同批 composite key 重複，並對既有相同 `scheduleId + dueDate` 採 idempotent 處理。
- AppCompositionRoot 在受控匯入驗證後統一注入 Drift Task Repository。
- 正式首頁移除 Task 直接完成、Schedule follow-up 與自動建立 MaintenanceRecord 的舊流程。
- 版本更新為 v0.5.6。

### 明確未修改

不切換 MaintenanceRecord、WorkCase 或 WorkCaseClosure；不修改 Schema、Migration、UI 視覺、新功能或 History 流程。

### 資料影響

SharedPreferences 與 `backup_v1_*` 維持唯讀，不刪除、覆蓋或回寫。Task 正式寫入只發生於 Drift；任一轉換、約束或寫入失敗時整批 rollback。

### 驗收結果

以 PR #207 的 codegen、Analyze、全部測試、Web release build、預覽與 GitHub Actions 結果為準。

### PR

- PR #207

---

## LM-036：v0.5.7 正式 WorkCase Runtime

日期：2026-07-19
類型：資料／架構／安全／測試

### 問題與原因

Schema v2 已有 WorkCase、WorkCaseUpdate 與 WorkCaseClosure，底層 Repository 也已建立，但 AppCompositionRoot 尚未提供正式案件 Runtime，Task 開始處理後沒有受控、可交易且可測試的案件生命週期入口。

### 修改

- 建立 WorkCaseRuntime 與 WorkCaseClosureRepository 正式邊界。
- 支援由 Maintenance、GeneralReminder、Milestone Task 或手動建立 WorkCase，並驗證所有來源與 WorkCase 屬於同一 Item。
- 支援多筆不可覆寫 WorkCaseUpdate，以及 Update 與非終止狀態的單一 transaction 寫入。
- WorkCaseClosure 與 completed／canceled 狀態維持單一 transaction，並阻擋第二筆 Closure。
- 終止後禁止修改案件、追加進度或更新狀態；案件 Item、來源與建立身分不可移動。
- AppCompositionRoot 只在受控匯入成功後注入案件 Runtime，版本更新為 v0.5.7。

### 明確未修改

不重畫 UI、不修改 Schema、Migration、SharedPreferences、MaintenanceRecord 或 History，不新增平行流程或下一階段功能。

### 資料影響

案件正式資料只寫入 Drift。SharedPreferences 與 `backup_v1_*` 保持唯讀，不刪除、覆蓋或雙寫；任一複合操作失敗時整筆 transaction rollback。

### 驗收結果

以 PR #208 的 codegen、Analyze、全部測試、Web release build、預覽與 GitHub Actions 結果為準。

### PR

- PR #208

---

## LM-037：v0.5.8 正式 History Projection 與 Attachment Runtime

日期：2026-07-19
類型：資料／架構／安全／測試

### 問題與原因

Schema v2 已保存案件、結案、舊完成紀錄與附件 metadata，但 Runtime 尚無統一、唯讀且可重建的 History 查詢，也未透過正式 Attachment abstraction 阻擋平台路徑、孤兒 Owner 與非法生命週期轉換。

### 修改

- 建立只讀 HistoryProjectionRepository，由 WorkCase、WorkCaseUpdate、WorkCaseClosure、MaintenanceRecord、Task、Milestone 與 Attachment 組合 Item 歷史。
- 不新增 History table 或 writer；舊 terminal WorkCase 缺少 Closure 時保留缺漏，不補造結案事實。
- 建立 AttachmentRepository／AttachmentRuntime 正式邊界，驗證 stable managed identifier、MIME、Owner 與初始狀態。
- 完整保存 available、missing、deleted 與 verifiedAt、missingAt、deletedAt；deleted 後保持不可變。
- AppCompositionRoot 只在受控匯入成功後注入兩個 Runtime，版本更新為 v0.5.8。

### 明確未修改

不重畫或接線 UI，不修改 Schema、Migration、SharedPreferences、既有匯入規則或案件生命週期，不新增 cache、同步表、檔案搬移功能或下一階段功能。

### 資料影響

History 查詢完全唯讀，不產生第三份真相。Attachment 只更新既有 Schema v2 metadata 生命週期；SharedPreferences 與 `backup_v1_*` 保持唯讀，不刪除、覆蓋或雙寫。

### 驗收結果

以 PR #209 的 codegen、Analyze、全部測試、Web release build、預覽與 GitHub Actions 結果為準。

### PR

- PR #209

---

## LM-038：v0.5.9 正式 MaintenanceRecord Runtime

日期：2026-07-19
類型：資料／架構／安全／測試

### 問題與原因

Schema v2 已保存舊匯入完成紀錄，但正式 Runtime 尚未提供受控的簡單完成入口，也未以 transaction 強制 Task、MaintenanceRecord 與 WorkCaseClosure 的資料角色邊界。

### 修改

- 建立 MaintenanceRecordRepository 正式邊界及 Drift Runtime adapter。
- 舊匯入紀錄與新簡單完成紀錄由同一 domain mapping 讀取，未知舊 record type 安全保留為 `other`。
- 手動簡單紀錄不得關聯 Task；Task 簡單完成會在單一 transaction 內建立唯一 MaintenanceRecord 並更新 Task terminal 狀態。
- 驗證 Item、Task、MaintenancePlan 均屬同一 Item；已進入 WorkCase 的來源不得另建 MaintenanceRecord，必須由唯一 WorkCaseClosure 結案。
- 新紀錄不得以 legacy photo path 繞過 Attachment Runtime；History 直接投影正式 MaintenanceRecord fact。
- AppCompositionRoot 只在受控匯入成功後注入正式 Repository，版本更新為 v0.5.9。

### 明確未修改

不重畫或接線 UI，不修改 Schema、Migration、SharedPreferences、Legacy Runtime 或既有匯入規則，不新增功能、平行 History／Closure 流程或下一個 PR。

### 資料影響

SharedPreferences 與 `backup_v1_*` 保持唯讀，不刪除、覆蓋或雙寫。Task 與 MaintenanceRecord 複合寫入任一步失敗時完整 rollback；WorkCaseClosure 不會同步複製成 MaintenanceRecord。

### 驗收結果

以 PR #210 的 codegen、Analyze、全部測試、Web release build、History Projection 驗證、預覽與 GitHub Actions 結果為準。

### PR

- PR #210

---

## LM-039：v0.5.10 Legacy Runtime 最終稽核與退休 Gate

日期：2026-07-19
類型：稽核／架構／安全／測試／文件

### 問題與原因

各正式 Drift Runtime 已逐步建立，但 LocalRepository、LocalStorageService 與 SharedPreferences 仍存在於 Composition Root、畫面、Widget、匯入／回復 Service 及測試。若只依「Drift Repository 已存在」便刪除舊程式，會破壞完成紀錄畫面、冷啟動 admission 與 blocked import rollback。

### 修改

- 全量掃描正式入口、AppCompositionRoot、screen、widget、service、repository 與 test 的 SharedPreferences／Local 依賴。
- 逐點分類為正式 Runtime 已無直接引用、唯讀備份／回復需要、或尚不可移除。
- 正式判定退休 Gate 尚未通過：Items／History 仍讀舊 MaintenanceRecord，新增 Item／補登紀錄仍保留被 Gate 關閉的 legacy writer 程式，完整 rollback 仍需 LegacyRuntimeDependencies。
- 新增架構防回歸測試，鎖定 SharedPreferences 單一 abstraction、screen／widget 禁止自行建構舊 persistence、已知 UI blocker 清單、Drift 唯一正式 writer、來源零雙寫、冷啟動維持 Drift 及 admission 失敗完整 rollback。
- 版本更新為 v0.5.10。

### 明確未修改

不刪除 Legacy Runtime、不修改 UI、Schema、Migration、匯入 mapping 或正式 CRUD，不搬資料、不新增功能、不開始下一個 PR。

### 資料影響

沒有 production 資料寫入變更。SharedPreferences 與 `backup_v1_*` 維持既有唯讀／不可變規則；防回歸測試使用隔離的記憶體 SharedPreferences 與 Drift database。

### 驗收結果

以 PR #211 的 codegen、Analyze、全部測試、Web release build、GitHub Actions 與 PR 說明為準。

### PR

- PR #211

---

## LM-040：v0.5.11 Drift 安全 Runtime 與 MaintenanceRecord 讀取切換

日期：2026-07-19
類型：架構／資料安全／Runtime／測試／文件

### 問題與原因

v0.5.10 稽核確認 Items／History 仍以 `MaintenanceRecordLocalRepository` 讀取舊來源，且 admission 失敗會恢復 Legacy Runtime writer。這會讓正式畫面的完成紀錄存在雙 read model，並讓 rollback 再次把 SharedPreferences 變成 writer，不符合 Drift 單一正式 writer 與 Legacy 唯讀回復來源規則。

### 修改

- `MaintenanceRecordRepository` 增加正式全量 read contract，Drift adapter 提供排序後的完整紀錄。
- Items／History 與補登紀錄 Widget 改依賴正式 MaintenanceRecord contract，screen／widget 不再引用 `MaintenanceRecordLocalRepository`。
- AppCompositionRoot 成功 admission 後統一注入 Drift MaintenanceRecord Repository。
- 備份、完整性或匯入失敗時改進入 `driftSafeReadOnly`：讀取既有 Drift 狀態並阻擋 Schedule、Task、MaintenanceRecord 與 Legacy storage mutation，不再恢復舊 Runtime writer。
- 新增 Drift-only MaintenanceRecord 畫面驗證、靜態依賴 Gate、冷啟動、來源不一致及備份失敗防回歸測試。
- 版本更新為 v0.5.11。

### 明確未修改

不刪除 Legacy 程式，不修改 UI 視覺、Schema、Migration、匯入 mapping 或 Domain role，不新增功能、平行流程、無關重構或下一個 PR。

### 資料影響

沒有刪除、覆蓋或雙寫 SharedPreferences 與 `backup_v1_*`。成功狀態只有 Drift 可寫；失敗安全狀態不提供任何正式 domain writer。匯入 transaction 仍由既有機制完整 rollback。

### 驗收結果

以 PR #212 的 Gate、codegen、Analyze、全部測試、Web release build、預覽驗證、GitHub Actions 與 PR 說明為準。

### PR

- PR #212

---

## LM-041：v0.5.12 Legacy Runtime 正式退休

日期：2026-07-19
類型：架構／資料安全／Runtime／測試／文件

### 問題與原因

v0.5.11 已完成所有正式資料讀寫切換並禁止 Legacy writer fallback，但 AppCompositionRoot 仍於正常啟動建立四個 LocalRepository、讀取 SharedPreferences、執行備份／admission／import，並保留 generic Legacy writer API。這些依賴已不再屬於正式 Runtime，持續存在會讓舊來源重新進入 business data flow。

### 修改

- AppCompositionRoot 改為直接建立完整 Drift Runtime，正常 initialize 不讀取或注入任何 Legacy persistence。
- main 啟動流程移除 Legacy integrity preflight／listener／fallback state，只等待正式 Drift Runtime 就緒。
- AppRuntimeDependencies 移除 ItemLocalRepository、backup／integrity service、legacy writer 狀態與 Legacy mode。
- LocalStorageService 移除 generic save、remove 與 writer toggle，只保留 readString 及受限 `backup_v1_*` immutable write-if-absent。
- Item／Schedule／Task／MaintenanceRecord LocalRepository 移除所有 writer，僅保留 recovery read／parser。
- 測試相容 writer 移至 `test/`，並新增正式 Runtime 零 Legacy dependency、Drift-only cold start、來源不變及 recovery 工具保留 Gate。
- 版本更新為 v0.5.12。

### 明確未修改

不刪除舊資料或備份，不修改 UI 視覺、Schema、Migration、匯入 mapping、Domain、新功能、平行流程或下一個 PR。

### 資料影響

沒有資料搬移、刪除或覆蓋。SharedPreferences business keys 與 `backup_v1_*` 原文保留；正常 Runtime 不再讀寫它們。受控 importer 仍只從 read-only source 讀取並以單一 Drift transaction 寫入目標。

### 驗收結果

以 PR #213 的 Gate、codegen、Analyze、全部測試、Web release build、GitHub Actions 與 PR 說明為準。

### PR

- PR #213

---

## LM-042：v0.5.13 正式 App Shell

日期：2026-07-19
類型：架構／導覽／Theme／測試／文件

### 問題與原因

既有 `main.dart` 同時負責 App 啟動、Theme、Composition Scope、Runtime readiness 與五個底部入口，且入口仍使用「今日／我的項目／履歷」等過渡名稱。這使正式 Shell 邊界不清楚，也不利於後續 UI 在不碰 Runtime 的前提下逐步施工。

### 修改

- 建立正式 `AppShell`，固定生活總覽、生活項目、新增、史略與設定五個入口。
- 五個入口只承接既有 Screen，不新增 route、功能或平行流程。
- 將既有 Theme 原值抽出為共用 `AppTheme.light`，不重新設計畫面。
- `LifeMaintenanceApp` 持續只持有一個 AppCompositionRoot，並由既有 AppCompositionScope 提供給全部畫面。
- 新增 Shell destination、Theme 與 Composition Root 注入防回歸測試。
- 版本更新為 v0.5.13。

### 明確未修改

不修改任何 Screen／Widget 功能，不修改 Schema、Migration、Database、Repository、Service、Runtime、Domain 或資料流程，不新增產品功能、平行導覽或下一個 PR。

### 資料影響

無資料格式、資料內容或資料存取行為變更。Drift 仍是唯一正式資料來源；Legacy recovery 邊界不變。

### 驗收結果

以 PR #214 的 Shell Gate、codegen、Analyze、全部測試、Web release build、GitHub Actions 與 PR 說明為準。

### PR

- PR #214

---

## LM-043：v0.5.14 生活總覽接 Drift 真實資料

日期：2026-07-19
類型：首頁／資料投影／測試／文件

### 問題與原因

正式 App Shell 已將第一入口定義為生活總覽，但既有 TodayScreen 仍只顯示 Task 清單，無法呈現進行中案件、階段性重點與最近完成，也不足以代表完整生活管理。

### 修改

- 生活總覽以 Item 為 Root，從既有正式讀取邊界組合首頁資料。
- 今日提醒由 Task Repository 提供，只顯示今天到期或逾期且尚未終止的提醒。
- 進行中案件由 WorkCase Runtime 提供，只顯示未結案案件及其正式最新進度／下一步。
- 階段性重點由 Milestone Repository 提供，只顯示未關閉的正式重點。
- 最近完成由唯讀 History Projection 提供，只顯示完成案件、MaintenanceRecord、完成 Task 或完成 Milestone，不把取消事項標成完成。
- 今天狀態顯示正式提醒、進行中案件與階段性重點總數，不使用完成率、評分或催促文案。
- 新增完整 Drift fixture Widget test，驗證五個區塊、未到期提醒排除及讀取前後來源筆數不變。
- 版本更新為 v0.5.14。

### 明確未修改

不修改 Runtime、Schema、Migration、Database、Repository／Service contract、其他畫面、寫入流程或導覽，不新增功能、首頁資料表、cache、writer、平行 History 或下一個 PR。

### 資料影響

沒有資料格式或既有資料內容變更。首頁只讀取既有正式資料；原有 Schedule 到期 Task 產生行為維持不變，History 仍是唯讀投影。

### 驗收結果

以 PR #215 的 Drift fixture、Analyze、全部測試、Web release build、GitHub Actions、實際預覽與 PR 說明為準。

### PR

- PR #215

---

## LM-044：v0.5.15 生活項目清單與完整 Item 詳情接 Drift

日期：2026-07-19
類型：生活項目／資料投影／UI／測試／文件

### 問題與原因

正式生活項目入口雖已使用 Drift Item 讀取，但主要詳情仍以大型 Bottom Sheet 顯示舊式基本欄位、排程與 MaintenanceRecord，無法呈現 Item 作為 Root 的完整管理結構。

### 修改

- 生活項目清單繼續只由正式 ItemReadRepository 讀取，讀取失敗時不偽裝成空資料。
- 點選生活項目後推入完整 Item 詳情頁，不再以主要 Bottom Sheet 承接長期管理內容。
- 詳情頁由既有 Composition Scope 取得 MaintenancePlan、GeneralReminder、Schedule、Milestone、WorkCase Runtime、History Projection 與 Attachment Runtime 的正式資料。
- 以獨立區塊呈現主資訊、保養項目、一般提醒、提醒與排程、階段性重點／大修、進行中案件、已結案件、史略與附件。
- History 保持唯讀投影；附件只顯示檔名、MIME、大小與生命週期狀態，不顯示 managed identifier 或平台路徑。
- 新增 in-memory Drift Widget tests，驗證完整 route、所有正式資料區塊、無主要 Bottom Sheet、無假資料及讀取前後來源筆數不變。
- 版本更新為 v0.5.15。

### 明確未修改

不修改 Schema、Migration、Database、AppCompositionRoot、Runtime、Repository／Service contract、正式資料寫入、其他主畫面或導覽，不新增功能、資料表、API、平行 History／Attachment 或下一個 PR。

### 資料影響

沒有資料格式、既有資料內容或正式寫入行為變更。畫面只組合既有 Drift 正式資料；舊 ItemDetailSheet 程式仍保留，不刪除 Legacy 程式或資料。

### 驗收結果

以 PR #216 的 Drift Widget tests、Analyze、全部測試、Web release build、GitHub Actions、實際預覽與 PR 說明為準。

### PR

- PR #216

---

## LM-045：v0.5.16 正式規劃資料新增與編輯 UI

日期：2026-07-19
類型：生活項目／規劃資料／UI／測試／文件

### 問題與原因

Item 詳情已能完整讀取 Drift 正式資料，但正式「新增」入口仍停留在舊預覽或唯讀提示，使用者無法建立或調整 Item、Category、MaintenancePlan／Step、GeneralReminder、Milestone 與 Schedule／AnchorPolicy。

### 修改

- 正式「新增」入口改為生活項目、分類、保養項目與步驟、一般提醒、階段性重點與提醒排程六類白話管理入口。
- 建立列表、正式新增與編輯表單，並從 Item 詳情提供主資訊與四個規劃區塊的管理入口。
- 新增 presentation-facing editor，畫面不接觸 Drift row 或 SQL，寫入仍由 AppCompositionRoot 既有 Schema v2 Repository 完成。
- Schedule 建立時只允許一個同 Item 正式來源；來源建立後不可更換，AnchorPolicy 明確區分固定日曆週期、完成後重算與自行指定日期。
- 已封存／已結束資料與 unknown 舊 Schedule 來源維持唯讀，UI 不提供物理刪除。
- 新增 in-memory Drift round-trip 與 Widget tests，驗證正式入口、白話文案與 Category 寫入。
- 版本更新為 v0.5.16。

### 明確未修改

不修改 Schema、Migration、AppCompositionRoot／Runtime contract、SharedPreferences／Legacy recovery、Task、WorkCase、WorkCaseClosure、MaintenanceRecord、History、Attachment、主導覽、資料表或其他功能；不開始下一個 PR。

### 資料影響

沒有資料格式、遷移或既有資料刪除。所有新增／編輯只經既有 Drift Repository 與正式約束；SharedPreferences 與 `backup_v1_*` 不讀寫。

### 驗收結果

以 PR #217 的 Drift round-trip／Widget tests、codegen、Analyze、全部測試、Web release build、實際手機尺寸預覽、GitHub Actions 與 PR 說明為準。

### PR

- PR #217

---

## LM-046：v0.5.17 正式 Task 提醒與開始處理流程

日期：2026-07-19
類型：Task／WorkCase／UI／資料安全／測試／文件

### 問題與原因

Task 已正式切換至 Drift，但畫面仍使用舊保養卡預覽，無法查看正式來源、安排單次提醒或把已開始處理的事情接成 WorkCase；暫停中的提醒也缺少可恢復入口。

### 修改

- 建立正式 Task 詳情與全部提醒入口，顯示 Item、提醒日期、狀態、正式來源、Schedule 週期與 AnchorPolicy。
- 新增單次重排、暫停與恢復操作；沿用既有 `postponed` 狀態，不改 Schema 或 Schedule 規則。
- 重排維持 `scheduleId + dueDate` 唯一約束，衝突時整筆 transaction rollback。
- Task 產生器辨識已移到未來的未終止實例，避免冷啟動重新建立原到期日提醒。
- 「開始處理」只透過既有 `WorkCaseRuntime.createFromTask` 建立進行中 WorkCase，並保留原 Task 不變。
- 新增 Repository 與 Widget 防回歸測試，確認不建立 WorkCaseClosure、MaintenanceRecord 或 History 寫入。
- 版本更新為 v0.5.17。

### 明確未修改

不修改 Schema、Migration、Schedule／AnchorPolicy 正式規則、WorkCaseUpdate／WorkCaseClosure、MaintenanceRecord、History、Attachment、SharedPreferences／Legacy recovery、主導覽、其他 UI 或領域；不開始下一個 PR。

### 資料影響

沒有資料格式、Migration、刪除或 Legacy 寫入。Task 的可變狀態與日期只透過 Drift transaction 更新；開始案件時 Task row 完全保持不變。

### 驗收結果

以 PR #218 的 Task Runtime／Widget tests、codegen、Analyze、全部測試、Web release build、實際手機尺寸預覽、GitHub Actions 與 PR 說明為準。

### PR

- PR #218

## LM-047：v0.5.18 正式 WorkCase UI

日期：2026-07-19
狀態：已核准施工，待 PR #219 驗收

### 變更內容

- 建立正式案件清單與完整 WorkCase 詳情頁。
- 以多筆 WorkCaseUpdate 組成不可覆寫的案件時間軸。
- 呈現處理日期、廠商／聯絡人、結果、費用、零件／品項、等待原因、下一步與備註。
- 新增進度時沿用正式 Runtime 的 Update／狀態單一 transaction。
- 取消與結案入口沿用唯一 WorkCaseClosure 與終止狀態單一 transaction。
- 呈現屬於 WorkCaseUpdate／WorkCaseClosure 的正式受管附件；不顯示 storage identifier，不接受平台路徑。
- 首頁生活總覽與 Item 詳情的案件卡片接至同一正式案件詳情。
- 終止案件只讀，不再允許新增進度、取消或重複結案。
- 版本更新為 v0.5.18。

### 不包含

- Schema、Migration 或 Domain 變更
- 新增附件檔案匯入服務
- UI 全面重畫或新領域功能
- History 獨立寫入或任何平行案件流程

### 驗收依據

以 PR #219 的 WorkCase Widget tests、既有 Runtime transaction tests、codegen、Analyze、全部測試、Web release build、實際手機尺寸預覽、GitHub Actions 與 PR 說明為準。

### 追蹤

- PR #219

## LM-048：v0.5.19 WorkCaseClosure 原子結案 UI

日期：2026-07-19
狀態：已核准施工，待 PR #220 驗收

### 變更內容

- 強化正式結案表單，保存完成日期、完成結果、結案摘要、總費用與後續注意事項。
- 可選建立一則同 Item 的單次後續提醒。
- 可選關聯同 Item 的既有正式 Schedule；不複製、不改寫週期與 AnchorPolicy。
- 後續提醒建立、排程關聯驗證、WorkCaseClosure 與案件 completed 狀態以單一 Drift transaction 完成。
- 任一提醒、排程或 Closure 驗證與寫入失敗時，所有本次寫入完整 rollback。
- 結案後只由既有 History Projection 查詢，不新增 History writer 或資料表。
- 版本更新為 v0.5.19。

### 不包含

- Schema、Migration 或 Domain model 變更
- 新的 Schedule 來源、週期規則或 AnchorPolicy
- Task 直接結案、History 寫入或平行完成流程
- 其他 UI 重畫、新功能或無關重構

### 驗收依據

以 PR #220 的 transaction commit／rollback tests、WorkCaseClosure Widget tests、History Projection 驗證、codegen、Analyze、全部測試、Web release build、手機尺寸預覽、GitHub Actions 與 PR 說明為準。

### 追蹤

- PR #220

---

## LM-049：v0.5.20 Architecture Audit

日期：2026-07-19
狀態：已核准施工，待 PR #221 驗收

### 變更內容

- 稽核 Domain、Repository、Runtime、AppCompositionRoot 與控制文件一致性。
- 確認 Drift 是唯一正式資料來源，正常啟動不讀 Legacy business source 或 fallback。
- 確認 Task、WorkCase、WorkCaseClosure 與 History 正式角色未混淆，沒有平行 History writer。
- 以 allowlist Gate 鎖定 SharedPreferences／LocalStorageService 只能存在於核准的唯讀 recovery 工具。
- 修正早期架構與資料庫決策文件的現況標示衝突，不重寫歷史決策。
- 版本更新為 v0.5.20。

### 明確未修改

不修改 production Runtime、UI、Schema、Migration、匯入 mapping、Domain model 或正式資料；不新增功能、不刪除 Legacy recovery 工具、不開始下一個 PR。

### 資料影響與回復

沒有資料讀寫、搬移或格式變更，不需要資料 rollback。程式回復只需還原本 PR 的文件、Gate 與版本變更。

### 驗收依據

以 PR #221 的 Architecture／Legacy retirement Gate、codegen 無差異、Analyze、全部測試、Web release build 與 GitHub Actions 為準。

### 追蹤

- PR #221

---

## LM-050：v0.5.21 Code Quality Audit

日期：2026-07-19
狀態：已核准施工，待 PR #222 驗收

### 變更內容

- 掃描 TODO、FIXME、HACK、DEBUG、dead／duplicate code、unused import／dependency 與 lint。
- 移除 v0.5.12 後已退休且零引用的 Drift safe-read-only transition adapter。
- 將測試直接使用的 `shared_preferences_platform_interface` 列為 dev dependency，移除 transitive dependency lint suppression。
- 新增 production 品質標記與退休 adapter 防回歸 Gate。
- 版本更新為 v0.5.21。

### 明確未修改

不修改 UI、Schema、Migration、Domain、production Runtime 行為或正式資料；不新增功能、不刪除 Legacy recovery 工具、不做無證據重構、不開始下一個 PR。

### 資料影響與回復

沒有資料讀寫、搬移或格式變更，不需要資料 rollback。程式回復只需還原本 PR 的 dead adapter、dependency、Gate、文件與版本變更。

### 驗收依據

以 PR #222 的 Code Quality／Architecture Gates、codegen 無差異、Analyze、全部測試、Web release build 與 GitHub Actions 為準。

### 追蹤

- PR #222

---

## LM-051：v0.5.22 UI Audit

日期：2026-07-19
狀態：已核准施工，待 PR #223 驗收

### 變更內容

- 逐頁稽核 overflow、SafeArea、Loading／Empty／Error、字級、間距、圖示與深色系統環境。
- App Runtime 初始化失敗時顯示不洩漏技術資訊的 Error／Retry，不再永久停在 Loading。
- 生活總覽與史略新增真實 Loading 與 Error／Retry，載入完成前不再誤顯示空資料。
- 新增 320×568、1.3 放大字體、系統深色環境、五個主分頁與錯誤重試 Widget Gate。
- 完成 390×844 與 320×568 實際 Web 手機預覽。
- 版本更新為 v0.5.22。

### 明確未修改

不新增功能、不重畫 UI，不修改 Schema、Migration、Domain、Repository、資料或正式生命週期；不展開完整 dark palette 改版、不做無關重構、不開始下一個 PR。

### 資料影響與回復

沒有資料讀寫、搬移或格式變更，不需要資料 rollback。回復只需還原 UI state、tests、文件與版本變更。

### 驗收依據

以 PR #223 的手機／大字／狀態 Widget tests、codegen 無差異、Analyze、全部測試、Web release build、手機預覽與 GitHub Actions 為準。

### 追蹤

- PR #223

---

## LM-052：v0.5.23 Product Constitution Audit

日期：2026-07-20
狀態：已核准施工，待 PR #224 驗收

### 變更內容

- 逐頁稽核正式 Runtime 文案、流程與狀態是否持續承接生活事項，而非催促、評分、KPI、打卡、焦慮化或 To-do 化。
- 將首頁 Task 的「待處理／已逾期」改為中性的「已安排／日期已過」。
- 將首頁與 Item 詳情的 Milestone「目標／達標」顯示改為預定日期、條件與條件是否到達。
- 移除共用 Task 卡可直接顯示完成按鈕的殘留 API；Task 仍只作提醒。
- 新增正式 UI 壓力文案及 Task 直接完成防回歸 Gate。
- 記錄 PR #230 必須部署最新版正式 Flutter Web；GitHub Pages 若仍顯示舊樣板或假資料即不得完成。
- 版本更新為 v0.5.23。

### 明確未修改

不修改 Schema、Migration、Domain、Repository、正式資料或生命週期；不新增功能、不重畫 UI、不執行 GitHub Pages 部署、不做無關重構、不開始下一個 PR。

### 資料影響與回復

沒有資料讀寫、搬移或格式變更，不需要資料 rollback。回復只需還原顯示文案、Task 卡 API、Gate、文件與版本變更。

### 驗收依據

以 PR #224 的 Product Constitution Gate、既有正式流程測試、codegen 無差異、Analyze、全部測試、Web release build、手機預覽與 GitHub Actions 為準。

### 追蹤

- PR #224

---

## LM-053：v0.5.24 Data Integrity Audit

日期：2026-07-20
狀態：已核准施工，待 PR #225 驗收

### 變更內容

- 稽核 transaction／rollback、FK／UNIQUE、匯入、備份、回復與 crash recovery。
- 修正 SharedPreferences 平台拒絕不可變備份寫入時仍被誤判成功的阻擋性問題。
- 新增 FK／UNIQUE metadata、`foreign_key_check`、`integrity_check` 與檔案資料庫重啟防回歸 Gate。
- 版本更新為 v0.5.24。

### 明確未修改

不修改 UI、Schema、Migration、Domain 或正式生命週期；不新增功能、不搬移或刪除資料、不做無關重構、不開始下一個 PR。

### 資料影響與回復

沒有 Schema 或資料格式變更。備份寫入遭拒時現在會明確失敗，既有完整性 Gate 因而阻擋匯入；來源與 `backup_v1_*` 仍不刪除、不覆寫。程式回復只需還原 service、tests、文件與版本。

### 驗收依據

以 PR #225 的備份拒絕、transaction rollback、檔案 DB 重啟、FK／UNIQUE、`foreign_key_check`、`integrity_check` Gate、codegen 無差異、Analyze、全部測試、Web release build 與 GitHub Actions 為準。

### 追蹤

- PR #225

---

## LM-054：v0.5.25 Performance Audit

日期：2026-07-20
狀態：已核准施工，待 PR #226 驗收

### 變更內容

- 以 80 個 Item、400 個 Task、400 筆 History 記錄與 800 筆 Attachment metadata 稽核正式 Drift Runtime。
- 驗證首頁與史略在手機尺寸下的大量資料載入、連續捲動、時間與記憶體界線。
- 以 `EXPLAIN QUERY PLAN` 鎖定 Task、MaintenanceRecord、Attachment 與 WorkCase 正式索引。
- 新增可由 CI 重跑的效能防回歸 Gate；未發現需要修改 production code 的阻擋性瓶頸。
- 版本更新為 v0.5.25。

### 明確未修改

不修改 UI、Schema、Migration、Domain、Runtime 或正式生命週期；不新增功能、cache、API、資料表或平行流程，不做無關重構、不開始下一個 PR。

### 資料影響與回復

沒有正式資料讀寫、Schema 或資料格式變更。壓力資料只存在於測試的記憶體資料庫，測試結束即關閉。程式回復只需還原 tests、文件與版本。

### 驗收依據

以 PR #226 的大量資料 query-plan、查詢時間、首頁／史略載入與捲動、RSS 記憶體 Gate、codegen 無差異、Analyze、全部測試、Web release build 與 GitHub Actions 為準。

### 追蹤

- PR #226

---

## LM-055：v0.5.26 Security Audit

日期：2026-07-20
狀態：已核准施工，待 PR #227 驗收

### 變更內容

- 稽核 SQLite、Attachment、備份／還原／匯入、檔案路徑、平台與 workflow 權限、敏感資訊及 crash recovery。
- 阻擋 Attachment traversal、反斜線、URI、encoded separator、query／fragment 與控制字元，Runtime 及 Repository bypass 均套用相同限制。
- 為 sqlite3 3.4.0 Web WASM 資產鎖定 SHA-256，下載內容驗證通過前不得寫入 build source。
- 將 GitHub Pages write／OIDC 權限限縮至 deploy job，build job 只保留 contents／Pages read。
- 新增 SQLite 參數綁定、secret pattern、平台正式權限與供應鏈資產防回歸 Gate。
- 版本更新為 v0.5.26。

### 明確未修改

不修改 UI、Schema、Migration、Domain 或正式生命週期；不新增功能、資料表、API、檔案 ingestion、加密層或平行流程，不做無關重構、不開始下一個 PR。

### 資料影響與回復

沒有 Schema、Migration 或既有資料變更。既有 Attachment metadata 不改寫；新正式 Attachment identifier 只會更嚴格拒絕可能越界或被解析為 URI 的值。回復只需還原安全驗證、tests、workflow 權限、文件與版本，不需資料 rollback。

### 驗收依據

以 PR #227 的 hostile identifier、Repository bypass、SQLite parameter binding、WASM SHA-256、workflow／平台權限、secret scan、既有 import／backup／rollback／crash recovery Gate、codegen 無差異、Analyze、全部測試、Web release build 與 GitHub Actions 為準。

### 追蹤

- PR #227

---

## LM-056：v0.5.27 Cross Platform Audit

日期：2026-07-20
狀態：已核准施工，待 PR #228 驗收

### 變更內容

- 稽核 iPhone、iPad、Android、Web，以及 Safari、Chrome、Edge、Firefox 的啟動、版面、輸入、導覽、Drift 與完整正式主流程。
- 完成 iPhone 16 Pro 與 iPad Pro Simulator 實際安裝／啟動，保留 iPhone／iPad universal target 與正式 Drift sandbox。
- 接受 Flutter stable 必要的 iOS UIScene／Swift Package Manager 專案更新、CocoaPods lockfile，以及 Android Gradle compatibility flags。
- 修正 Web 缺少 viewport meta，避免行動 Safari／Chrome 使用寬版 layout viewport 後縮放。
- 新增 phone／tablet／desktop 尺寸、鍵盤、Unicode 輸入、正式導覽與平台設定防回歸 Gate。
- CI 新增 Android release APK 與 iPhone／iPad Simulator build Gate。
- 版本更新為 v0.5.27。

### 明確未修改

不修改 Schema、Migration、Domain、Repository contract 或正式生命週期；不新增產品功能、不重畫 UI、不建立平行流程、不做無關重構、不開始下一個 PR。

### 資料與回復

沒有資料格式、Schema 或既有資料變更。Drift native 與 Web 正式角色不變。回復只需還原平台專案相容更新、viewport、tests、workflow、文件與版本，不需要資料 rollback。

### 驗收依據

以 iPhone／iPad Simulator 實際啟動、Android release APK、iOS Simulator universal build、Chrome release build 輸入／導覽／Drift refresh persistence、Mobile Safari render、跨尺寸／鍵盤測試、codegen、Analyze、全部 tests、Web release build 與 GitHub Actions 為準。

### 追蹤

- PR #228

---

## LM-057：v0.5.28 Real User Validation

日期：2026-07-20
狀態：已核准施工，待 PR #229 驗收

### 變更內容

- 以正式 Drift Runtime 驗證 Item → MaintenancePlan → Task → WorkCase → 多筆 WorkCaseUpdate → 唯一 WorkCaseClosure → History Projection 完整生命週期。
- 以檔案資料庫跨三個使用日反覆關閉、重啟，確認案件進度、提醒角色、結案與史略不因冷啟動遺失或混用。
- 關閉資料庫後執行備份與還原，驗證 Item、Plan、Update、Closure、History、foreign key 與 SQLite integrity 均保持完整。
- 修正正式「史略」頁仍只讀 MaintenanceRecord、導致正式案件結案不可見的阻擋問題；改為既有唯讀 History Projection，未建立新寫入或平行真相。
- 新增手機尺寸史略 → 案件詳情時間軸操作防回歸測試。
- 版本更新為 v0.5.28。

### 明確未修改

不新增功能、不重畫 UI，不修改 Schema、Migration、Domain、Repository contract 或正式生命週期；不搬移、刪除或覆蓋既有資料，不做無關重構、不開始下一個 PR。

### 資料與回復

沒有 Schema、Migration 或既有資料格式變更。History 仍為由正式資料組合的唯讀投影；程式回復只需還原史略讀取接線、tests、文件與版本，不需要資料 rollback。

### 驗收依據

以跨日冷啟動、備份／還原、Task 不變性、唯一 Closure、History Projection、SQLite `foreign_key_check`／`integrity_check`、手機操作 Gate、codegen、Analyze、全部 tests、Web／Android／iOS build 與 GitHub Actions 為準。

### 追蹤

- PR #229

---

## LM-058：v0.5.29 Release Candidate Preparation

日期：2026-07-20
狀態：已核准施工，待 PR #230 與正式 Pages 驗收

### 變更內容

- 整合 PR #221～#229 的架構、品質、UI、產品憲法、資料完整性、效能、安全、跨平台與真實使用驗證結果，建立單一 RC Gate。
- 修正 Pages workflow 仍以 `lib/prototype_main.dart` 建置 review-only 樣板的阻擋問題；改為 Flutter 預設正式 `lib/main.dart`，產物仍固定上傳 `build/web`。
- Pages artifact Gate 明確拒絕「生活管理樣板審查／首頁樣板」內容，並新增 workflow 防回歸測試。
- 更新 README、版本、Release Notes 與 RC 控制文件；版本更新為 v0.5.29。

### 明確未修改

不新增產品功能、不重畫 UI，不修改 Schema、Migration、Domain、Repository contract、正式 Runtime 資料行為或生命週期；不開始下一個 PR。

### 資料與回復

沒有資料格式或使用者資料變更，不需要 Migration 或資料 rollback。回復只需還原 Pages workflow、Gate、文件與版本；Drift 正式資料不得刪除或改回 Legacy writer。

### 驗收依據

PR CI 先通過 codegen、Analyze、全部 tests、Web／Android／iOS build；squash merge 後，`main` Pages deploy 必須成功且部署 commit 可追溯至 PR #230。正式網址需於 Chrome、Safari 與隔離／無痕瀏覽情境呈現五入口正式 Runtime，沒有舊 prototype、假資料或 console error，才可宣告 PR #230 完成。

### 追蹤

- PR #230

---

## LM-059：v0.5.30 Device Validation Baseline

日期：2026-07-20
狀態：已核准施工，待 PR #231 驗收

### 變更內容

- 建立安裝、原地升級、冷啟動、背景切換、強制關閉重啟、資料持久化與版本相容的正式真機 Checklist。
- 鎖定相同 application／bundle identifier 原地升級、禁止卸載或清資料後冒充升級成功。
- 新增檔案 Drift 資料庫在同一 Runtime 與完整 Composition Root 重啟後的持久化、foreign key 與 integrity 防回歸 Gate；背景／前景保留為真機 Checklist，不以 Widget runner 冒充 OS lifecycle。
- 明確區分實體裝置、simulator、平台 build 與 CI 證據；未執行的實體裝置項目維持未簽核。
- 版本更新為 v0.5.30。

### 明確未修改

不新增功能、不修改 UI 設計、Schema、Migration、Domain、Repository contract 或正式生命週期；不搬移、刪除或覆蓋既有資料，不做無關重構、不開始下一個 PR。

### 資料與回復

沒有 Schema、Migration 或正式使用者資料變更，不需要資料 rollback。回復只需還原 Checklist、tests、版本與發行文件；不得刪除 Drift 資料或恢復 Legacy writer。

### 驗收依據

以 Device Validation Baseline、自動持久化／平台識別 Gate、codegen 無差異、Analyze、全部 tests、Web／Android／iOS build 與 GitHub Actions 為準。PR #231 施工時 iOS 實體裝置為 Offline，Android ADB／實體裝置不可用，因此不宣稱真機已通過。

### 追蹤

- PR #231

---

## LM-060：v0.5.31 Web Long-term Validation

日期：2026-07-21
狀態：已核准施工，待 PR #232 驗收

### 變更內容

- 建立重新整理、關閉分頁重開、瀏覽器重啟、背景恢復、Drift 持久化與 GitHub Pages 正式部署 Checklist。
- 驗證相同 release build 在全新 Web origin 建立正式 Category／Item 後，重新整理與關閉分頁重開仍可讀回同一筆 Drift 資料。
- 修正 Pages 長期部署的阻擋性快取風險：build 停用已棄用的 Flutter Service Worker，避免 `main.dart.js`、Drift worker 與 SQLite WASM 混用不同部署世代。
- 新增 database identity、相對資產 URL、Pages PWA strategy 與 artifact 的防回歸 Gate。
- 版本更新為 v0.5.31。

### 明確未修改

不新增功能、不修改 UI、Schema、Migration、Domain、Repository contract 或正式生命週期；不搬移、刪除或覆蓋資料，不做無關重構、不開始下一個 PR。iPhone／Android 實體裝置延後驗收。

### 資料與回復

沒有 Schema、Migration 或正式使用者資料變更，不需要資料 rollback。回復只可還原 workflow、Gate、控制文件與版本；不得刪除 Drift 資料、改名資料庫、清除網站資料或恢復 Legacy writer。

### 驗收依據

以 Web Long-term Validation Checklist、codegen 無差異、Analyze、全部 tests、Web build、GitHub Actions 與最新版 `main` Pages deploy 為準。瀏覽器程序重啟、背景／休眠與既有資料持久化必須人工驗證，不得由 unit test、artifact build 或無痕新來源冒充。

### 追蹤

- PR #232

---

## 後續條目模板

```text
## LM-XXX：標題

日期：
類型：文案／UI／資料／架構／安全／CI／文件

### 問題

### 修改

### 明確未修改

### 資料影響

### 驗收

### 批准

### PR／commit
```
