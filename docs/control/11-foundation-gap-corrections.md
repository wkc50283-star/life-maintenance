# 生活管理 App 基礎架構缺口修正計畫

狀態：正式控制文件候選  
版本：v0.5.0  
日期：2026-07-18

## 1. 目的

本文件記錄從產品起點、核心角色、週期、案件、史略、資料庫、遷移與 UI／UX 重新稽核後，發現尚未被正式模型或 schema 承接的缺口。

在本文件列出的阻擋項目完成前：

- PR #185 不得合併。
- schema v2 不得開始正式施工。
- 不得把現有舊 enum、Schedule 或 MaintenanceRecord 直接視為最終產品模型。
- 不得因資料庫工程進度而省略階段性重點、大修、生活類別、結案與視覺資訊架構。

## 2. 稽核總結

主方向正確：

- 專案已恢復為生活管理 App，不是 PMS。
- Item、MaintenancePlan、Schedule、Task、WorkCase、WorkCaseUpdate 與史略已初步分離。
- 舊資料備份、寫入鎖、只讀盤點、關聯稽核與遷移准入方向正確。
- 年／半年／季／月／週／日與「日歸日、週歸週」原則已進入產品文件。
- 突發事項／工程、保養修理卡、多筆處理進度與結案進史略已進入產品文件。

仍有重大缺口：

1. 階段性重點／大修只有規格文字，沒有正式模型與資料表位置。
2. 固定週期基準仍以舊 `strictPeriodMode` 布林值表達，且舊模型預設為 false，與產品最高原則衝突。
3. Item 類別仍只涵蓋家電、車輛、房屋、保固證件與其他，不能承接完整生活類。
4. WorkCase 結案資料不足，無法正式保存總費用、完修摘要、後續注意與下一次安排。
5. Schedule／Task 來源與跨表一致性約束尚未完整。
6. 附件／照片只有識別碼，尚無正式生命週期設計。
7. 「限－工程」與「突發事項／工程」的正式名詞關係尚未定案。
8. 變更紀錄與控制文件清單落後實際 PR。
9. 工程進度過度偏向資料庫，首頁與生活項目詳情的資訊架構及視覺樣板尚未驗收。

## 3. 阻擋項目 A：階段性重點與大修

### 3.1 正式角色

需建立 `Milestone`（正式技術名稱可在模型 PR 定案），代表固定週期之外、達到條件後浮現的一次性重大處理重點。

至少支援：

- 使用年限
- 里程
- 使用量或指定數值
- 完成次數
- 指定日期
- 另一件事完成
- 人生或照護階段
- 異常次數
- 使用者手動啟動

### 3.2 建議欄位

- `schemaVersion`
- `id`
- `itemId`
- `maintenancePlanId`（可空）
- `title`
- `description`
- `triggerType`
- `thresholdValue`（可空）
- `thresholdUnit`（可空）
- `triggerDate`（可空）
- `dependencyId`（可空）
- `status`
- `reachedAt`（可空）
- `acknowledgedAt`（可空）
- `createdAt`
- `updatedAt`
- `archivedAt`（可空）

### 3.3 流程

```text
條件達成
→ 顯示階段性重點
→ 使用者決定是否開始
→ 建立 Task 或直接建立 WorkCase
→ 多筆處理進度
→ 結案進史略
```

不得在條件達成時直接建立完成紀錄。

## 4. 阻擋項目 B：固定週期基準

產品正式原則是：

> 日歸日、週歸週、月歸月、季歸季、半年歸半年、年歸年。

正式模型不得只沿用 `strictPeriodMode`，也不得預設完成後漂移。

需建立明確策略，例如：

- `fixedCalendarPeriod`：依原到期基準推進，正式預設。
- `completionBased`：使用者明確選擇後，依實際完成時間重新計算。
- `userDefined`：使用者自行指定下一次日期。

必須測試：

- 日、週、月、季、半年、年各自推進。
- 延遲完成不改變週期層級。
- 月底、閏年、跨年。
- 同一期不得重複產生 Task。
- 只有使用者明確選擇時才可改為 completion-based。

## 5. 阻擋項目 C：生活項目類別

現有 `ItemCategory` 不足以承接完整生活管理。

正式策略需二選一並經批准：

### 方案 A：擴充系統 enum

至少包含：

- 居家與家電
- 車輛與交通
- 房屋與修繕
- 文件、證件與合約
- 健康與照護
- 家庭
- 寵物
- 財務
- 學習
- 工作
- 其他

### 方案 B：系統類別＋使用者自訂類別

至少具備：

- `categoryId`
- `systemCategoryCode`（可空）
- `customCategoryName`（可空）

在類別策略定案前，不得直接以舊 enum 建立最終 `items` table。

## 6. 阻擋項目 D：案件正式結案

現有 WorkCase 只保存 `closedAt`、`closeResult` 與 `cancellationReason`，不足以符合產品規格。

