# Performance Audit（PR #226）

狀態：正式控制文件
版本：v0.5.25
日期：2026-07-20

## 1. 範圍與結論

本次只量測既有正式 Runtime 在大量 Item、Task、History 與 Attachment metadata 下的查詢、首頁載入、捲動、時間與記憶體，不修改 UI、Schema、Migration、Domain 或產品功能。

測試資料包含 80 個 Item、400 個當日 Task、400 筆 MaintenanceRecord History fact 與 800 筆 Attachment metadata。這高於一般單一家庭同時管理的活躍資料量，可作為 v0.5.x Foundation 的防回歸壓力基準。

所有基準均通過，且關鍵查詢命中既有 Schema v2 index；沒有發現足以授權 production code 變更的阻擋性瓶頸，因此本 PR 不修改 Runtime 或 UI。

## 2. 正式基準

| 範圍 | 資料量／操作 | Gate | 結果 |
|---|---|---|---|
| Item／Task 查詢 | 80 Item、400 Task | 與單一 Item History／Attachment 合計低於 3 秒 | 通過 |
| History Projection | 單一 Item 5 筆完成事實、10 筆附件；全庫 400／800 | 包含資料完整性驗證並低於查詢 Gate | 通過 |
| 首頁 | 80 Item、400 個今日提醒及全庫 History 掃描 | 430×900 載入低於 8 秒，可連續捲動 | 通過 |
| 記憶體 | 同一首頁壓力資料 | 額外 RSS 低於 384 MiB | 通過 |
| 史略 | 400 筆正式 MaintenanceRecord | 430×900 載入低於 8 秒，可連續捲動 | 通過 |
| Attachment | 800 筆 metadata、Owner 查詢 | 命中 owner index，Owner 結果正確 | 通過 |

時間門檻刻意保留 CI runner 差異，不作微型效能競賽；其目的在阻擋演算法退化、全表掃描、無限等待、過量記憶體成長與無法捲動等產品級回歸。

## 3. Query-plan Gate

以下正式查詢必須持續使用既有 Schema v2 index：

- Task 的 Item／status 查詢：`tasks_item_status_idx`
- MaintenanceRecord 的 Item／date 查詢：`maintenance_records_item_date_idx`
- Attachment 的 ownerType／ownerId 查詢：`attachments_owner_status_idx`
- WorkCase 的 Item／status 查詢：`work_cases_item_status_idx`

本 Gate 只驗證既有 index，不新增或修改 Schema。

## 4. 記憶體與捲動邊界

- Attachment 測試只保存正式 metadata，不載入檔案實體或平台路徑。
- 首頁壓力測試量測載入前後 RSS，並在資料完成投影後連續捲動。
- 史略以完整正式記錄建立月份區段並連續捲動，確認沒有 exception、永久 Loading 或無回應。
- 測試資料全部位於 `NativeDatabase.memory()`，不污染或搬移使用者資料。

## 5. 防回歸與回復

任何基準超時、超過記憶體上限、失去指定 index、捲動 exception 或資料筆數不一致，都視為 PR 阻擋。

本 PR 沒有 production、Schema 或資料變更；回復只需移除本次 performance Gate、控制文件與版本更新，不需要 Migration 或資料 rollback。
