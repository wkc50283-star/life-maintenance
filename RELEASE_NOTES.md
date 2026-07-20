# Life Management v0.5.30 Device Validation Baseline Notes

日期：2026-07-20

## 本版內容

- 建立正式真機驗收基線與可重跑 Checklist。
- 驗收範圍涵蓋安裝、原地升級、冷啟動、背景切換、強制關閉重啟、資料持久化與版本升級相容。
- 新增平台識別、Drift 檔案完整重啟、foreign key 與 SQLite integrity 防回歸 Gate；OS 背景切換仍由真機 Checklist 驗收。
- 明確禁止以 simulator、artifact build 或 CI 冒充實體裝置通過。
- iPhone Simulator 已完成安裝、強制終止與再次冷啟動；Android APK 與 iOS Simulator App build 通過。

## RC 基礎

- 正式五入口 App Shell：生活總覽、生活項目、新增、史略、設定。
- Drift Schema v2 為唯一正式 Runtime 資料來源；Legacy 僅保留唯讀匯入與災難回復證據。
- Item、Plan、Reminder、Milestone、Schedule、Task、WorkCase、Update、Closure、MaintenanceRecord、Attachment 與 History Projection 正式流程。
- Task 保持提醒角色；需要處理過程的事件走 WorkCase → WorkCaseClosure；History 不獨立寫入。
- #221～#229 架構、品質、UI、產品憲法、資料完整性、效能、安全、跨平台與真實使用 Gate。
- GitHub Pages 改為部署最新版 `main` 的正式 Flutter Web，而非 review-only prototype。

## 發佈驗證

- Drift codegen 無差異。
- Flutter Analyze 與全部 tests 通過。
- Web release、Android release APK、iOS Simulator build 通過。
- GitHub Actions quality／Android／iOS 與 Pages build／deploy 全綠。
- 公開 Pages 在 Chrome、Safari 與隔離／無痕情境顯示正式五入口 Runtime，無舊樣板、fixture 或 console error。

## 已知限制

- PR #231 施工環境沒有可用的 iOS／Android 實體裝置；實體裝置 Checklist 維持未簽核。
- Android 正式發佈簽章與 iOS distribution signing 尚未驗證，build artifact 不代表商店安裝資格。
- 尚未宣告真實裝置舊來源匯入／唯讀預覽完成。
- Attachment 檔案內容尚未宣告可跨裝置備份／還原。
- v0.5.30 是 Device Validation Baseline，不是 v1.0 正式產品版，也不代表實體裝置簽核或正式 UI／UX 改版完成。
