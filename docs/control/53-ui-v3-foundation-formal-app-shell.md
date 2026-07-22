# UI v3 Foundation 與正式 App Shell Gate

狀態：正式控制文件
版本：v0.5.40
PR：#241

## 1. 視覺來源與產品邊界

已批准的「PMS App 全新視覺設計方案」只作為視覺品質最低標準，包括暖白表面、深藍／亮藍層級、精簡導覽與低噪音元件。不得採用 PMS 產品定位、文案、任務中心、績效、完成率或任何領域角色。

本產品仍是 Life Management App。Item 是 Root；Task 只是提醒；WorkCase 是正式案件；WorkCaseClosure 是正式結案；History 是唯讀投影。

## 2. UI v3 Token

- 色彩：暖白背景、白色表面、深藍主要文字／操作、亮藍焦點／選取，以及 success／warning／danger／info 狀態色與低彩度表面。
- 字級：12／14／16／18／22pt。
- 間距：8／12／16／24／32。
- 圓角：控制項 12、卡片及主要表面 16。
- 表面：1px 輕邊框及低強度藍灰陰影。
- Motion：120／180／260ms，系統要求 Reduce Motion 時裝飾動畫歸零。

## 3. 正式共用元件

- `UiCompactPageHeader`
- `UiBottomNavigation`
- `UiSurfaceCard`／`UiActionCard`
- `UiPrimaryButton`／`UiSecondaryButton`
- `UiFormField`
- `UiStatusTag`
- `UiStepIndicator`
- `UiMotionEntrance`／`UiPressFeedback`

本 PR 只建立元件基礎，不代表所有頁面已套用或改版。

## 4. App Shell

- 五入口仍為生活總覽、生活項目、新增、史略、設定，名稱、順序及 Screen 不變。
- 移除 Shell 額外顯示的「生活管理／分頁名稱」雙層 AppBar；每個 Screen 仍顯示原有正式頁首。
- 正式 Shell 只建立一個 `UiBottomNavigation`，不新增 route、資料存取或平行導覽。
- Shell body 與底部導覽分別承接 SafeArea。

## 5. 明確不修改

不修改各頁內容、Domain、Schema、Migration、Repository、Runtime、資料流程、產品邏輯、功能、欄位、API、資料表或下一個 PR。

## 6. 驗收

- UI v3 Token 與所有共用元件可獨立渲染。
- Shell 不存在重複 AppBar 或「生活管理」品牌副標。
- NavigationBar 僅有五個正式入口，名稱、順序及 Screen 不變。
- 320×568、390×844、200% 文字與左右／底部 SafeArea 無 overflow 或遮擋。
- Reduce Motion 時 Shell、按壓與步驟動畫歸零。
- 深藍主要按鈕與白字、一般文字及非文字圖示通過既有對比 Gate。
- codegen、Analyze、全部 tests、Web／Android／iOS build 與 GitHub Actions 全綠。

## 7. 回復

本 PR 不改資料。回復只需還原 Token、Theme、共用元件、Shell、測試、版本與文件；不得刪除或修改 Drift、SharedPreferences 或 `backup_v1_*` 資料。
