# 生活管理 App 目前正式任務

狀態：正式控制文件
最後核對日期：2026-08-02

## 1. 目前任務狀態

目前進行中的正式任務：

- 任務名稱：入口與資訊層級收斂
- Branch：`codex/entry-information-hierarchy`
- Base：`main`
- 狀態：施工中，已完成第一版輕量入口與基本測試，等待 CI 與實機驗收
- 正式規劃：`docs/control/issues/issue-ai-guided-simplification-plan.md`
- 目標：保留全部正式功能與資料角色，第一層只呈現拍照、語音、輸入與當下必要入口；完整保養、提醒、排程、案件與完成紀錄移入「更多建立方式」，仍可正常到達。

## 2. 本任務施工內容

已完成：

1. 新增 `QuickAddScreen`，第一層只呈現拍照、語音、輸入。
2. 輸入直接沿用既有 `ItemFormScreen` 與正式 `ItemCreationRuntime` 路徑。
3. 拍照與語音保留可見入口，明確顯示尚未啟用，不假裝已有能力。
4. 既有完整 `AddScreen` 保留，改由「更多建立方式」進入。
5. 底部導覽的「史略」討論用名稱改為目前共識「履歷」。
6. 新增 Widget tests，驗證第一層未攤開內部功能、完整功能仍可到達，以及未啟用入口有誠實提示。

## 3. 明確未修改

- 未刪除任何既有正式功能。
- 未合併 Item、MaintenancePlan、Schedule、Task、WorkCase、WorkCaseUpdate、MaintenanceRecord、History 等正式資料角色。
- 未修改 Schema、Migration、Repository、Runtime 或 transaction 契約。
- 未串接真實 AI。
- 未新增照片或語音正式寫入能力。
- 未加入外部 App 資料匯入。
- 未重做生活項目詳情、搜尋或履歷內容。

## 4. PR #273 狀態與處置

- PR #273：`Simplify one-minute item creation`
- 產品實機驗收結果：完整操作超過五分鐘，分類與功能入口不夠直覺。
- 正式處置：已關閉、不合併。
- 可重用的必填驗證、防重複送出、按鈕可操作性與測試概念，可在本功能 PR 中按批准範圍重新採用；不得整批帶入舊流程。

## 5. 完成條件

- 第一次使用者 5 秒內知道從哪裡開始。
- 既有全部正式功能仍可到達。
- 主要需求最多三個畫面完成確認。
- 30 秒內找到最近建立資料。
- 60 秒內完成一筆簡單建立或安排。
- 小螢幕、鍵盤與 200% 文字可操作。
- Analyze、完整 tests、Android build、iOS build 全部通過。

## 6. 待完成驗收

1. 執行格式化與靜態分析。
2. 執行完整 Flutter tests。
3. 執行 Android build。
4. 執行 iOS build。
5. iPhone 驗證三入口、輸入建立、更多建立方式與舊功能可達。
6. 驗證小螢幕與高文字倍率操作。

## 7. 後續順序

本 PR 驗收通過後才進入：

1. 快速搜尋以前建立的資料。
2. 生活項目詳情的下一步引導。
3. AI 文字影子模式。
4. AI 確認後正式建立。
5. 語音與拍照。
6. 外部 App 資料匯入。

## 8. 更新規則

- PR Head、Draft 狀態、CI、阻擋或完成條件改變時，必須同步本文件。
- Draft 或 Open PR 不得描述成 main 已完成功能。
- 未經使用者明確批准，不得擴張本 PR 的產品或資料範圍。
