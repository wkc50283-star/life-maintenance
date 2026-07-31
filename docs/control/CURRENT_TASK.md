# 生活管理 App 目前正式任務

狀態：正式控制文件
最後核對日期：2026-08-01

## 1. 任務識別

- Issue：#268
- 任務名稱：一分鐘建立生活項目並自動產生第一筆史略
- PR：#270
- PR URL：<https://github.com/wkc50283-star/life-maintenance/pull/270>
- Branch：`issue-268-one-minute-item-creation`
- Base commit：`a214658fea5eda280a10d00ede292c2bf2fd3a86`
- Head branch：`issue-268-one-minute-item-creation` 的 GitHub `headRefOid`（本文件與最新 Head 同步提交，精確 SHA 以 PR metadata 為準）
- 功能施工 commit：`3ee2d53ebd96b3cf5150ee944d92a994841e344d`
- 同步 main commit：`a214658fea5eda280a10d00ede292c2bf2fd3a86`
- PR 狀態：OPEN、Draft、未合併

## 2. 核准範圍

- 「＋新增」開啟拍照／語音／輸入 bottom sheet。
- 拍照與語音誠實顯示尚未啟用，不寫入正式資料。
- 輸入流程以名稱、分類與管理週期建立 Item。
- 只呼叫正式 `ItemCreationRuntime.create()`，自然建立唯一 created lifecycle event。
- 成功畫面、ItemDetail 與全域 History 承接 `ItemCreatedHistoryEntry`。

完整範圍以 PR #270 內的 `docs/control/issues/issue-268-one-minute-item-creation.md` 為準；該文件尚未進入 main。

## 3. 驗證狀態

- 同步前 Head `3ee2d53ebd96b3cf5150ee944d92a994841e344d` 的 `quality`、`android-build`、`ios-simulator-build` 均為 SUCCESS。
- 同步最新 `main` 後，PR #270 最新 `headRefOid` 的 `quality`、`android-build`、`ios-simulator-build` 均為 SUCCESS；結果以 GitHub PR metadata 為準。
- 同步前 PR quality job：396 tests passed。

## 4. 目前阻擋與完成條件

- PR #270 必須維持 Draft，直到 Draft 解除前人工驗收完成並取得批准。
- 未取得人工批准前不得解除 Draft或合併。
- 合併後才可把 Issue #268 能力移入 [`CURRENT_STATE.md`](CURRENT_STATE.md) 的 main 已完成功能。

## 5. 證據來源

- GitHub PR #270 metadata
- GitHub Actions run `30598884661`（同步前 Head）
- PR #270 GitHub metadata 的最新 `headRefOid` 與 checks
- PR #270 功能施工 commit `3ee2d53ebd96b3cf5150ee944d92a994841e344d`
- main commit `a214658fea5eda280a10d00ede292c2bf2fd3a86`

## 6. 更新規則

- PR Head、Draft 狀態、CI、阻擋或完成條件改變時，必須同步本文件。
- PR 合併或關閉後，必須在同一文件更新任務結果；若沒有進行中任務，明寫「目前沒有進行中的正式施工任務」。
- 本文件不得把 Draft 或 Open PR 描述成 main 已完成功能。
