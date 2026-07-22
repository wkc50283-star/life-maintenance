# Life Management v0.5.40 UI v3 Foundation & Formal App Shell

日期：2026-07-23

## 本版內容

- 建立暖白背景、白色表面、深藍／亮藍主色與 success／warning／danger／info 狀態色。
- 統一 12～22pt 字級、8／12／16／24／32 間距、12～16 圓角、輕邊框及低陰影。
- 建立共用精簡頁首、底部導覽、表面／操作卡、主要／次要按鈕、表單欄位、狀態標籤及步驟指示器。
- Motion 統一為 120／180／260ms，系統開啟 Reduce Motion 時停用裝飾動畫。
- App Shell 移除重複的「生活管理／分頁名稱」AppBar，由各 Screen 原有頁首承接內容層級。
- 五個正式入口名稱、順序、Screen 與快速新增行為不變。

## 產品與資料邊界

- 已批准 PMS 視覺方案只作為美術品質標準，不引入 PMS 產品角色、文案或任務邏輯。
- Item 仍是 Root；Task 是提醒；WorkCase 是案件；WorkCaseClosure 是正式結案；History 是唯讀投影。
- 不修改 Domain、Schema、Migration、Repository、Runtime、資料流程、產品邏輯或各頁功能內容。
- 不新增遊戲化、完成率、KPI、打卡、催促設計或平行流程。

## 發佈驗證

- UI v3 Token 與九類共用元件 Gate。
- 五入口、320×568、390×844、200% 文字、SafeArea 與 Reduce Motion Gate。
- 既有 UI v2 表單、Shell、生活總覽與 Accessibility Gate 持續通過。
- Drift codegen 無差異、Analyze、全部 tests、Web／Android／iOS build 與 GitHub Actions 全綠。

## 已知限制

- 本版只將 UI v3 正式套用 App Shell，不代表各頁內容已全面改版。
- 平台 build 與自動化尺寸測試不等於 iPhone／Android 實體裝置人工簽核。
- v0.5.40 不是 v1.0 正式產品版。
