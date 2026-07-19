# Data Integrity Audit（PR #225）

狀態：正式控制文件
版本：v0.5.24
日期：2026-07-20

## 1. 範圍與結論

本次只稽核既有 Drift Schema v2 資料路徑，不修改 Schema、Migration、Domain、UI 或產品功能。Drift 仍是唯一正式資料來源；SharedPreferences 與 `backup_v1_*` 只保留為唯讀匯入證據與災難回復材料。

稽核確認 transaction／rollback、FK／UNIQUE、匯入、備份、回復及 crash recovery 均已有正式保護。唯一阻擋性問題是 SharedPreferences 平台拒絕 `setString`、回傳 `false` 時，備份工具仍會誤判成功；本 PR 將該結果改為明確失敗，交由既有完整性 Gate 阻擋後續匯入。

## 2. 驗證矩陣

| 範圍 | 正式規則 | 驗證方式 | 結果 |
|---|---|---|---|
| transaction | 關聯寫入必須原子完成 | Repository、WorkCaseClosure、import 交易測試 | 通過 |
| rollback | 任一步失敗不得留下部分資料 | 記憶體與檔案 DB 強制失敗測試 | 通過 |
| FK | 所有正式實體關聯啟用且刪除為 RESTRICT | `foreign_keys`、`foreign_key_list`、`foreign_key_check` Gate | 通過 |
| UNIQUE | Plan Step 順序、Task scheduleId + dueDate、WorkCase Closure 唯一 | SQLite index metadata 與既有衝突測試 | 通過 |
| import | dry-run、准入檢查、單一交易、重跑保護、前後完整性檢查 | Legacy importer 測試 | 通過 |
| backup | 原始值逐字備份、不可覆寫、寫入拒絕必須失敗 | backup service 與平台拒絕測試 | 修正後通過 |
| restore | 不自動恢復 Legacy writer；失敗時保持 Drift 安全狀態 | Legacy retirement／runtime Gate | 通過 |
| crash recovery | 已提交資料重啟後存在；未完成交易重啟後不存在 | 檔案 DB close／reopen 測試 | 通過 |

## 3. Rollback 與回復邊界

- 匯入失敗：整個 Drift transaction rollback，來源與 `backup_v1_*` 不刪除、不覆寫。
- Runtime 啟動失敗：進入 Drift 安全狀態，不切回 Legacy writer，也不建立雙寫。
- PR 程式回復：可還原本 PR 的 service、tests、文件與版本；沒有 Schema 或資料格式 rollback。
- 災難回復：只使用保留的唯讀來源與不可變備份作人工受控證據，不讓正式畫面冷啟動回讀舊來源。

## 4. 防回歸 Gate

PR #225 後必須持續驗證：

1. SharedPreferences 寫入回傳 `false` 必須視為失敗。
2. FK 必須啟用，正式關聯必須維持 RESTRICT，`foreign_key_check` 必須為空。
3. 三個正式 UNIQUE index 必須存在且保持 unique。
4. 檔案型資料庫重啟後，只能保留已 commit 的資料。
5. `integrity_check` 必須回傳 `ok`。

任一 Gate 失敗即不得匯入、發布或合併。
