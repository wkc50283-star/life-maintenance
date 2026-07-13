# PMS v0.13.0 規格凍結｜完成真正閉環

- 狀態：正式凍結
- 適用版本：v0.13.0
- 原則：後續版本不得在沒有明確批准的情況下破壞此版本資料角色、操作語意與安全條件

## 一、版本目標

v0.13.0 完成真正閉環：

Task 完成
→ MaintenanceRecord 建立
→ 使用者決定 Schedule 後續狀態
→ paused 資料可找到
→ paused 資料可重新安排並恢復

## 二、核心資料角色

Item

- 責任錨點。
- 代表被管理的物品、文件或生活責任主體。
- 不等於 Task。
- 不等於 Schedule。

Schedule

- 排程安排與狀態。
- 決定是否及何時產生 Task。
- 不等於待辦事項實例。
- 不等於完成紀錄。

Task

- Schedule 到期後產生的一次待處理實例。
- Today 顯示與完成的是 Task。

MaintenanceRecord

- 已完成處理的履歷。
- 不承擔 Schedule 控制狀態。
- 不得把後續安排寫進 note、result 或 workDescription 作為控制資料。

## 三、Schedule 狀態

ScheduleStatus.active

- 允許 MaintenanceTaskService 產生 Task。
- enabled 相容值為 true。

ScheduleStatus.paused

- 保留排程資料。
- 暫時不產生 Task。
- enabled 相容值為 false。
- 可以重新安排並恢復 active。

ScheduleStatus.ended

- 正式結束。
- 不產生 Task。
- enabled 相容值為 false。
- v0.13.0 不允許恢復。

paused 不等於 ended。

## 四、舊資料相容規則

- 舊 JSON 沒有 status 時：
  - enabled=true → active
  - enabled=false → ended
- 舊 enabled=false 不得推論為 paused。
- toJson 同時寫入 status 與相容 enabled。
- 採 lazy fallback。
- v0.13.0 不建立 migration。

## 五、Task 產生規則

- MaintenanceTaskService 只處理 active Schedule。
- paused / ended 不產生 Task。
- 到期後才產生 Task。
- 恢復 Schedule 時不立即建立 Task。
- 同 scheduleId + 同 dueDate 防止重複 Task。
- 不修改既有 overdue 判斷。

## 六、一般保養完成後續處理

固定三個選項：

1. 繼續原週期

- Task completed。
- 建立 regularMaintenance Record。
- Schedule 維持 active。
- 推進 nextDueDate。

2. 保留但不排程

- Task completed。
- 建立 Record。
- Schedule 改為 paused。
- nextDueDate 不變。

3. 結束排程

- Task completed。
- 建立 Record。
- Schedule 改為 ended。
- nextDueDate 不變。

三者只能擇一，不得同時執行。

## 七、手動提醒完成後續處理

固定三個選項：

1. 結束提醒

- Task completed。
- 建立 expiryHandled Record。
- Schedule 改為 ended。

2. 保留但不排程

- Task completed。
- 建立 expiryHandled Record。
- Schedule 改為 paused。

3. 重新安排日期

- Task completed。
- 建立 expiryHandled Record。
- Schedule 維持 active。
- 更新 nextDueDate。

## 八、paused 手動提醒

- 顯示於既有提醒清單。
- 狀態文案：已暫停。
- ended 文案：已結束。
- paused 詳情顯示「重新安排並恢復」。
- active / ended 不顯示此按鈕。
- 新日期只能選今天之後的日期，最早為明天。
- pending 同日 Task 會阻止恢復。
- completed / canceled Task 不算衝突。
- 恢復只更新：
  - status=active
  - nextDueDate

## 九、paused 一般保養

- 顯示於 Item 詳情的獨立「保養安排」區塊。
- 不混入「需要你記住的事」。
- active 文案：進行中。
- paused 文案：已暫停。
- ended 文案：已結束。
- paused 顯示「重新安排並恢復」。
- active / ended 不顯示此按鈕。
- 恢復只更新：
  - status=active
  - nextDueDate

## 十、安全條件

- Schedule 更新必須重新讀取本機資料。
- 只更新第一筆符合條件資料。
- 一般保養與 manual reminder 必須用 cardId 隔離。
- 必須檢查 scheduleId / id。
- Item 詳情恢復一般保養時必須檢查 itemId。
- paused 操作只允許更新 paused Schedule。
- ended 不得恢復。
- repository 失敗不得誤顯示成功。
- follow-up 失敗不得回滾已成功的 Task 與 MaintenanceRecord。
- completed Task 不得重複完成。
- 相同 taskId 不得重複建立 Record。
- 已存在 Record 時不得再次執行 follow-up。

## 十一、提示規則

- follow-up updated：
  `已完成任務並建立紀錄，可到履歷查看`
- follow-up notApplicable / failed：
  `已完成並建立紀錄，但後續安排未更新`
- paused 手動提醒恢復成功：
  `提醒已重新安排並恢復`
- paused 一般保養恢復成功：
  `保養安排已重新安排並恢復`

## 十二、版本不包含範圍

v0.13.0 不包含：

- 履歷時間軸
- Schedule 刪除
- ended 恢復
- paused 直接使用舊日期恢復
- 一般保養總排程清單
- 首頁排程管理中心
- 雲端同步
- 帳號系統
- migration
- 獨立責任事項 model

## 十三、禁止偏移事項

- 不得把 paused 與 ended 合併回 enabled=false 的單一語意。
- 不得把 Schedule 當成 Task。
- 不得把 Task 當成長期事項。
- 不得把 MaintenanceRecord 當作排程控制資料。
- 不得把一般保養混入 manual reminder 清單。
- 不得讓 manual reminder 誤更新一般保養 Schedule。
- 不得讓首頁成為排程管理中心。
- 不得以文案假裝資料狀態不同。
- 不得在未批准情況下破壞舊 JSON fallback。
- 不得為方便而重寫已驗證完成流程。

## 十四、v0.13.0 完成判定

- production 主線已完成。
- flutter analyze 通過。
- flutter test 通過。
- 沒有阻止升版的 production bug。
- 剩餘事項只有真機 UI 驗收與非阻塞測試補強。
- 下一版本可進入：v0.14.0｜履歷時間軸。
