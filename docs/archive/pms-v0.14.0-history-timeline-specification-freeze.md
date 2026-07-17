# 歷史文件｜PMS v0.14.0 規格凍結｜履歷時間軸

> **封存狀態：已撤銷現行規格效力。**
>
> 本文件只用於追溯 PMS 時期的產品演化。文件內原有的「正式凍結」、「不得破壞」與「禁止偏移」等文字，只適用於當時的 PMS v0.14.0 設計背景，不能控制目前的生活管理 App。
>
> 現行需求、開發與驗收一律以 `docs/control/` 六份正式控制文件為準。若本文件與現行控制文件衝突，以現行控制文件為準。

---

## 原始歷史內容

# PMS v0.14.0 規格凍結｜履歷時間軸

- 狀態：正式凍結
- 適用版本：v0.14.0
- 原則：後續版本不得在未經明確批准的情況下破壞本版本履歷資料來源、入口角色與只讀邊界

## 一、版本目標

v0.14.0 完成：

MaintenanceRecord
→ History 月份分組
→ 日期新到舊
→ 時間軸節點
→ 點擊查看既有紀錄詳情

## 二、唯一資料來源

- Timeline event 只能來自 MaintenanceRecord。
- 不得把 Task、Schedule 或 UI 操作偽裝成履歷事件。
- Timeline 不建立或修改任何業務資料。

## 三、三層履歷角色

### History Timeline

- 全 App 完成紀錄總覽。
- 顯示所有 Item 的 MaintenanceRecord。
- 依月份與日期排序。

### Item Detail「處理紀錄」

- 單一 Item 的上下文摘要。
- 不建立第二套完整 Timeline。
- 不需要立即新增跳轉或篩選。

### MaintenanceRecord Detail

- 單筆完成紀錄詳情。
- History 與 Item Detail 共用。
- 不修改 Record。
- 不控制 Schedule。
- 不建立 Task。

## 四、排序與月份分組

- 依 MaintenanceRecord.date 新到舊。
- 月份由新到舊。
- 月份內紀錄由新到舊。
- 月份標題包含年份。
- 不顯示空月份。
- 各月份時間線彼此獨立。

## 五、時間軸節點

每筆節點至少顯示：

- 日期
- Item 名稱
- Record 標題
- RecordType 文案
- 一行摘要
- result 或既有補充資訊

時間軸視覺只包含最小節點與垂直線，不代表新增資料模型。

## 六、摘要規則

固定順序：

1. workDescription
2. issueDescription
3. note
4. `已留下保養維修紀錄。`

null 與空字串必須跳過。

## 七、RecordType 正式文案

- regularMaintenance → 保養
- failure → 故障
- repair → 維修
- partsReplacement → 更換
- expiryHandled → 到期提醒
- construction → 施工
- other → 其他

## 八、Item 名稱與 fallback

- 以 MaintenanceRecord.itemId 對應 Item.id。
- 找不到 Item 時顯示 `未命名物品`。
- 不得因 Item 缺失而 crash。

## 九、舊資料相容

必須支援：

- taskId == null
- 可選文字欄位為 null 或空字串
- cost == null
- warrantyUntil == null
- photos 為空
- 舊 MaintenanceRecord
- corrupted local records 安全降級為空 list

不建立 migration。

## 十、資料安全邊界

- History 只讀取 MaintenanceRecord。
- 不修改 Record。
- 不修改 Schedule。
- 不修改 Task。
- 不建立 Timeline repository。
- 不新增 Timeline model。
- 不寫入 Schedule／Task 狀態事件。
- 顯示 Timeline 不得產生本機資料變化。

## 十一、空狀態與既有 fallback

- 保留現有本機資料載入。
- 保留既有 MockData fallback。
- 保留既有 EmptyHistoryState。
- MockData 行為屬既有產品行為，不是 Timeline 新邏輯。

## 十二、v0.14.0 不包含範圍

- 未完成 Task
- Schedule active / paused / ended 事件
- 提醒建立、暫停、恢復事件
- 搜尋
- 篩選器
- 統計
- 匯出
- Record 編輯
- Record 刪除
- 照片管理
- Timeline 專用 model
- Timeline 專用 repository
- Item Detail 第二套完整 Timeline
- 新頁面

## 十三、UX 債與非阻塞事項

以下事項僅記錄為非阻塞，不得寫成 production bug：

- Detail 顯示技術 ID。
- Detail 欄位順序偏追溯導向。
- photos 尚未在 Detail 呈現。
- IntrinsicHeight 的理論效能風險。
- 長文字與大量紀錄的真機密度待統一驗收。
- 少數直接測試缺口。

## 十四、禁止偏移事項

- 不得把 Timeline 變成排程控制中心。
- 不得從 Timeline 建立 Task。
- 不得從 Timeline 修改 Schedule。
- 不得把未完成事項顯示為完成履歷。
- 不得把純技術事件當成人類可理解的履歷。
- 不得為了 Timeline 新增第二套 MaintenanceRecord。
- 不得讓 History 與 Item Detail 使用不同詳情資料來源。
- 不得未經批准擴大為搜尋、統計或紀錄管理系統。
- 不得為方便而破壞 v0.13.x 已凍結狀態機。

## 十五、完成判定

- v0.14.0 第一版 production 主線完成。
- flutter analyze 通過。
- flutter test 通過。
- 沒有阻止版本結案的 production bug。
- History / Item Detail / Detail 三層邊界已確認。
- 剩餘事項只有文件、統一真機驗收、tag 與下一版本規劃。
