# 生活管理 App 版本管理規則

狀態：正式控制文件
目前產品版本：`v0.5.37`
建置版本：`0.5.37+38`

## 1. 單一版本來源

正式版本唯一來源為 `pubspec.yaml` 的 `version` 欄位。

格式：

```text
主版本.次版本.修訂版本+建置號
```

例如：

```text
0.5.0+1
```

- 對外產品版本：`v0.5.0`
- Flutter／商店建置版本：`0.5.0+1`

不得再於 Widget、README 或設定頁各自手寫不同版本號。未來若 App 畫面需要顯示版本，必須從建置資訊讀取。

## 2. 三碼版本定義

### 第一碼：Major

代表已正式發布後的重大產品或相容性變更。

例：

- `1.x.x`：第一個正式可長期使用版本
- `2.x.x`：產品角色、資料格式或使用流程出現重大且可能不相容的改變

目前尚未正式發布，因此維持 `0.x.x`。

### 第二碼：Minor

代表一個完整產品階段或可辨識能力完成。

目前規劃：

- `0.5.x`：基礎架構與資料安全
- `0.6.x`：完整資料層與安全遷移
- `0.7.x`：案件、進度與史略系統
- `0.8.x`：週期、階段性重點與生活管理整合
- `0.9.x`：正式 UI／UX 與真機體驗
- `1.0.0`：第一個正式穩定版

Minor 版本必須代表一組完整、可驗收的階段，不得只因單一小 PR 任意升版。

### 第三碼：Patch

代表不改變主要產品階段的小幅改進：

- Bug 修正
- 文案修正
- 測試補強
- 小型相容性調整
- 文件與治理補充
- 不改變資料角色的安全重構

例如：

- `0.5.1`
- `0.5.2`

## 3. 建置號

`+1` 是 Flutter 建置號，不是產品功能版本。

規則：

- 同一三碼版本若重新產生可安裝建置，建置號必須增加。
- 三碼版本升級時，建置號可依正式發布流程重新設定或持續遞增，但不得倒退於已發布平台要求。
- Git commit、PR 數量與建置號沒有必然一對一關係。

## 4. 目前版本判定

目前正式定義為：

> **Life Management App v0.5.37 — Accessibility & Beta UI Readiness**

此版本已完成的核心基礎包括：

