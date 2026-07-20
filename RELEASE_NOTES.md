# Life Management v0.5.29 Release Candidate Notes

日期：2026-07-20

## 候選版內容

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

- 尚未宣告真實裝置舊來源匯入／唯讀預覽完成。
- Attachment 檔案內容尚未宣告可跨裝置備份／還原。
- v0.5.29 是 RC Preparation，不是 v1.0 正式產品版，也不代表正式 UI／UX 改版完成。
