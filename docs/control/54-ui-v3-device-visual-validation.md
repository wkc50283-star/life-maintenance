# UI v3 真機視覺驗收 Gate

狀態：阻擋中，禁止合併
目標版本：v0.5.41
適用 PR：#242
日期：2026-07-23

## 1. 正式目的

本 PR 只補做 UI v3 的 iPhone 真機視覺驗收與必要阻擋修正。必須以已批准參考圖為最低標準，在 390×844 iPhone 逐頁驗收 App Shell、生活總覽、生活項目、新增、史略、設定、字級、間距、卡片比例、底部導覽、SafeArea 與第一屏觀感。

不得以 Widget test、模擬器、Web viewport、平台 build 或 CI 綠燈取代真機截圖與董事長視覺簽核。

## 2. Admission 結果

截至 2026-07-23：

- 本機偵測到一台真實無線 iPhone：`K.C的iPhone`。
- 裝置型號為 iPhone 12 Pro Max（`iPhone13,4`），實體顯示為 1284×2778、3x，對應 428×926pt。
- 此裝置不符合本 PR 指定的 390×844 iPhone 基線。
- repo 內未找到已批准參考圖；僅有 App icon 與 launch image。
- 已安裝 `libimobiledevice` 截圖工具，但無線 CoreDevice 裝置未出現在 `idevice_id -n -l`，目前不能以 `idevicescreenshot` 擷取真機畫面。
- Xcode CoreDevice 顯示裝置已配對、Developer Mode 開啟、DDI services 可用，具備安裝與啟動 App 的條件。

## 3. 目前禁止宣告

在下列條件全部滿足前，不得宣告 PR 完成或 squash merge：

1. 提供已批准參考圖原檔或可逐項檢查的正式附件。
2. 連接 390×844 iPhone，或由董事長明確書面批准 428×926 iPhone 12 Pro Max 作為替代基線。
3. 建立可重複的真機截圖通道。
4. 擷取五入口與 App Shell 的真機截圖。
5. 對每張截圖逐項記錄參考圖差異、修正與複驗結果。
6. codegen、Analyze、全部 tests、Web／Android／iOS build 與 GitHub CI 全綠。
7. 董事長明確回覆真機視覺驗收通過。

## 4. 範圍邊界

只允許真機視覺阻擋修正、截圖證據、對照紀錄、測試、版本及控制文件。禁止修改 Domain、Schema、Migration、Repository、Runtime、資料流程、產品邏輯、功能、欄位或建立平行流程。

## 5. 資料與回復

Admission 階段不修改程式、版本或使用者資料。本文件可直接還原；不得刪除或修改 Drift、SharedPreferences 或 `backup_v1_*` 資料。
