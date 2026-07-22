# Life Management v0.5.39 App Shell & Life Overview UI v2 Motion

日期：2026-07-22

## 本版內容

- 將既有 UI v2 色彩、字級、間距、圓角與表面層級套用至正式 App Shell 與生活總覽。
- 五個正式入口維持生活總覽、生活項目、新增、史略、設定，名稱、順序、功能與對應畫面不變。
- 首頁 TodayHero、區塊標題、提醒／案件／重點／完成卡片及空狀態建立一致視覺層級。
- 新增「快速新增」操作，只切換至既有「新增」入口，不建立新的寫入或資料流程。
- Tab 使用淡入與輕移，首頁區塊加入進場，卡片與按鈕加入按壓回饋；duration 為 160～280ms。
- 系統啟用減少動態效果時，Tab、區塊與按壓裝飾動畫歸零。

## 明確邊界

- 不修改 Domain、Schema、Migration、Repository、Runtime、資料、產品邏輯或正式生命週期。
- Item 仍是 Root；Task 是提醒；WorkCase 是案件；WorkCaseClosure 是正式結案；History 是唯讀投影。
- 不全面改造生活項目、新增、史略或設定頁內容。
- 不新增遊戲化、評分、KPI、打卡、循環獎勵或焦慮效果。

## 發佈驗證

- Widget Gate：五入口、快速新增、Tab／區塊／卡片／按鈕 Motion、減少動態效果。
- 320×568、200% 文字縮放可完整捲動生活總覽。
- 既有 Shell、生活總覽 Drift 真實資料、Accessibility 與 UI v2 表單測試持續通過。
- Drift codegen 無差異、Analyze、全部 tests、Web／Android／iOS build 與 GitHub Actions全綠。

## 已知限制

- 本版只處理 App Shell 與生活總覽，不代表其他頁面已全面改版。
- 平台 build 與自動化尺寸測試不等於 iPhone／Android 實體裝置人工簽核。
- v0.5.39 不是 v1.0 正式產品版。
