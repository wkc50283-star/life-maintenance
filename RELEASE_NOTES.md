# Life Management v0.5.37 Accessibility & Beta UI Readiness Notes

日期：2026-07-21

## 本版內容

- 驗證 320×568 小型畫面與 200% 文字縮放下，正式五入口可閱讀且沒有 overflow。
- 修正生活總覽狀態標籤在大型文字下的水平溢位。
- 為設定安全界線與首頁提醒卡補上明確按鈕語意、可聚焦互動及鍵盤啟用。
- 驗證正式底部導覽觸控高度至少 48dp。
- 以防回歸 Gate 驗證核心內文 4.5:1、非文字圖示 3:1 的最低對比。

## 明確邊界

- 沒有重做美術、改變 UI 功能或新增產品功能。
- Domain、Schema、Migration、Runtime、Repository 與正式資料生命週期均未修改。
- Item 仍是 Root；Task 是提醒；WorkCase 是案件；WorkCaseClosure 是正式結案；History 是唯讀投影。

## 發佈驗證

- Drift codegen 必須無差異。
- Flutter Analyze、全部 tests、Web／Android／iOS build 與 GitHub Actions 必須全綠。
- Web 另以正式 build 驗證 Tab 焦點、Enter 啟用與五入口操作。

## 已知限制

- 平台 build 與自動化語意測試不等於實體裝置上的 VoiceOver／TalkBack 人工簽核；真機仍依 Device Validation Checklist 執行。
- v0.5.37 不是 v1.0 正式產品版。
