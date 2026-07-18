# 生活管理 App 舊資料遷移範圍決策

狀態：正式控制文件

日期：2026-07-18

## 1. 決策摘要

目前不得執行舊 SharedPreferences 資料匯入 Drift。

原因不是舊資料尚未通過稽核，而是 Drift schema v1 只有：

- `work_cases`
- `work_case_updates`

現有 SharedPreferences 則包含：

- `items`
- `schedules`
- `tasks`
- `maintenance_records`

四組舊資料目前都沒有對應的 Drift 目標表，因此不存在合法、可回復、可驗證的正式匯入路徑。

## 2. 不得偽造案件歷史

`MaintenanceRecord` 代表既有完成結果與舊版歷史資料，不代表完整案件過程。

禁止把一筆舊完成紀錄自動轉成：

- 一個已完成 `WorkCase`
- 一筆虛構的 `WorkCaseUpdate`
- 不存在的開始時間、等待狀態、廠商聯絡或處理過程

原因：

- 舊資料沒有保存完整案件生命週期。
- 自動補齊會把推測寫成歷史事實。
- 史略原則要求舊完成紀錄可直接保留顯示，不必偽造案件過程。

## 3. 目前各資料角色的處置

| 舊資料 | 現行角色 | 目前處置 |
|---|---|---|
| Item | 生活項目 | 繼續保留於 SharedPreferences，待 Drift items table 建立 |
| Schedule | 固定週期與提醒規則 | 繼續保留，待正式 schedule kind 與 Drift schedules table 建立 |
| Task | 某次到期或待處理提醒 | 繼續保留，待 Drift tasks table 建立 |
| MaintenanceRecord | 舊完成結果與歷史資料 | 繼續保留，待 Drift maintenance records table 建立；不得硬轉案件 |
| WorkCase | 新的實際處理案件 | 只允許未來由新流程建立 |
| WorkCaseUpdate | 新案件的多筆進度 | 只允許未來由新案件流程新增 |

## 4. 已完成的遷移前保護

目前已完成：

- 原始 JSON 安全預設
- 逐筆解析
- 資料異常寫入鎖
- `backup_v1_*` 不可變原始備份
- 原始資料與備份筆數／一致性盤點
- 重複 ID 與斷裂關聯稽核
- Drift 目標案件表是否為空的檢查
- 單一遷移准入判定

這些工具只證明資料狀態是否可進入下一階段，不代表目前 schema 已具備匯入能力。

## 5. 遷移准入與 schema 准入必須同時成立

舊資料匯入前必須同時通過兩種准入：

### 資料准入

- 來源可讀
- 備份完整且一致
- 沒有無效項目
- 沒有重複 ID
- 沒有斷裂關聯
- 目標表狀態符合預期

### schema 准入

- 每一種來源資料都有明確目標 table
- enum 與特殊字串有正式轉換規則
- foreign key 與刪除規則已定義
- migration transaction 與 rollback 已測試
- 筆數與關聯比對方式已建立
- native 與 Web schema 行為一致

任一類准入未通過，都不得匯入。

## 6. 下一個 schema 批次

下一個正式資料庫 schema 批次應先建立：

- `items`
- `schedules`
- `tasks`
- `maintenance_records`

同時必須處理：

- Item category／status enum fallback
- Schedule status、cycle type 與正式 `scheduleKind`
- Task status 與一般提醒特殊 cardId 的過渡相容
- MaintenanceRecord record type 與 nullable taskId
- Item → Schedule／Task／MaintenanceRecord foreign keys
- Schedule → Task foreign key
- Task → MaintenanceRecord optional relation
- 建立時間、更新時間與 schema version
- migration tests、transaction rollback 與 Web schema 驗證

這個 schema 批次仍不得同時執行正式資料匯入。

## 7. 合法施工順序

```text
完成舊資料准入工具
→ 鎖定舊資料遷移範圍
→ 建立 Item／Schedule／Task／MaintenanceRecord schema
→ 建立 mapper 與 repository 邊界
→ 建立純記憶體轉換預演
→ 比對來源筆數、目標筆數與關聯
→ 驗證整批 transaction rollback
→ native／Web 測試
→ 才建立可執行但預設關閉的匯入器
→ 真機人工批准
→ 才允許正式匯入
```

## 8. 明確禁止

- 不得因案件表已建立，就把所有舊資料塞進案件表。
- 不得把完成紀錄推測成完整案件。
- 不得在 schema 未完成時開始匯入。
- 不得修改或刪除 `backup_v1_*`。
- 不得以 UI 看起來正常作為遷移成功證據。
- 不得在部分資料寫入後繼續運作。
- 不得在未驗證 Web 與 iOS 前停止舊資料來源。

## 9. 回復原則

在舊資料正式匯入完成、驗證並批准前：

- SharedPreferences 仍是 Item、Schedule、Task、MaintenanceRecord 的正式來源。
- Drift 案件表不得被當作舊資料鏡像。
- 新案件功能若尚未開放，App 不應在背景建立案件資料。
- 任何新 schema 或 mapper 都必須可整批移除，而不影響舊資料讀取。