- 生活管理產品定位與控制文件
- PMS 文件退出正式規格
- 舊 JSON 相容與資料寫入保護
- 不可變原始備份
- Drift + SQLite 正式選型
- WorkCase／WorkCaseUpdate 模型
- Drift Schema v2 與 v1 → v2 migration
- Schema v2 Repository、transaction 與跨 Item 邊界
- 舊資料只讀盤點、關聯稽核與遷移准入閘門
- 正式 Runtime SharedPreferences／LocalRepository 全面稽核
- 禁止雙寫、匯入／切換／rollback 與驗收順序
- SharedPreferences → Drift v2 dry-run、原子匯入、重跑保護與 rollback 測試
- 單一 AppCompositionRoot 與可替換的測試注入
- 啟動受控匯入、rollback、唯讀來源 gate 與 ItemCategory／Item Drift 讀取切換
- MaintenancePlan、GeneralReminder、Milestone 與 Schedule（含 ScheduleAnchorPolicy）Drift Repository 讀寫與 transaction 切換
- Task 依 Schedule／source contract 產生、Drift Runtime 讀寫、transaction 與 `scheduleId + dueDate` 去重
- 正式 Runtime 移除 Task 直接完成成 MaintenanceRecord 的舊流程
- WorkCase 正式 Runtime、Task／手動案件建立、多筆 WorkCaseUpdate 與唯一 WorkCaseClosure
- 案件來源同 Item、Update／狀態原子寫入、結案／終止狀態原子寫入及終止後唯讀
- WorkCase、Update、Closure、MaintenanceRecord、Task、Milestone 與 Attachment 的唯讀 History Projection
- Attachment stable identifier、MIME、Hash、正式 Owner、available／missing／deleted 生命週期 Runtime
- History 唯讀投影、Loading／Empty／Error／Retry、事件排序、正式來源一致性與冷啟動防回歸 Gate
- MaintenanceRecord 正式 Drift Repository、簡單完成 transaction、同 Item／唯一 Task 紀錄與 WorkCaseClosure 邊界
- Legacy Runtime 全量引用稽核、Drift 唯一正式 writer、冷啟動與 rollback 防回歸 Gate
- Items／History 的 MaintenanceRecord Drift read cutover、正式 UI 零 MaintenanceRecordLocalRepository 依賴
- admission／backup／import 失敗時進入 Drift 唯讀安全狀態，不恢復 Legacy writer
- 正式入口與 AppCompositionRoot 零 LocalRepository／SharedPreferences 業務依賴，Drift 為唯一正式資料來源
- Legacy business writer API 退休；`backup_v1_*`、唯讀匯入、稽核與災難回復工具保留
- 正式 App Shell 統一生活總覽、生活項目、新增、史略與設定五個入口
- 全 App 共用單一 App Theme 與 AppCompositionRoot 注入邊界
- 生活總覽以既有 Drift Repository／Runtime／History Projection 組合五個正式真實資料區塊
- 生活項目清單以完整頁面呈現 Item 的保養、提醒、排程、Milestone、案件、史略與附件真實資料
- Task 正式詳情、來源投影、單次重排、暫停／恢復與「開始處理」案件建立流程
- Task 保持提醒角色；開始處理不完成 Task、不建立 WorkCaseClosure、不寫入 History
- 正式 WorkCase 清單與詳情，呈現主資訊、多筆 Update 時間軸、費用、廠商、零件、等待原因、下一步及正式附件
- 新增案件進度沿用 Update／狀態單一 transaction；取消與結案沿用唯一 WorkCaseClosure transaction
- 首頁與 Item 詳情案件入口共用正式 WorkCase Runtime，終止案件後 UI 保持唯讀
- WorkCaseClosure 正式結案表單保存完成日期、結果、摘要、總費用與後續注意事項
- 可選後續提醒與既有正式排程關聯，和 Closure／案件終止在單一 transaction 完成，失敗全 rollback
- Item、Category、MaintenancePlan／Step、GeneralReminder、Milestone 與 Schedule／AnchorPolicy 的正式新增與編輯 UI
- CI 的 Analyze、Test、Web build、Drift code generation 與 Web 資產驗證
- Web 重新整理、關閉分頁重開、瀏覽器重啟、背景恢復、Drift 持久化與 Pages 正式部署 Checklist
- Pages build 停用已棄用的 Flutter Service Worker，避免跨部署混用不同世代執行資產
- 既有 Pages origin 在 Flutter 啟動前解除本 App scope 的舊 Service Worker，沿用同名 Drift database
- 既有 shared IndexedDB 的 Schema v2 index 可安全重開，不因非冪等 `CREATE INDEX` 阻擋 Runtime
- Domain／Repository／Runtime／CompositionRoot 一致性稽核與 Legacy recovery allowlist 防回歸 Gate
- production 品質標記、dead code、dependency 與 lint 稽核及防回歸 Gate
- 全頁 Loading／Empty／Error、SafeArea、overflow、字級、間距、圖示與手機尺寸 UI 稽核
- 正式 Runtime 逐頁產品憲法稽核、中性提醒／Milestone 文案與 Task 禁止直接完成防回歸 Gate
- PR #230 最新正式 Flutter Web GitHub Pages 部署阻擋條件
- transaction／rollback、FK／UNIQUE、匯入、備份、回復與 crash recovery 資料完整性稽核
- 平台拒絕不可變備份寫入時明確失敗，不得誤判備份成功
- 大量 Item／Task／History／Attachment 的索引、查詢、首頁、捲動、記憶體與時間防回歸基準
- SQLite 參數綁定、Attachment identifier、備份／匯入／回復、平台權限、敏感資訊與 Web SQLite 資產安全 Gate
- iPhone／iPad／Android／Web 啟動、尺寸、輸入、導覽、Drift 與平台 build 相容 Gate
- Item → MaintenancePlan → Task → WorkCase → WorkCaseUpdate → WorkCaseClosure → History 的跨日、冷啟動、備份／還原真實生命週期 Gate
- App Shell 史略改由正式 History Projection 組合案件、結案、簡單紀錄、提醒與階段性重點
- #221～#229 稽核結論整合為單一 RC admission Gate
- GitHub Pages 由最新版 `main` 的正式 `lib/main.dart` 建置，不得部署 prototype、樣板或 fixture
- 正式裝置安裝、原地升級、冷啟動、背景／前景、強制關閉重啟、資料持久化與版本相容 Checklist
- 平台 application／bundle identifier、Drift 檔案重啟與 SQLite 完整性防回歸 Gate；simulator 與 build 不得冒充真機簽核

此版本仍不代表使用者功能完成。下列內容尚未完成：

- iOS／Android 實體裝置 Checklist 尚待具備連線、簽章與安裝環境後逐項簽核
- 真實裝置匯入與唯讀來源預覽驗收
- Attachment 檔案內容的正式跨裝置備份／還原
- 正式 UI／UX 改版

## 5. 版本升級批准

- Patch：明確 Bug、安全或文件修正可依既有授權執行，仍須 PR 與 CI。
- Minor：必須完成該階段驗收條件，並由專案負責人批准。
- Major：屬於不可逆或高風險決策，必須由專案負責人逐項批准。

## 6. PR 規則

每個 PR 必須標示它屬於：

- 目前版本內的施工
- Patch 候選
- 下一個 Minor 版本的組成項目

PR 合併不代表自動升版。只有版本條件完整達成並通過驗收後，才修改 `pubspec.yaml`。

## 7. 版本顯示規則

在尚未加入可靠的建置資訊讀取機制前：

- 首頁不顯示版本號
- 設定頁不手寫版本號
- README 可引用正式版本，但必須與 `pubspec.yaml` 一致
- Git tag 與 release 後續建立時，也必須與 `pubspec.yaml` 一致
