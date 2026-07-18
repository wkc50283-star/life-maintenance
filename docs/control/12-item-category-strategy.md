# 生活管理 App 生活項目類別策略

狀態：正式控制文件候選  
版本：v0.5.0  
日期：2026-07-18

## 1. 決策原因

現有 `ItemCategory` 只有：

- appliance
- vehicle
- house
- warrantyDocument
- other

這是舊生活維護 MVP 的設備導向分類，無法完整承接目前已確認的生活管理範圍，例如健康與照護、家庭、寵物、財務、學習、工作、文件與合約。

若直接把舊 enum 固定成 Drift schema，資料庫會再次把產品限制成家電／車輛維護工具。

## 2. 正式決策

採用：

> 系統大類代碼＋使用者自訂類別名稱

正式 Item 不再只依賴單一固定 enum 顯示分類，而是保存：

- `categoryCode`：系統穩定大類代碼
- `customCategoryName`：使用者自訂名稱，可空

`categoryCode` 用於資料查詢、預設圖示、模板建議與安全 fallback；`customCategoryName` 用於使用者真正看到的細分類名稱。

## 3. 第一版系統大類

正式 `ItemCategoryCode` 第一版：

- `homeAndAppliance`：家電、家具、居家設備
- `vehicleAndTransport`：汽機車、自行車、交通工具
- `houseAndRepair`：房屋、空間、修繕與工程
- `documentAndContract`：證件、保固、保險、合約與到期文件
- `healthAndCare`：健康、醫療、復健、照護與用藥管理對象
- `family`：家庭成員、家庭責任與共同生活事項
- `pet`：寵物、醫療、照護與相關用品
- `finance`：帳務、資產、貸款、稅務與財務責任
- `learning`：課程、證照、學習計畫與教材
- `work`：工作設備、職涯事項與工作責任
- `other`：無法歸入以上大類
- `unknown`：未來版本或未知值的安全 fallback

## 4. 使用者自訂名稱

系統大類不應限制使用者實際理解。

例如：

| categoryCode | customCategoryName | 使用者看到的分類 |
|---|---|---|
| homeAndAppliance | 廚房設備 | 廚房設備 |
| documentAndContract | 保險與合約 | 保險與合約 |
| healthAndCare | 爸爸的復健 | 爸爸的復健 |
| pet | 阿福 | 阿福 |
| other | 社區事務 | 社區事務 |

顯示規則：

1. `customCategoryName` 有內容時，優先顯示自訂名稱。
2. 自訂名稱為空時，顯示系統大類中文名稱。
3. 未知代碼顯示「其他」，不得因未知 enum 造成整筆資料無法讀取。

## 5. 舊資料對應

舊 `ItemCategory` 遷移到新類別：

| 舊值 | 新 categoryCode | customCategoryName |
|---|---|---|
| appliance | homeAndAppliance | 空 |
| vehicle | vehicleAndTransport | 空 |
| house | houseAndRepair | 空 |
| warrantyDocument | documentAndContract | 空 |
| other | other | 空 |
| 未知值 | unknown | 保留原始值於 migration report，不自動猜測 |

不得依 Item 名稱自動猜測健康、家庭、寵物或財務類別。舊資料只能做確定映射；無法確定的內容保留為 `unknown` 或 `other`，由使用者日後自行調整。

## 6. 模型與資料庫邊界

正式 Item 模型與 schema v2 應包含：

- `categoryCode`
- `customCategoryName`（nullable）

不得：

- 把中文顯示名稱當作資料庫主鍵或關聯值
- 以自由文字完全取代穩定 categoryCode
- 在 migration 時依名稱或備註自行分類
- 刪除舊分類原始值而不留下比對證據

## 7. 自訂類別的第一版範圍

第一版不建立獨立 `item_categories` table。

原因：

- 目前需求只需要穩定大類與單筆自訂顯示名稱
- 尚未需要跨 Item 共用排序、顏色、圖示、封存或階層分類
- 過早建立完整類別管理子系統會增加 migration 與 UI 複雜度

未來若需要使用者建立可重用類別，另以新 schema 版本新增 `item_categories`，不得在 schema v2 中預先塞入未使用功能。

## 8. UI 原則

新增／編輯生活項目時：

- 先選擇一個容易理解的系統大類
- 可選填更貼近生活的自訂類別名稱
- 不要求使用者理解資料庫代碼
- 不強迫使用者在建立當下把分類做到完美

首頁與生活項目詳情應以使用者名稱與實際管理內容為主，分類只能作為輔助，不得再次把 App 做成分類管理器。

## 9. 查詢與模板原則

`categoryCode` 可以用於：

- 建議可用的 MaintenanceCardCatalog 模板
- 預設圖示
- 預設排序或篩選
- 統計與搜尋

但分類不得決定使用者能否建立某種 MaintenancePlan、Milestone 或 WorkCase。

例如健康項目也可以有週期保養、階段性重點或突發事件；`categoryCode` 只提供建議，不是功能權限。

## 10. schema v2 阻擋條件

PR #185 在以下事項完成前不得解除 Draft：

- `items` table 改用新 categoryCode 與 customCategoryName
- 舊 ItemCategory 映射規則寫入 migration 設計
- 未知舊分類有明確保留與報告方式
- 模型 round-trip 與未知值 fallback 測試完成
- 不再以舊五類 enum 作為正式 schema 唯一分類

## 11. 明確未修改

本文件 PR 不修改：

- 現有 Item 模型
- SharedPreferences JSON
- Drift schema
- UI
- Repository
- 遷移程式

## 12. 驗收

- 正式生活類別涵蓋產品規格中的主要生活領域
- 舊五類資料可確定映射且不猜測
- 未知值不造成資料遺失
- 自訂名稱不破壞穩定系統代碼
- 不提前建立未使用的完整類別管理子系統
- PR 差異只包含控制文件
