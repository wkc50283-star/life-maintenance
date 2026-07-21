# Life Management v0.5.36 History Experience Validation Notes

日期：2026-07-21

## 本版內容

- 驗收正式「史略」入口的 Loading、Empty、Error 與 Retry 狀態，載入完成前不誤顯示空資料，失敗後可重新讀取正式投影。
- 驗證 History 事件依正式發生時間倒序排列，相同時間以穩定來源 ID 排序。
- 驗證 Item、Task、WorkCase、多筆 WorkCaseUpdate 與唯一 WorkCaseClosure 的投影關係一致，不重複或補造事實。
- 驗證 History 查詢前後正式來源資料列完全不變，持續維持唯讀架構。
- 以檔案 Drift database 關閉再重開，確認冷啟動後案件過程、結案與史略結果一致。
- 既有 production Runtime 通過驗收，沒有需要修改正式程式碼的阻擋問題。

## 明確邊界

- History 仍是由正式資料即時組合的唯讀投影，不提供 create、save、update 或 delete。
- Task 仍只是提醒；WorkCase 才是案件；WorkCaseClosure 才是正式結案。
- 本版沒有新增 History table、cache、writer、平行來源或產品功能。
- UI 設計、Domain、Schema、Migration、Runtime 與 Repository contract 均未修改。

## 發佈驗證

- Drift codegen 必須無差異。
- Flutter Analyze 與全部 tests 必須通過。
- Web／Android／iOS build 與 GitHub Actions 必須全綠。
- PR 與文件不得把 metadata 驗收冒充實體檔案能力。

## 已知限制

- 本版驗收既有史略體驗，不是正式 UI／UX 重畫。
- iPhone／Android 實體裝置仍依 Device Validation Checklist 個別簽核；平台 build 不等於真機完成。
- v0.5.36 不是 v1.0 正式產品版。