需擴充 WorkCase 或新增 `WorkCaseClosure`，至少保存：

- 完成日期
- 最終結果
- 完修／結案摘要
- 總費用
- 後續注意事項
- 是否建立下一次 Schedule
- 下一次 Schedule ID（可空）
- 是否建立下一次提醒
- 下一次 Task ID（可空）
- 建立時間

總費用不能只靠 UI 臨時計算而沒有正式結案確認。

取消案件仍保存取消原因，不得直接刪除。

## 7. 阻擋項目 E：Schedule 與 Task 來源一致性

### 7.1 Schedule 來源

需正式決定：

- `maintenancePlan`
- `generalReminder`
- `milestone`

到期事項 `expiry` 必須明確定義為 generalReminder subtype，或保留獨立 source type，不得模糊處理。

### 7.2 Task 來源

建議建立：

- `scheduledMaintenance`
- `scheduledReminder`
- `milestone`
- `manual`

Repository 或 transaction 必須驗證：

```text
Task.itemId
= Schedule.itemId（有 Schedule 時）
= MaintenancePlan.itemId（有 MaintenancePlan 時）
= Milestone.itemId（有 Milestone 時）
```

不能只確認每個 foreign key 各自存在，卻允許它們指向不同 Item。

## 8. 已知後續缺口：附件與照片

第一階段可繼續保存穩定 `photoIdentifiers`，但必須正式記錄附件子系統尚未完成。

未來至少需要：

- `Attachment` 或 `PhotoAsset`
- owner type／owner ID
- mime type
- 檔案大小
- App 管理路徑或 Web 儲存識別
- 建立、遺失、刪除時間
- 孤兒檔案清理
- 備份與匯出
- iOS／Web 差異

此缺口可排在 schema v3，但不得把 JSON identifiers 宣稱為最終完整方案。

## 9. 名詞待定：「限－工程」

使用者原始「限－工程」概念已被產品文件吸收為：

- 突發事項
- 突發重點
- 修繕／整修／工程
- 臨時重要辦理事項

需在 UI 資訊架構 PR 正式決定：

- 正式入口是否統一叫「突發事項／工程」。
- 是否拆成「突發事項」與「工程」。
- 「突發重點」是否屬於手動 Milestone。

在定案前，底層可統一使用 WorkCase，但 UI 不得自行發明新名稱。

## 10. 治理修正

### 10.1 變更紀錄

需補記 PR #177～#184 的正式 LM 條目與 squash commit，包括：

- WorkCase Repository 邊界
- 遷移準備盤點
- 舊資料關聯稽核
- 遷移准入閘門
- 舊資料遷移範圍
- v0.5.0 三碼版本
- MaintenancePlan 核心角色
- MaintenancePlan 模型基線

### 10.2 控制文件狀態

- `09-core-data-roles.md` 已合併，狀態應改為「正式控制文件」。
- 不再以固定「六份控制文件」描述現況。
- `docs/control/` 內標示為正式控制文件者，依 README 順序共同生效。
- PR #185 的 schema v2 文件在缺口修正前只能維持草稿／候選，不得升格。

## 11. UI／UX 前置驗收

在 schema v2 正式施工前，插入一個不接真實資料的資訊架構與視覺樣板批次，只做：

1. 首頁樣板。
2. 生活項目詳情樣板。

必須呈現並驗證：

- 現在需要處理
- 處理中
- 即將到期
- 保養項目
- 階段性重點／大修
- 突發事項／工程入口
- 最近完成與史略入口

目的不是先做假功能，而是先確認資訊層級、入口名稱與視覺方向。樣板不得在正式 App 中呈現為可操作功能；應以設計文件、測試頁或隔離 prototype 驗收。

## 12. 修正施工順序

```text
本修正計畫合併
→ Milestone／大修模型基線
→ Item 類別策略定案
→ ScheduleAnchorPolicy 模型基線
→ WorkCaseClosure 模型基線
→ Schedule／Task 來源一致性定案
→ 修正 PR #185 schema v2 設計
→ 補齊變更紀錄與控制文件狀態
→ 首頁＋生活項目詳情視覺樣板
→ 才批准 schema v2 正式施工
```

## 13. 批准與凍結

### 已批准

- 生活管理 App 主線。
- MaintenancePlan 正式角色與模型。
- WorkCase／WorkCaseUpdate 案件方向。
- Drift + SQLite 技術方向。
- 舊資料只讀稽核與准入。

### 暫停批准

- PR #185 合併。
- schema v2 正式程式施工。
- 以舊 ItemCategory 建立最終 items table。
- 以 `strictPeriodMode = false` 作為正式排程預設。
- 在沒有 Milestone 模型時宣稱已承接大修與階段性重點。

### 不得執行

- 匯入 SharedPreferences。
- 切換現有 Repository。
- 讓 UI 使用未驗證的新核心資料表。
- 把 MaintenanceRecord 轉成 WorkCase。
- 因趕進度省略手機視覺驗收。
