# 生活管理 App 目前正式任務

狀態：正式控制文件
最後核對日期：2026-08-02

## 1. 目前任務狀態

目前進行中的正式施工任務：

- 任務名稱：一分鐘建立頁簡化
- Branch：`codex/simplify-one-minute-item-creation`
- Base commit：`435156d2eeedac381552b549fec4c643125dc3c7`
- 目標版本：`0.5.54+55`
- 狀態：施工中，尚未合併
- 目標：簡化 Issue #268 已存在的建立表單，不修改資料契約與生命週期。

最近完成任務：

- Issue：#268
- 任務名稱：一分鐘建立生活項目並自動產生第一筆史略
- PR：#270
- PR URL：<https://github.com/wkc50283-star/life-maintenance/pull/270>
- Branch：`issue-268-one-minute-item-creation`
- Base commit：`a214658fea5eda280a10d00ede292c2bf2fd3a86`
- Head commit：`aa5e26b5d17b0a14ffe7fefa020aebba65a53633`
- Merge commit：`7a2f4c35e5211d4fea9f83a185867c1bc6a4d149`
- PR 狀態：CLOSED、Merged、已進入 main
- App version：`0.5.53+54`

## 2. Issue #268 完成內容

- 「＋新增」開啟拍照／語音／輸入 bottom sheet。
- 拍照與語音誠實顯示尚未啟用，不寫入正式資料。
- 輸入流程以名稱、分類與管理週期建立 Item。
- 只呼叫正式 `ItemCreationRuntime.create()`，自然建立唯一 created lifecycle event。
- 成功畫面、ItemDetail 與全域 History 承接 `ItemCreatedHistoryEntry`。
- 完整範圍以 main 內的 `docs/control/issues/issue-268-one-minute-item-creation.md` 為準。

## 3. 驗證狀態

- PR #270 合併前 Head `aa5e26b5d17b0a14ffe7fefa020aebba65a53633` 的 GitHub Actions run `30647489700` 完成且成功。
- `quality`：SUCCESS。
- `android-build`：SUCCESS。
- `ios-simulator-build`：SUCCESS。
- PR 說明記錄：`flutter test` 396 tests passed，Web build、Android debug APK build、iOS debug no-codesign build PASS。

## 4. 尚未完成的驗收與限制

- iPhone 實體裝置人工驗收尚未在本文件中記錄為完成。
- Android 實體裝置人工驗收尚未在本文件中記錄為完成。
- 拍照、語音與 AI 自動填欄位不屬於 Issue #268 已完成功能。
- 下一個功能 PR 施工前，必須先建立新的 CURRENT_TASK 條目並明確批准範圍。

## 5. 本任務完成條件

1. 新建 Item 表單明確呈現必填名稱、選填單一分類與可 0／1／多選的六種管理週期。
2. 小螢幕、鍵盤開啟與 200% 文字下主要按鈕可見且可點擊。
3. 只透過 `ItemCreationRuntime.create()` 新建，保留 Loading、錯誤處理、防重複送出、成功承接與唯一 created event。
4. Format、Analyze、全部 Flutter tests、Web／Android／iOS build gates 通過。
5. Draft PR 建立後維持 Draft，等待人工驗收，不自行合併。

## 6. 證據來源

- GitHub PR #270 metadata
- GitHub Actions run `30647489700`
- PR #270 Head commit `aa5e26b5d17b0a14ffe7fefa020aebba65a53633`
- PR #270 merge commit `7a2f4c35e5211d4fea9f83a185867c1bc6a4d149`
- main `pubspec.yaml`
- main `docs/control/issues/issue-268-one-minute-item-creation.md`

## 7. 更新規則

- 有新的正式施工任務時，必須在動工前更新本文件。
- PR Head、Draft 狀態、CI、阻擋或完成條件改變時，必須同步本文件。
- PR 合併或關閉後，必須在同一文件更新任務結果；若沒有進行中任務，明寫「目前沒有進行中的正式施工任務」。
- 本文件不得把 Draft 或 Open PR 描述成 main 已完成功能。
