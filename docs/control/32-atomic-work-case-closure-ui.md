# WorkCaseClosure 原子結案 UI 控制規格

狀態：正式控制文件

版本：v0.5.19

適用範圍：PR #220

## 1. 正式定位

WorkCaseClosure 是 WorkCase 唯一正式結案來源。結案 UI 只收集與送出正式 Closure 資料，不直接改 WorkCase terminal status，也不寫入 History。

## 2. 結案資料

正式表單保存：

- 完成日期
- 完成結果
- 結案摘要
- 總費用（無費用時為 0）
- 後續注意事項
- 可選同 Item 的既有正式 Schedule 關聯
- 可選新建一則同 Item 的單次 manual Task 提醒

畫面不顯示內部 ID。沒有可用正式 Schedule 時，畫面誠實說明，不建立假排程。

## 3. 單一 transaction

Runtime 必須在同一 Drift transaction 中依序完成：

1. 驗證 WorkCase 仍可結案。
2. 建立可選的一次性後續 Task。
3. 驗證可選 Schedule 與 WorkCase 屬於同一 Item。
4. 寫入唯一 WorkCaseClosure。
5. 將 WorkCase 設為 completed 並保存完成時間。

任一步失敗，Task、Closure 與 WorkCase 狀態全部 rollback。既有 Schedule 只被引用，不複製、不更新，也不改變原本週期或 ScheduleAnchorPolicy。

## 4. History 邊界

History 只透過既有 HistoryProjectionRepository 即時組合已終止 WorkCase、Updates 與唯一 Closure。結案 transaction 不新增 History row、cache 或 writer。

## 5. 禁止事項

- 不修改 Schema、Migration 或 Domain model。
- 不讓 Task 直接完成案件。
- 不以修改 WorkCase.status 取代 Closure。
- 不把後續注意事項當成提醒或排程的平行資料。
- 不在 UI 逐筆寫入後續資料與 Closure。
- 不建立正式 Schedule 來源契約以外的新來源。
