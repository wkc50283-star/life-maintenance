# 生活管理 App 核心資料角色修正案

狀態：正式控制文件  
版本：v0.5.0  
日期：2026-07-18

## 1. 修正原因

在建立 Drift 核心資料表時，稽核發現舊 MVP 結構只有 `Item → Schedule → Task → MaintenanceRecord`，缺少使用者真正長期管理的「保養項目」。

若直接把舊結構固定成正式資料庫，`Schedule` 會被迫同時代表：

- 要保養什麼
- 多久一次
- 下一次何時到期

這會混淆「管理內容」與「時間規則」，也違反已確認的產品共識：

> 保養項目與保養／修理卡不是同一件事。

因此，正式 schema 在繼續新增 Task 與 MaintenanceRecord 資料表前，必須先補回保養項目的獨立資料角色。

## 2. 正式資料流程

```text
生活項目 Item
    ↓
保養項目 MaintenancePlan
    ↓
排程 Schedule
    ↓
本次提醒 Task
    ↓
需要持續處理時建立 WorkCase
    ↓
多筆 WorkCaseUpdate
    ↓
結案後進入史略
```

這條流程不是所有資料都必須經過全部階段：

- 一般日期提醒可以由 Item 直接建立 Schedule／Task，不一定有 MaintenancePlan。
- 突發修理、工程或辦理事項可以由 Item 直接建立 WorkCase。
- 已完成的舊 MaintenanceRecord 保持舊史略角色，不反推虛構 WorkCase。

## 3. 六個核心角色

### 3.1 `Item`：生活項目

代表被長期管理的對象，例如：

- 冷氣
- 機車
- 房屋
- 身分證件
- 保險或合約
- 家庭、健康或其他生活內容

Item 只回答：

> 我在管理什麼？

Item 不應直接保存完整保養週期、某次到期任務或某次修理過程。

### 3.2 `MaintenanceCardCatalog`：系統模板目錄

代表 App 內建的建立模板，例如：

- 冷氣濾網清洗
- 機車胎壓檢查
- 合約到期確認

它的用途是協助使用者快速建立 MaintenancePlan 或提供安全步驟、風險、預估時間。

它不是：

- 使用者資料
- 真實生活項目
- 正式排程
- 已發生任務
- 處理案件

模板可更新，但不得直接改寫使用者已建立的 MaintenancePlan。

### 3.3 `MaintenancePlan`：保養項目

代表附屬於某一個 Item、長期存在的管理規則，例如：

- 客廳冷氣的濾網清洗
- 我的機車的胎壓檢查
- 租屋合約的定期確認

它回答：

> 這個生活項目長期需要管理什麼？

第一版建議欄位：

- `id`
- `itemId`
- `templateCardId`（可空；若由模板建立則保留來源）
- `title`
- `planType`
- `description`
- `riskLevel`
- `estimatedMinutes`
- `requiredPhotos`
- `requiredNote`
- `safetyNotice`
- `steps`（建立時保存的使用者步驟快照）
- `status`
- `createdAt`
- `updatedAt`
- `archivedAt`

MaintenancePlan 必須能由使用者自行建立，不得強迫一定來自模板。

模板後續更新時，不得自動覆蓋已存在 MaintenancePlan 的標題、步驟或安全資訊；任何同步都必須是明確、可審查的升級流程。

### 3.4 `Schedule`：時間規則

Schedule 只回答：

> 什麼時間規則會讓某件事浮上來？

Schedule 可以屬於：

- MaintenancePlan：週期性保養項目
- Item：一般到期提醒或日期事項
- Milestone：達標後需要形成提醒的階段性重點

因此正式 schema 不得只留下模糊的 `cardId`。來源必須依 `ScheduleSourceReference` 與來源一致性契約表示，不得用空字串假裝外鍵，也不得讓多種來源同時存在。

Schedule 保存：

- 週期種類
- 間隔
- 起始日
- 下次到期日
- 提醒時間
- 狀態
- `anchorPolicy`（正式預設為 `fixedCalendarPeriod`）

Schedule 不保存案件處理進度，也不代表某一次已經發生的任務。

### 3.5 `Task`：某一次提醒

