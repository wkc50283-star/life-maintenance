# Life Management v0.5.38 UI v2 Design System & Device UX Fixes

日期：2026-07-22

## 本版內容

- 建立集中式色彩、字級、間距、圓角、陰影、動畫 duration 與 curve Token。
- 建立共用主要按鈕、操作卡與精簡頁首，先套用於「新增」入口及正式表單，不全面改造其他頁面。
- 全新資料沒有分類時，生活項目表單可進入既有新增分類畫面，完成後回到原表單並可選擇分類。
- 多分類選單可操作，保存後仍由既有 FormalPlanningEditor 與 Drift Repository 建立正確 Item → Category 關聯。
- 表單儲存操作會隨鍵盤移到可見區域；拖動表單可收起鍵盤並捲至最後欄位。
- 表單內容與底部儲存操作承接手機 SafeArea。

## 明確邊界

- 不新增或刪除任何欄位、功能、資料表、API 或主導覽入口。
- 不修改 Domain、Schema、Migration、Repository、Runtime、產品邏輯或資料生命週期。
- Item 仍是 Root；Task 是提醒；WorkCase 是案件；WorkCaseClosure 是正式結案；History 是唯讀投影。
- 不加入遊戲化、評分、KPI、打卡或催促設計。

## 發佈驗證

- Widget Gate：空分類、分類切換與正式關聯、鍵盤、底部捲動、SafeArea。
- 320×568、200% 文字縮放，以及 390×844／360×800 手機尺寸。
- Drift codegen 無差異、Analyze、全部 tests、Web／Android／iOS build 與 GitHub Actions 全綠。

## 已知限制

- UI v2 只在新增入口與表單驗證，不代表其他頁面已全面改版。
- 平台 build 與自動化尺寸測試不等於 iPhone／Android 實體裝置人工簽核。
- v0.5.38 不是 v1.0 正式產品版。
