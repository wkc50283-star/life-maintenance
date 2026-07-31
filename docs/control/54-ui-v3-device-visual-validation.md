# UI v3 真機視覺驗收 Gate

狀態：歷史 Gate 已完成；PR #242 已合併
目標版本：v0.5.41
適用 PR：#242
日期：2026-07-25
合併時間：2026-07-25
Merge commit：`1510feca6decf3cf315411486cf86ebfb2ed3a53`

本文件保存 PR #242 的歷史驗收證據，不是目前施工任務；目前任務以 [`CURRENT_TASK.md`](CURRENT_TASK.md) 為準。

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

## 3. 合併前 Gate（歷史）

PR #242 合併前要求下列條件全部滿足：

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

## 6. USB 真機驗收結果（2026-07-25）

驗收裝置與安裝內容：

- 真實 USB iPhone：`K.C的iPhone`，iPhone 12 Pro Max（iPhone13,4）。
- iOS 26.5（23F77），Developer Mode 已開啟，USB trust 與 Developer Disk Image 已確認。
- 安裝 commit：`2c17e4a`，Release bundle `com.example.lifeMaintenance`。
- 採覆蓋安裝，未解除安裝、未清除 App 或網站資料。
- 原始截圖由真機 XCUITest 的 `XCUIScreen.main.screenshot()` 直接輸出；每張皆為 1284×2778 PNG，未裁切、未修圖、未縮放。

正式標準字級截圖：

1. [生活總覽](../assets/ui/device/iphone-12-pro-max-428x926/01-life-overview.png)
2. [生活項目](../assets/ui/device/iphone-12-pro-max-428x926/02-items.png)
3. [新增首頁](../assets/ui/device/iphone-12-pro-max-428x926/03-add-home.png)
4. [新增生活項目 Step 1](../assets/ui/device/iphone-12-pro-max-428x926/04-add-item-step-1.png)
5. [新增生活項目 Step 2](../assets/ui/device/iphone-12-pro-max-428x926/05-add-item-step-2.png)
6. [項目詳情](../assets/ui/device/iphone-12-pro-max-428x926/06-item-detail.png)
7. [史略](../assets/ui/device/iphone-12-pro-max-428x926/07-history.png)
8. [設定](../assets/ui/device/iphone-12-pro-max-428x926/08-settings.png)

## 7. 真機流程與檢查結果

已在真機完成：

`新增分類 → 新增生活項目 → Step 1 → Step 2 → 儲存 → 返回生活項目列表確認出現 → 開啟 Item 詳情 → 返回首頁`

結果：

- 建立分類 `真機驗收分類` 成功。
- 建立生活項目、儲存、重讀列表與開啟詳情成功；Drift 資料可在後續獨立 XCUITest session 重讀。
- Step 1 鍵盤輸入後可操作「下一步」；底部操作列未被鍵盤遮住。
- 各頁狀態列、頂部 Safe Area、底部 Home Indicator／導覽列均完整保留。
- 標準字級未見文字截斷、水平 overflow、卡片互相覆蓋或不可捲動區域。
- 裝置原有大型 Dynamic Type 亦完成同一流程；未見 overflow，惟大型字級畫面只作 accessibility 壓力測試，不作核准參考圖的標準密度截圖。
- Motion 在真機切頁、按壓、表單步驟切換與返回流程中可正常完成；Reduce Motion 的 duration-zero 行為另由既有自動化 Gate 保護。
- 320×568 小螢幕與 200% 文字仍由既有 Widget Gate 驗證；本次實體裝置基線為董事長核准的 428×926pt。

## 8. 視覺問題與處置

本輪發現：

- 真機原始設定為大型 Dynamic Type，首輪截圖資訊密度明顯低於核准參考圖；已保留為大型字級壓力測試，正式逐頁比對改以同一真機的標準 Dynamic Type 測試啟動條件重拍，未修改或加工 PNG。
- `idevicescreenshot` 在 iOS 26.5 回覆 `Invalid service`；已改用 Apple XCUITest 原生截圖，不使用模擬器或桌面鏡像替代。
- 工作目錄的 `Runner.app` 帶有 `com.apple.FinderInfo`，簽章驗證拒絕；使用同 commit 的乾淨 `/tmp` source copy 建置並覆蓋安裝，沒有修改產品分支或降低簽章要求。

本輪不需修改功能、Domain、Schema、Migration、Repository、Drift 或資料流程。正式截圖的字級、密度、卡片比例、暖白／深藍／亮藍配色、操作層級及五入口已達本 PR 的董事長審查候選狀態；是否通過仍只由董事長逐頁簽核決定。

## 9. Gate 狀態

- USB 真機安裝：通過。
- 八張未加工原始真機截圖：完成。
- 分類與生活項目完整新增流程：通過。
- 標準 Dynamic Type 真機 XCUITest：通過。
- 大型 Dynamic Type 真機流程：通過，作 accessibility 補充證據。
- PR #242：已於 2026-07-25 合併。

本節為合併前 Gate 的歷史紀錄；PR #242 已合併，後續不得再將其列為 Draft 或目前阻擋。
