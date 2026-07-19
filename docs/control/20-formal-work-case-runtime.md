# 正式 WorkCase Runtime

狀態：正式控制文件
版本：v0.5.7
日期：2026-07-19
適用 PR：#208

## 1. 正式範圍

只有當 AppCompositionRoot 完成舊來源與 Drift 匯入驗證，案件 Runtime 才可被注入。案件資料只寫入 Drift；SharedPreferences 與不可變備份維持唯讀且不新增案件儲存鍵。

本版本不重畫 UI、不修改 Schema 或 Migration、不建立 History writer，也不切換 MaintenanceRecord。

## 2. 正式生命週期

```text
Task／手動建立
        ↓
    WorkCase
        ↓
多筆 WorkCaseUpdate
        ↓
唯一 WorkCaseClosure
        ↓
History 查詢投影
```

- Task 只提供提醒與來源證據，建立案件不得完成、取消或改寫 Task。
- WorkCase 是事情正式開始處理的唯一案件角色。
- WorkCaseUpdate 是不可覆寫的過程事實，可有多筆。
- WorkCaseClosure 是唯一正式結案資料；History 不另行寫入。

## 3. 建立來源與 Item 約束

- `scheduledMaintenance` Task 建立 `maintenanceTask` WorkCase，保存來源 Task ID。
- `scheduledReminder` Task 建立 `generalReminder` WorkCase，保存正式 GeneralReminder ID。
- `milestone` Task 建立 `milestone` WorkCase，保存正式 Milestone ID。
- 手動案件必須使用 `manual` 且不得有 source ID。
- Task、GeneralReminder、Milestone、WorkCase、Closure follow-up Schedule／Task 必須屬於同一 Item。
- `unknown` 只允許保留既有資料，不得新建。

## 4. 寫入與 transaction

- WorkCase 與第一筆 WorkCaseUpdate 可在單一 transaction 建立。
- 追加 WorkCaseUpdate 與案件狀態變更可在單一 transaction 完成；任一驗證或 insert 失敗時兩者一起 rollback。
- Closure insert 與 WorkCase 的 completed／canceled 狀態、時間及取消原因必須在單一 transaction 完成。
- 一個 WorkCase 最多一筆 Closure，資料庫 unique constraint 與 Repository 驗證共同防護。
- terminal status 不得由一般 save／status API 設定，必須經 Closure。

## 5. 不可變與終止規則

- 案件的 Item、來源類型、來源 ID 與建立時間不可改動。
- WorkCaseUpdate 只允許新增，不提供覆寫 API；描述必填，費用不得為負。
- completed 或 canceled 後，WorkCase、Update 與狀態均不得再修改。
- Closure 不得由 Update 自動推測，也不得以 WorkCase 一般欄位替代。

## 6. 驗收

- 三種 Task source 與手動案件建立。
- 跨 Item／缺失來源／未知來源阻擋。
- 多筆 Update、不可覆寫、非負費用與原子 rollback。
- 唯一 Closure、結案／取消 transaction 與終止後唯讀。
- 冷啟動後案件仍存在且 SharedPreferences 原文零寫入。
- Task 狀態不因建立案件而改變，History 無寫入流程。
- codegen、Analyze、全部 tests、Web release build、CI 與 Web 預覽通過。
