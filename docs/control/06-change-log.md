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
