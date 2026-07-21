# Life Management v0.5.35 Attachment Metadata Integrity Validation Notes

日期：2026-07-21

## 本版內容

- 完成 item、maintenanceRecord、workCaseUpdate、workCaseClosure、milestone 五種既有 Attachment Owner 驗收。
- 驗證完整 metadata 建立、ID 查詢、Owner 查詢與不同 Owner 隔離。
- 驗證 available、missing、重新驗證 available 與 deleted metadata lifecycle。
- Runtime 與 Repository 同時拒絕空白、平台 path、traversal、encoded separator、URI、query／fragment 與控制字元。
- 不存在／unknown Owner、重複 ID 與非法 lifecycle 時間失敗後不留部分資料，原 metadata 保持不變。
- 既有 production Runtime 通過驗收，沒有為測試修改或弱化正式邏輯。

## 明確邊界

- WorkCase 不是目前的 Attachment Owner；案件附件只依既有模型附屬於 WorkCaseUpdate 或 WorkCaseClosure。
- `recordStorageDeleted`／`deleted` 只代表 storage 已由外部確認後保存的 metadata 事實，本版沒有操作平台實體檔案。
- 本版沒有實體檔案新增、讀取、預覽、刪除、孤兒檔清理、storage adapter、相簿、分享或雲端功能。
- UI、Domain、Schema、Migration、Runtime 與 Repository contract 均未修改。

## 發佈驗證

- Drift codegen 必須無差異。
- Flutter Analyze 與全部 tests 必須通過。
- Web／Android／iOS build 與 GitHub Actions 必須全綠。
- PR 與文件不得把 metadata 驗收冒充實體檔案能力。

## 已知限制

- Attachment 實體檔案 storage lifecycle 仍待未來明確授權與獨立設計。
- iPhone／Android 實體裝置仍依 Device Validation Checklist 個別簽核；平台 build 不等於真機完成。
- v0.5.35 不是 v1.0 正式產品版，也不代表正式 UI／UX 改版完成。
