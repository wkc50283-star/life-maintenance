# App Shell＋生活總覽 UI v2＋第一階段 Motion Gate

狀態：正式控制文件
版本：v0.5.39
PR：#240

## 1. 範圍

本 PR 只將既有 UI v2 Design System 套用至正式 App Shell 與生活總覽。五個入口名稱、順序、對應 Screen、Composition Root、資料來源、查詢、寫入與正式生命週期全部不變。

## 2. App Shell

- 正式入口仍為生活總覽、生活項目、新增、史略、設定。
- 頁首以生活管理品牌層與目前入口建立清楚層級。
- 底部 NavigationBar 加入 UI v2 表面、邊界與低強度陰影。
- Tab 切換只使用淡入與 2.5% 水平輕移，不建立新 route 或平行導覽。

## 3. 生活總覽

- TodayHero 繼續顯示今日提醒、進行中案件與階段性重點的正式數量。
- 今日提醒、進行中案件、階段性重點與最近完成維持既有 Drift／Runtime／History Projection 資料角色與排序。
- 空狀態使用平靜圖示與文字，不加入催促、評分、完成率或焦慮倒數。
- 快速新增只切換至既有第三個「新增」入口，不建立新的新增流程或 writer。

## 4. 第一階段 Motion

- quick：160ms，用於卡片與按鈕按壓回饋。
- standard：220ms，用於 Tab 與一般區塊進場。
- emphasized：280ms，用於後續首頁區塊進場。
- 動畫只使用既有 UI v2 curve；沒有循環、獎勵、遊戲化或焦慮效果。
- `MediaQuery.disableAnimations` 為 true 時，Tab、按壓與區塊裝飾動畫 duration 必須歸零。

## 5. 資料與產品邊界

Task 仍只是提醒；WorkCase 才是案件；WorkCaseClosure 才是正式結案；History 仍是唯讀投影。Item 仍是所有生活資料的 Root。本 PR 不修改 Domain、Schema、Migration、Repository、Runtime、產品邏輯或資料。

## 6. 驗收

- 五入口名稱、順序與對應 Screen 不變，快速新增抵達既有 AddScreen。
- Tab、區塊、卡片與按鈕動畫均在 150～300ms。
- 減少動態效果時裝飾動畫歸零。
- 320×568、200% 文字縮放可捲動到所有生活總覽區塊，沒有 overflow 或例外。
- 既有 Shell、生活總覽真實資料、Accessibility 與 UI v2 表單 Gate 持續通過。
- codegen、Analyze、全部 tests、Web／Android／iOS build 與 GitHub Actions 全綠。

## 7. 回復

本 PR 不改資料。回復只需還原 Shell／生活總覽樣式、Motion 元件、測試、版本與文件；不得刪除或修改任何 Drift、SharedPreferences 或 `backup_v1_*` 資料。
