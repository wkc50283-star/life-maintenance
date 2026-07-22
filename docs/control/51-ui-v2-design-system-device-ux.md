# UI v2 Design System 與真機阻擋 UX Gate

狀態：正式控制文件
版本：v0.5.38
PR：#239

## 1. 範圍

本 PR 建立集中式 UI v2 Token 與三種共用元件，並只在「新增」入口及正式規劃表單驗證。阻擋修正限定為生活項目分類操作、鍵盤遮住儲存、長表單無法到達底部及 SafeArea。

不得以本 PR 為由全面改造其他頁面，也不修改任何功能、欄位、Domain、Schema、Migration、Repository、Runtime、產品邏輯或資料生命週期。

## 2. 正式 Token

- `UiColors`：畫布、表面、主色、文字、邊框與選取狀態。
- `UiType`：頁首、說明、卡片標題、內文與按鈕。
- `UiSpace`：4／8／12／16／20／24／32 間距尺度。
- `UiRadius`：控制項、卡片、主視覺與 pill。
- `UiShadow`：低強度卡片陰影。
- `UiMotion`：quick／standard／emphasized duration 與正式 curve。

## 3. 共用元件

- `UiPrimaryButton`：至少 54dp 高、支援 loading 與 disabled。
- `UiActionCard`：Material 點擊、裁切與明確語意。
- `UiCompactPageHeader`：精簡標題與白話說明。

## 4. 阻擋問題與修正

| 問題 | 根因 | 最小修正 |
|---|---|---|
| 新增 Item 時分類無法操作 | 全新 Drift 沒有 Category，表單只顯示空下拉選單 | 顯示誠實空狀態並進入既有 CategoryForm；成功後重載同一正式 Repository |
| 鍵盤遮住儲存 | 底部 SafeArea 未納入 `viewInsets.bottom` | 底部操作以 Token 動畫跟隨鍵盤 inset |
| 表單無法捲到底部 | 鍵盤與固定底部操作壓縮可視範圍，無明確 scroll Gate | 保留單一 ListView、支援拖動收鍵盤並驗證最後欄位可到達 |
| SafeArea | 表單 body 只依賴 Scaffold，未明確承接橫向安全區 | body 與底部操作分別承接 SafeArea |

## 5. 資料邊界

分類仍由既有 `CategoryFormScreen` → `FormalPlanningEditor.saveCategory` → Drift Repository 寫入；生活項目仍由既有 `saveItem` 寫入。沒有雙寫、備援來源、平行流程、Schema／Migration 或資料搬移。

## 6. 驗收矩陣

- 空資料：可建立第一個分類並返回生活項目表單。
- 多分類：可選擇第二分類，保存後 `categoryId` 正確。
- 鍵盤：320×568、bottom inset 280 時儲存鍵完整位於鍵盤上方。
- 捲動：鍵盤開啟時最後「備註」欄位仍可到達。
- 文字：320×568、200% 縮放無 overflow／例外。
- SafeArea：390×844 與 360×800、左右及底部系統區域不遮擋內容。
- codegen、Analyze、全部 tests、Web／Android／iOS build、預覽與 CI 全綠。

## 7. 回復

本 PR 不改資料。回復只需還原 Token、共用元件、表單版面、測試、版本與文件；不得刪除或修改任何 Drift／SharedPreferences／`backup_v1_*` 資料。
