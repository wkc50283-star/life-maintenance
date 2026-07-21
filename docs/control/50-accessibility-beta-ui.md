# Accessibility 與 Beta 前介面 Gate

狀態：正式控制文件
版本：v0.5.37
PR：#238

## 範圍

本 Gate 只驗收既有正式畫面的阻擋性可用性：Dynamic Type／文字縮放、VoiceOver／TalkBack 語意、48dp 觸控範圍、對比、焦點順序與鍵盤操作。不新增功能、不重做美術，不修改 Domain、Schema 或 Migration。

## 驗收矩陣

| 項目 | Gate | 結果 |
|---|---|---|
| 文字縮放 | 320×568、200% 依序開啟五個正式入口，無 overflow／例外 | 通過 |
| 螢幕閱讀器 | 可操作卡片具明確中文 label、button role 與 tap action | 通過 |
| 觸控範圍 | 正式底部五入口高度至少 48dp | 通過 |
| 對比 | 一般文字至少 4.5:1；大型非文字圖示至少 3:1 | 通過 |
| 焦點／鍵盤 | 設定操作可由 Tab 聚焦並以 Enter 啟用 | 通過 |

## 阻擋問題與最小修正

- 首頁狀態標籤在 200% 文字縮放與窄畫面會水平溢位：讓標籤文字在既有膠囊內彈性換行。
- 設定安全界線與首頁提醒卡使用裸手勢，缺少可靠按鈕語意與鍵盤焦點：改用 Material 焦點互動，加入明確語意 label、button role 與 semantic tap action。

## 資料與回復

本 PR 不讀寫、搬移或刪除正式資料，沒有 Schema／Migration、匯入或資料格式變更。回復只需還原本 PR 的 Widget、測試、版本與文件變更。

## 不得宣稱

- 自動化測試與平台 build 不等於 VoiceOver／TalkBack 實體裝置人工驗收。
- 本次不是 UI 重畫、功能新增或 v1.0 正式產品驗收。
