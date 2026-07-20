# Security Audit（PR #227）

狀態：正式控制文件
版本：v0.5.26
日期：2026-07-20

## 1. 範圍與結論

本次稽核 SQLite、Attachment、SharedPreferences 備份／回復／匯入、檔案路徑、平台與 CI 權限、敏感資訊及 crash recovery。只修正可由現有證據重現的阻擋性安全問題，不修改 UI、Schema、Migration、Domain 或產品功能。

確認三項阻擋問題並完成最小修正：

1. Attachment managed identifier 可接受 traversal、URI 與控制字元，未來 storage adapter 可能誤解為越界路徑或外部資源。
2. CI 下載 `sqlite3.wasm` 只驗證大小，遭置換的二進位仍可能進入 Web build。
3. GitHub Pages workflow 將 Pages write 與 OIDC token 權限授予 build job，超出建置所需權限。

## 2. 安全驗證矩陣

| 範圍 | 正式安全邊界 | 結果 |
|---|---|---|
| SQLite | Drift／bound variables 保存輸入；FK、integrity、transaction 與 crash recovery Gate 持續通過 | 通過 |
| Attachment | 新 identifier 拒絕絕對路徑、traversal、反斜線、任何 URI scheme、encoded separator、query／fragment 與控制字元 | 修正後通過 |
| Repository bypass | Runtime 與底層 Attachment Repository 都執行相同 identifier 安全限制 | 修正後通過 |
| 備份 | 只建立 `backup_v1_*`、不可覆寫；平台拒絕寫入即失敗 | 通過 |
| 回復 | 不自動切回 Legacy writer；保留來源及備份作人工受控證據 | 通過 |
| 匯入 | dry-run、SHA-256／byte length、來源凍結、單一 transaction、重跑與完整性驗證 | 通過 |
| 敏感資訊 | production／delivery text 無常見 private key、GitHub、AWS 或 Google credential pattern | 通過 |
| 平台權限 | Android release 無 `uses-permission`；iOS 無敏感 UsageDescription；macOS release 只有 App Sandbox | 通過 |
| CI 權限 | quality 只讀；Pages build 只有 contents／Pages read；Pages write／OIDC 只存在 deploy job | 修正後通過 |
| Web SQLite | sqlite3 3.4.0 WASM 必須符合 pinned SHA-256，錯誤內容不得寫入 | 修正後通過 |

## 3. Attachment 路徑政策

正式 Runtime 只保存 stable managed identifier，不操作平台實體路徑。新寫入會拒絕：

- Unix、Windows、UNC 絕對路徑及任何反斜線。
- `.`／`..` path segment 及 `%2e`、`%2f`、`%5c` encoded path token。
- `file:`、`content:`、`ph:`、HTTP 或其他任何 URI scheme，不分 scheme 大小寫。
- query、fragment、NUL 與其他控制字元。

Legacy importer 仍依既有正式 mapping 將舊路徑轉成 `legacy-unverified:{SHA-256}`，只保存為未知來源證據；本 PR 不改 migration mapping 或既有資料。

## 4. SQLite、備份與 crash recovery

- Repository 寫入與查詢使用 Drift bound variables；hostile SQL-like text 只作資料保存，不會執行。
- `foreign_keys`、`foreign_key_check`、`integrity_check`、transaction rollback 及檔案 DB close／reopen Gate 沿用 PR #225 並在完整測試重跑。
- SharedPreferences 與 `backup_v1_*` 不是正式 Runtime source；不雙寫、不刪除、不覆蓋。
- 匯入及回復失敗留在 Drift 安全狀態，不自動恢復 Legacy writer。

## 5. 供應鏈與權限

- `sqlite3.wasm` 下載完成後先比對 SHA-256，再寫入 `web/`；錯誤檔案不覆蓋既有資產。
- quality workflow 只取得 `contents: read`。
- Pages build job 只有 `contents: read` 與 configure-pages 所需的 `pages: read`；只有 deploy job 取得 `pages: write` 與 `id-token: write`。
- 正式 Android、iOS、macOS manifest 未宣告目前功能不需要的相機、照片、檔案、定位、網路或其他敏感權限。

## 6. 殘餘風險與回復

- SQLite 依賴平台 App Sandbox／裝置資料保護，本版本未新增資料庫加密。若未來提供跨裝置同步、匯出或高敏感健康／財務內容，必須另立單一安全設計 PR，不得在本稽核擅自新增加密層或金鑰管理。
- Legacy note 依既有控制文件保留未驗證來源識別作回復證據，正式 UI 不顯示 storage identifier 或平台路徑；本 PR 不改匯入 mapping。
- GitHub Actions 仍依批准的 major-version action references；若治理要求 immutable action SHA，需另立 supply-chain policy PR 統一管理更新機制。
- GitHub API 回報本 repository 尚未啟用 Dependabot alerts，且目前 CLI token 無 secret-scanning alert 讀取權限；本次以套件解析 advisory 查詢及 repository 靜態 secret Gate 驗證，不宣稱已涵蓋 GitHub 平台警示。啟用 repository security settings 屬外部治理變更，需另行明確授權。

回復本 PR 不需要資料 rollback；還原 identifier 驗證、WASM digest、workflow 權限、tests、文件與版本即可。任一安全 Gate 失敗均不得合併或發布。
