# Cross Platform Audit（PR #228）

狀態：正式控制文件
版本：v0.5.27
日期：2026-07-20

## 1. 範圍與結論

本次只稽核既有正式 Runtime 在 iPhone、iPad、Android、Web 與主要瀏覽器的啟動、版面、輸入、導覽、Drift 及主流程相容性。沒有修改 Schema、Migration、Domain、Repository contract 或產品功能。

確認兩項阻擋問題並完成最小修正：

1. 現有 iOS project 未完成目前 Flutter stable 所需的 UIScene／plugin Swift Package project update，且缺少可重現的 CocoaPods lockfile，首次 iOS build 無法通過。
2. `web/index.html` 缺少 viewport meta，行動瀏覽器可能用寬版 layout viewport 縮放正式畫面，造成字級與操作區失真。

## 2. 平台驗證矩陣

| 平台 | 驗證 | 結果 |
|---|---|---|
| iPhone | iPhone 16 Pro Simulator 安裝、啟動、Drift App sandbox、390×844 與 320×568 Widget Gate | 通過 |
| iPad | iPad Pro 11-inch Simulator 安裝、啟動、Drift App sandbox、1024×1366 Widget Gate | 通過 |
| Android | Android release APK、360×800 Widget Gate、AndroidX／Gradle stable compatibility | 通過 |
| Web | 正式 release build、worker／WASM、390×844 與 1366×768、中文輸入、導覽、Drift 寫入及 refresh persistence | 通過 |
| Chrome | 本機 Chrome 150 實際執行正式 release build；console 無 warning／error | 通過 |
| Safari | iPad Simulator Mobile Safari 18.6 實際載入正式 release build並檢查版面 | 通過 |
| Edge | 使用標準 viewport、Flutter release artifact、無 browser sniffing／專屬 storage API；與 Chromium 共用引擎路徑 | 相容 Gate 通過；未宣稱 Edge 實機 |
| Firefox | 使用 Flutter 標準 Web runtime、worker／WASM 相對資產、無 browser sniffing／專屬 storage API | 相容 Gate 通過；未宣稱 Firefox 實機 |

## 3. 原生平台修正

- iOS 使用 UIScene lifecycle 與 `FlutterImplicitEngineDelegate`，plugin 在 implicit engine 初始化後註冊。
- iPhone／iPad 維持同一 universal target，`TARGETED_DEVICE_FAMILY` 保持 `1,2`，iPad orientations 不縮減。
- Flutter generated plugin Swift Package 納入 Xcode project；既有非標準 Podfile 保留，並提交 `Podfile.lock` 使 CocoaPods sandbox 可重現。
- Android 保留 AndroidX，加入目前 Flutter migrator 要求的 built-in Kotlin／new DSL compatibility flags；不改 package id、SDK contract 或權限。

## 4. 版面、輸入與導覽 Gate

- 五個正式 App Shell 入口在 small iPhone、modern iPhone、Android phone、iPad portrait 與 desktop Web 尺寸逐一導覽。
- 320×568 且模擬 280 logical pixels 鍵盤時，分類 Unicode 輸入與正式儲存按鈕仍可操作，無 overflow／exception。
- Web 加入 `width=device-width, initial-scale=1.0`；不以裝置或 user-agent 分支 UI。
- iPhone、iPad、Chrome mobile／desktop、Mobile Safari 實際畫面均未出現截斷、底部遮擋或錯誤頁。

## 5. Drift 與完整主流程

- Native iOS App sandbox 建立成功；Android release 含 native SQLite runtime。
- Chrome 正式 release build 使用 `sqlite3.wasm` 與 `drift_worker.dart.js`，成功新增 Unicode Category，重新整理後資料仍存在。
- 既有完整 tests 持續涵蓋 Item／Category／Plan／Reminder／Milestone／Schedule、Task → WorkCase、多筆 Update、唯一 Closure 與 History Projection。
- 本 PR 不建立 browser-only Repository、測試資料庫入口或平行 persistence。

## 6. CI 與殘餘限制

- `quality` 持續執行 codegen、Analyze、全部 tests 與 Web release build。
- 新增 Android release APK job 與 macOS iOS Simulator universal build job。
- 本機未安裝 Edge／Firefox，無 Android AVD，且 iOS device release 未進行正式簽章；因此不宣稱這三項實機驗收。本 PR 以共同引擎／Web standards Gate、Android release artifact 與原生 Widget／Runtime 證據阻止已知相容回歸。
- 上述實機／簽章驗收若成為發行 admission requirement，必須在具備裝置、瀏覽器與 signing identity 的正式 release environment 執行；不得以本文件冒充實機結果。

## 7. 回復

本 PR 沒有資料變更，不需要資料 rollback。回復平台 project update、Podfile lock、Android compatibility flags、viewport、tests、workflow、文件與版本即可。任一平台 build、正式資料 Gate 或主流程測試失敗均不得合併。
