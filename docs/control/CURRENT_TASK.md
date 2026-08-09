# 生活管理 App 目前正式任務

狀態：正式控制文件
最後核對日期：2026-08-09

## 1. 目前任務

目前進行中的正式任務：

- 任務名稱：PR #288 合併後控制文件同步
- Branch：`docs/sync-main-after-pr288`
- Base：`main`
- Base SHA：`8ebffb99ea877ad76931c5d77aa56dbf7f5e3765`
- 任務類型：文件／治理同步，不是功能施工 PR
- 目的：把已批准的四個生活目的入口、三方工程權責與最新 main／Schema v10 正式能力重新寫回控制文件，取代已落後的 CURRENT_STATE／CURRENT_TASK 與舊基準 PR #280。

## 2. 本任務允許修改

只允許處理以下控制文件：

1. `docs/control/CURRENT_STATE.md`
2. `docs/control/CURRENT_TASK.md`
3. `docs/control/04-development-rules.md`
4. `docs/control/issues/issue-manual-create-four-purpose-plan.md`

不得修改 Flutter 程式、UI、導航、Schema、Migration、Model、Repository、Runtime、測試、依賴或 App version。

## 3. 本次同步必須寫清楚的事實

- 正式 App version：`0.5.53+54`
- 正式 Schema：v10
- 最新 main：`8ebffb99ea877ad76931c5d77aa56dbf7f5e3765`
- PR #281、#283、#285、#286、#287、#288 已形成目前資料能力基線。
- PR #288 CI 全綠並已合併。
- 四個生活目的入口仍是已批准產品方向，但不得把資料層 foundation 誤寫成 UI 已完成。
- PR #280 仍是舊基準 OPEN PR；不得直接合併到現行 main，應由本次最新控制文件取代。

## 4. 四入口正式方向

第一層只保留四個生活目的：

1. 建立要長期管理的內容
2. 安排未來要注意或處理的事情
3. 記錄正在處理的事情
4. 補記已完成的事情

共同規則：

- 四入口只負責新增。
- 最低成立後即可正式建立，不強迫一次填完整。
- 建立成功後可先記錄或繼續補充；是否補充由使用者決定。
- 正式建立、補充、修改與狀態變化必須可追溯到履歷。
- 不得未經使用者確認自動建立提醒、排程、下一次安排或其他正式資料。
- 鎖定產品邏輯，不鎖死介面表現。
- 未經真機驗證的文案、版面、步驟與互動只能標記為待實機驗證。

完整規劃見 `docs/control/issues/issue-manual-create-four-purpose-plan.md`。

## 5. 資料基礎與四入口的目前關係

### 入口 1｜建立要長期管理的內容

- 已有 ItemCreationRuntime、固定管理週期、自訂管理週期資料基礎與管理週期修改履歷能力。
- 管理週期不等於 Reminder／Schedule／Task，不得自動建立後續排程。
- 四入口 UI 與完整實機驗收仍未完成。

### 入口 2｜安排未來要注意或處理的事情

- 已有 FutureMatter v7～v10 的建立、修改、完成、補充／更正與履歷資料基礎。
- 這些資料層能力不代表入口 2 UI 已完成。

### 入口 3｜記錄正在處理的事情

- Repo 已有 WorkCase 與相關正式資料角色。
- 最終映射、最低成立、建立後履歷與 UI 必須在施工前另做只讀工程映射；不得由 Codex 自行決定。

### 入口 4｜補記已完成的事情

- Repo 已有 MaintenanceRecord 等完成紀錄能力，FutureMatter 也已有正式 completion／amendment foundation。
- 補登完成、既有排程關聯、後續週期計算與影響範圍仍需依已批准產品規則逐項映射，不得自行連動。

## 6. 本任務完成條件

- 四份控制文件以最新 main／Schema v10 為基準。
- 不把 Open／Draft／未實機驗證內容誤列為完成。
- 不修改任何 App 程式或正式資料契約。
- 文件內的 App version、Schema、main SHA、PR 狀態彼此一致。
- 建立新的文件 PR，以最新 main 為 Base；通過 diff 稽核與必要 CI 後才能合併。
- 新文件 PR 合併後，舊 PR #280 才可關閉為「已被新版控制文件取代」，不得反向合併舊 branch。

## 7. 後續功能施工順序

本文件 PR 完成後，不自動開始下一個功能 PR。下一步先依最新 main 做「四入口對現有 Model／Runtime／Repository／History 的只讀工程映射」，由 GPT 整理施工規格，再由使用者逐項批准。

沒有批准，不得進入 UI 或資料施工。

## 8. 更新規則

- PR Head、Draft、CI、阻擋、Base 或完成條件改變時，必須同步本文件。
- Draft 或 Open PR 不得描述成 main 已完成功能。
- 未經使用者批准，不得擴張本任務的產品或資料範圍。
