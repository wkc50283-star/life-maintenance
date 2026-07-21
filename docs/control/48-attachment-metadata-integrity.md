# Attachment Metadata Integrity Validation（PR #236）

狀態：正式控制文件
版本：v0.5.35
日期：2026-07-21

## 1. 範圍與結論

本 PR 只驗收既有 Attachment metadata abstraction、Drift Repository 與 Runtime，不修改 production logic。現有正式流程已通過五種 Owner、完整 metadata round-trip、狀態生命週期、不安全 identifier、owner existence 與 rollback 防回歸矩陣，未發現需要修改 Runtime 的阻擋性缺陷。

本次承認的正式 Owner 僅有：

- `item`
- `maintenanceRecord`
- `workCaseUpdate`
- `workCaseClosure`
- `milestone`

`unknown` 只供舊資料安全讀取，新 Attachment 不得使用。

## 2. 建立與查詢 Gate

- 每種正式 Owner 必須已存在，才能建立 Attachment metadata。
- 建立後 `findById` 與 `listForOwner` 必須完整保留 identifier、原始檔名、MIME、byte size、capturedAt、hash、note、state 與 createdAt。
- 不同 Owner 的查詢不得混入其他 Owner 的 Attachment。
- 不存在或 unknown Owner 必須在 transaction 內拒絕，且不得留下部分 row。

## 3. Metadata lifecycle

- 新 Attachment 只能從 `available` 開始。
- `missing` 必須保存 `missingAt`。
- 重新驗證後回到 `available`，保存 `verifiedAt` 並清除 `missingAt`。
- `recordStorageDeleted` 只記錄 managed storage 已確認刪除後的 metadata 事實，保存 `deletedAt`；本 PR 不執行實體檔案刪除。
- `deleted` metadata 必須保留供歷史查詢，且不得恢復、再次刪除或轉為 missing。
- lifecycle 時間不得早於 Attachment 建立時間；失敗後原狀態必須完整保留。

## 4. Identifier 與 rollback Gate

Runtime 與底層 Repository 都必須拒絕空白、絕對路徑、Windows path、`.`／`..` traversal、encoded separator、反斜線、URI scheme、query、fragment 與控制字元，避免繞過 abstraction。

重複 ID、無效 identifier、owner 不存在或非法 lifecycle transition 任一失敗時：

- 既有 Attachment metadata 不得被覆寫。
- 不得留下新的部分 row。
- row count 與原內容必須保持一致。

## 5. 明確未完成與禁止宣稱

- 不支援或宣稱 WorkCase 直接 Attachment Owner；案件附件只能依現有正式模型附屬於 WorkCaseUpdate 或 WorkCaseClosure。
- 未驗收實體檔案新增、讀取、預覽或刪除。
- 未驗收孤兒實體檔掃描或清理。
- 未建立 storage adapter、相簿、分享或雲端能力。
- Attachment metadata 的 `deleted` 狀態不得被描述為本 PR 已刪除平台實體檔。

## 6. 明確未修改

- 不修改 UI、Domain、Schema、Migration、Runtime、Repository contract 或正式生命週期。
- 不新增資料表、Owner、storage adapter、產品功能或平行附件流程。
- 不讀寫、刪除或覆蓋 SharedPreferences、`backup_v1_*` 或既有使用者資料。
- Item 仍是 Root；Task 仍是提醒；WorkCase 才是案件；WorkCaseClosure 才是正式結案；History 仍是投影。

## 7. 合併 Gate

codegen 必須無差異，Analyze、全部 tests、Web／Android／iOS build 與 GitHub Actions 必須全綠。任何文件或 PR 說明若把 metadata 驗收誤稱為實體檔案能力，均不得合併。
