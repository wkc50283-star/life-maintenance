# 受控 Runtime 匯入與 Item 讀取切換

狀態：正式控制文件
版本：v0.5.4
日期：2026-07-19
適用 PR：#205

## 1. 正式範圍

App 啟動時由唯一 `AppCompositionRoot` 先建立不可變備份、解析四組舊來源並執行既有安全 importer。只有 importer 回報 `imported` 或 `alreadyImported`，才把 ItemCategory／Item 的正式 read repository 切換為 Drift。

本版本不切換 Task、Schedule、MaintenanceRecord 或 WorkCase writer，不修改 Schema、Migration、Domain 或 UI 設計。

## 2. 單一來源與寫入規則

- 匯入 transaction 開始前，Composition Root 先關閉同一 `LocalStorageService` 的所有寫入。
- 匯入成功後 SharedPreferences 與 `backup_v1_*` 永久維持唯讀；所有 LocalRepository save／remove 都由底層 gate 阻擋。
- Drift Item 讀取不會回寫 SharedPreferences，也不在使用者操作中 mirror 或雙寫。
- 尚未切換的 mutation 不改寫 Drift；新增入口於本階段保持關閉，Task 完成與 Schedule 恢復亦不得寫舊來源。

## 3. 啟動狀態判定

不新增 Schema table 或 SharedPreferences marker。正式狀態由 importer 對來源、不可變備份與 Drift 目標逐列驗證後確定：

- `imported`：本次 transaction 完整寫入並驗證，切換 Item read。
- `alreadyImported`：所有確定性 row 逐列相同，零寫入切換 Item read。
- `blocked` 或其他失敗：transaction rollback，恢復舊 Runtime 與舊 writer，不做部分切換。

這個判定每次冷啟動重做，因此不會因記憶體旗標遺失而誤切來源。

## 4. Item Domain 邊界

正式畫面只依賴 `ItemReadRepository`。Drift adapter 同時讀取 ItemCategory 與 Item，依正式 legacy category mapping 轉回目前 UI 使用的 Domain `Item`；UI 不接觸 Drift row 或 Database。

首頁生活總覽、生活項目清單／詳情，以及其他 Item 名稱投影共用同一 Composition Root read repository，避免同一 Item 在不同畫面分流來源。

## 5. Rollback

來源／備份不一致、資料無法解析、關聯錯誤、目標衝突、FK／integrity 失敗或 transaction 中途錯誤時：

1. Drift transaction 整批 rollback。
2. SharedPreferences 與不可變備份原文不變。
3. Composition Root 保持 legacy Item reader。
4. 重新開啟舊 writer，讓尚未成功匯入的 App 維持既有 Runtime。

成功切換後不提供破壞性反向搬移；來源只作唯讀回復證據。

## 6. 驗收

- 首次匯入、重啟 `alreadyImported`、blocked rollback 與來源唯讀測試。
- Drift ItemCategory／Item Domain mapping 與正式畫面讀取測試。
- `rg` 證明正式畫面不直接建立 Repository、LocalStorageService 或 SharedPreferences。
- codegen、Analyze、全部 tests、Web release build、CI 與 Web 預覽通過。
