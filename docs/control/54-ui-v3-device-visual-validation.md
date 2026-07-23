# UI v3 真機視覺驗收 Gate

狀態：施工中，維持 Draft，禁止合併
目標版本：v0.5.41
適用 PR：#242
日期：2026-07-23

## 1. 正式目的

本 PR 依董事長 2026-07-23 最新指示，在同一 Draft 內完成 UI v3 全站改版，涵蓋 App Shell、生活總覽、生活項目、新增流程、項目詳細、保養／提醒／案件、史略、設定與全站 Motion。以已批准參考圖為最低視覺標準，先用 428×926、390×844、320×568 自動化與模擬器預覽施工；USB 真機截圖與完整新增流程延後至最後一次總驗收。

自動化、模擬器、Web viewport、平台 build 與 CI 可作施工中的防回歸證據，但不得取代最後的 USB 真機截圖與董事長視覺簽核。

## 2. Admission 結果

截至 2026-07-23：

- 本機偵測到一台真實無線 iPhone：`K.C的iPhone`。
- 裝置型號為 iPhone 12 Pro Max（`iPhone13,4`），實體顯示為 1284×2778、3x，對應 428×926pt。
- 董事長已書面批准此 iPhone 12 Pro Max 的 428×926pt 作為正式替代基線；390×844 與 320×568 保留為自動化相容尺寸。
- 2026-07-24 董事長已提供核准參考圖，正式保存為 `docs/assets/ui/ui-v3-approved-reference.jpg`，並由 `docs/control/UI_CONSTITUTION.md` 定義最低視覺驗收標準。
- 已安裝 `libimobiledevice` 截圖工具，但無線 CoreDevice 裝置未出現在 `idevice_id -n -l`，目前不能以 `idevicescreenshot` 擷取真機畫面。
- Xcode CoreDevice 顯示裝置已配對、Developer Mode 開啟、DDI services 可用，具備安裝與啟動 App 的條件。

## 3. 目前禁止宣告

在下列條件全部滿足前，不得宣告 PR 完成或 squash merge：

1. 完成全站 UI v3 與所有指定頁面的一致性修正。
2. 428×926、390×844、320×568 自動化與模擬器 Gate 通過。
3. 建立可重複的 USB 真機截圖通道。
4. 擷取 App Shell 與五入口真機截圖，並完成分類→生活項目→儲存→列表出現流程。
5. 對每張截圖逐項記錄參考圖差異、修正與複驗結果。
6. codegen、Analyze、全部 tests、Web／Android／iOS build 與 GitHub CI 全綠。
7. 董事長明確回覆真機視覺驗收通過。

## 4. 範圍邊界

只允許 presentation layer 的全站 UI v3、Motion、視覺阻擋修正、截圖證據、對照紀錄、測試、版本及控制文件。必須保留所有功能、欄位與五入口；禁止修改 Domain、Schema、Migration、Repository、Runtime、資料流程、產品邏輯或建立平行流程。

## 5. 資料與回復

本 PR 不修改使用者資料。UI 與文件可由還原本 PR 回復；不得刪除或修改 Drift、SharedPreferences 或 `backup_v1_*` 資料。
