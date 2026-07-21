# Life Management v0.5.33 Pages Drift Root Cause Fix Notes

日期：2026-07-21

## 本版內容

- 根因確認為既有 shared IndexedDB 已有 Schema v2 indexes，但 Drift creation path 再次執行非冪等 `CREATE INDEX`。
- creation path 改為建立既有 tables 後，以 `CREATE INDEX IF NOT EXISTS`／`CREATE UNIQUE INDEX IF NOT EXISTS` 建立同一組正式 indexes。
- 加入 release Web 可觀測的 Runtime 階段診斷與既有 index 防回歸測試。
- Drift 維持原 `life_maintenance` database name；不清除 IndexedDB、Local／Session Storage 或任何網站資料。
- GitHub Pages 對 `main.dart.js` 回應 `cache-control: max-age=600`；公開驗收須等待或確認新 bundle，不能以仍在有效期的舊 asset 判斷修正結果。

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
- Web release build 不註冊有版本的 Flutter Service Worker，只保留空白退出標記。
- GitHub Actions quality 與 Pages build／deploy 必須全綠。
- 公開 Pages 必須由最新版 `main` 顯示正式五入口 Runtime，並完成 Safari、Chrome、隔離／無痕與既有來源的持久化驗證。

## 已知限制

- iPhone／Android 實體裝置依本 PR 範圍延後，Device Validation Checklist 維持未簽核。
- Android 正式發佈簽章與 iOS distribution signing 尚未驗證，build artifact 不代表商店安裝資格。
- 尚未宣告真實裝置舊來源匯入／唯讀預覽完成。
- Attachment 檔案內容尚未宣告可跨裝置備份／還原。
- v0.5.33 是 Pages Drift 根因修正，不是 v1.0 正式產品版，也不代表實體裝置簽核或正式 UI／UX 改版完成。