Task 代表某個 Schedule 在某一次時間點產生的待處理提醒。

它回答：

> 這一次現在需要處理什麼？

Task 是一次性實例，不是長期規則。

一般提醒可能沒有 MaintenancePlan；因此 Task 不得用空字串假裝必填外鍵。正式欄位必須能誠實表達來源。

Task 完成不一定需要建立 WorkCase：

- 單次簡單確認可直接完成並留下 MaintenanceRecord。
- 需要多天、多次處理、等待廠商、等待零件或工程追蹤時，才升級為 WorkCase。

### 3.6 `WorkCase`／`WorkCaseUpdate`：實際處理案件

WorkCase 是一件已經發生、需要持續追蹤的實際事件，例如：

- 冷氣開始異常，聯絡廠商、檢查、等零件、完修
- 浴室漏水工程
- 證件遺失後的補辦過程

WorkCaseUpdate 是其中每一筆不可互相覆蓋的處理進度。

它回答：

> 實際發生了什麼？處理到哪裡？

WorkCase 可以由以下來源建立：

- Maintenance Task
- General Reminder
- Milestone
- Manual

WorkCase 必須可靠關聯 Item；當 Items table 進入正式 schema 時，需為 `work_cases.itemId` 建立資料庫層關聯與安全 migration。

## 4. 史略的正式組成

史略不是單一資料表名稱，而是使用者看到的統一歷史視圖。

它可包含：

- 舊 `MaintenanceRecord`
- 新 WorkCase 結案摘要
- WorkCaseUpdate 完整時間軸
- 任務完成資訊
- 費用、廠商、零件、照片識別與結果

舊 MaintenanceRecord 只能代表當時實際保存的完成紀錄，不得補造不存在的處理進度。

## 5. 舊模型與正式模型的關係

| 舊資料 | 正式定位 | 是否可直接視為新角色 |
|---|---|---|
| Item | 生活項目 | 可以，需建立正式 table 與 mapper |
| Schedule | 舊時間規則 | 不完全可以；需補來源角色，不能代替 MaintenancePlan |
| Task | 舊單次提醒 | 可以保留，但來源欄位需誠實化 |
| MaintenanceRecord | 舊完成紀錄／舊史略 | 可以保存，不得轉成 WorkCase |
| MaintenanceCardCatalog | 系統模板 | 不得轉成使用者資料 |

## 6. schema v2 修正邊界

`database/core-schema-v2` 分支目前的 enum converter、Items table 與 Schedules table 只能視為草稿，不得直接合併。

正式 schema v2 應依序建立：

1. `items`
2. `maintenance_plans`
3. 重設計後的 `schedules`
4. `tasks`
5. `maintenance_records`
6. `work_cases.itemId` 正式外鍵或等效關聯保護
7. schema v1 → v2 migration 與 rollback tests

在上述角色與 migration 完成前：

- 不接 UI
- 不匯入 SharedPreferences
- 不切換 Repository
- 不將舊紀錄轉成案件

## 7. 必要資料限制

正式 table 至少應驗證：

- `MaintenancePlan.itemId` 必須指向存在的 Item。
- `Schedule.interval > 0`。
- `Item.expectedLifeYears` 若有值，必須大於 0。
- `Task.scheduleId` 若是一般手動任務，可空；不得使用空字串偽裝關聯。
- `MaintenanceRecord.taskId` 可空，支援補登紀錄。
- WorkCase、Schedule、Task、MaintenanceRecord 的刪除與封存政策需分開定義。
- 有歷史或案件關聯的 Item 不得直接實體刪除，應優先封存。

## 8. 目前批准與凍結

批准：

- 新增 `MaintenancePlan` 正式資料角色。
- 保留 MaintenanceCardCatalog 作為模板目錄。
- Schedule 與 MaintenancePlan 分離。
- WorkCase 與 MaintenanceRecord 分離。
- 史略以統一查詢視圖呈現，不強迫全部塞入同一資料表。

凍結：

- `database/core-schema-v2` 暫停新增 Task、MaintenanceRecord 與 migration。
- 在本文件合併並完成 schema 修正設計前，不得合併該分支。
