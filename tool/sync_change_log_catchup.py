from pathlib import Path

path = Path('docs/control/06-change-log.md')
text = path.read_text(encoding='utf-8')

pending = '- PR #176\n- squash commit 待合併後補記'
if text.count(pending) != 1:
    raise RuntimeError('Expected one pending PR #176 entry')
text = text.replace(
    pending,
    '- PR #176\n- squash commit `6c3ff4fdf1de5a8d08c50b56189465493c0177a9`',
)

rows = [
    (15, '建立案件 Repository 邊界', 177, '43d3442b7543c69d7c5628a78a6bcb3dae9f6d24', '建立案件查詢、模型轉換與原子寫入邊界。', '不接 UI、不建立全域資料庫、不遷移 SharedPreferences。'),
    (16, '建立只讀遷移準備盤點', 178, 'ed90a0a0e5b546e3bbbc82c09a4fbbfc796071e0', '盤點四組來源、不可變備份與 Drift 目標表狀態。', '不修復、不補備份、不匯入，也不呼叫儲存或刪除。'),
    (17, '建立舊資料關聯稽核', 179, 'f3cfd329c717a0f753ff20a8a704a7eee5b1a255', '檢查逐筆解析、重複 ID 與斷裂關聯。', '不修復舊資料、不寫入 Drift、不接 UI。'),
    (18, '建立遷移准入閘門', 180, '99a492132459dcf61417ede2cab4182f97e4aaf6', '整合備份、解析、重複 ID、關聯與目標表狀態。', '通過准入不代表匯入，本批次沒有寫入能力。'),
    (19, '鎖定舊資料遷移範圍', 181, 'db97c41a38dbcbb34b476131ea2c6d4b05eeb12b', '確認 schema v1 尚無舊四組資料的合法目標表。', '不新增 schema、不建立 mapper、不執行轉換預演。'),
    (20, '正式標示 v0.5.0 Foundation', 182, '35c097fdd02302d595739a71b6c2733c64f89ca6', '建立三碼版本唯一來源與版本規則。', '不在 Widget 手寫版號，不修改功能或資料格式。'),
    (21, '正式分離保養項目與模板／排程／案件', 183, 'b0b840bfff04d352b5c24e2c421df3662e79548c', '補回 MaintenancePlan 正式角色，禁止 Schedule 代替保養項目。', '不修改資料庫、不接 UI、不搬移舊資料。'),
    (22, '建立 MaintenancePlan 模型基線', 184, 'cab5af9d5e5f23bbffb5162f43c6ac83f2c8572e', '建立可序列化並保存步驟快照的保養項目模型。', '不建立 Repository、Drift table 或 UI。'),
    (23, '建立地基缺口修正計畫', 186, 'e0e9d7fe406a9e50c2f6393d10258d6686823eac', '正式阻擋缺少 Milestone、週期基準、結案與附件等角色的 schema v2 草稿。', 'PR #185 維持 Draft，不開始 schema v2 程式施工。'),
    (24, '建立 Milestone／大修模型基線', 187, 'f5a40777130d8116882c0d77f9c128e89fddc56d', '承接第六年大修、里程、次數、日期與人生階段等條件。', '不接 Drift、Repository、UI 或舊資料。'),
    (25, '正式生活項目類別策略', 188, 'c3ad904bc26e56586497b83e49b2eba00a1baa55', '採系統大類加使用者自訂名稱，避免產品被限縮為設備維護。', '不修改 Item 模型、資料庫或既有分類。'),
    (26, '建立固定週期基準策略', 189, '39c43874f5f5cd5f1d1915d90bb5bac58bd553fc', '建立日不移日、週不移週等固定曆期計算基線。', '不修改舊 Schedule、任務完成流程或既有排程。'),
    (27, '建立正式案件結案模型', 190, 'ec640244a60124941a30e85aaabf606cbb79d1aa', '將案件生命週期、處理過程與人工確認的正式結案摘要分離。', '不修改 WorkCase／WorkCaseUpdate、不接 Drift 或 UI。'),
    (28, '建立 Schedule／Task 來源一致性契約', 191, '494b32a200c672bf02260778c71544258aa748fa', '禁止空字串假外鍵、來源矛盾與跨生活項目錯配。', '不修改舊 Schedule／Task、不建立資料表或遷移。'),
    (29, '建立附件／照片生命週期模型', 192, '0be21cd8ebb3b17ea37addf886a1121cee62a086', '補上附件所有權、檔案狀態、遺失與刪除生命週期。', '不搬動現有照片、不接檔案系統、Drift 或 UI。'),
]

parts = []
for number, title, pr, commit, change, unchanged in rows:
    parts.append(f'''## LM-{number:03d}：{title}

日期：2026-07-18  
類型：架構／資料／治理

### 問題與原因

{change}

### 修改

依 PR #{pr} 的核准範圍完成對應模型、服務、測試或控制文件。

### 明確未修改

{unchanged}

### 資料影響

無既有使用者資料寫入、刪除或遷移。

### 驗收結果

Drift code generation、Analyze、全部測試、Web release build 與 Drift Web 資產驗證均通過。

### 批准狀態

已依產品憲法、資料安全與最小變更原則批准並合併。

### PR／commit

- PR #{pr}
- squash commit `{commit}`
''')

marker = '---\n\n## 後續條目模板'
if text.count(marker) != 1:
    raise RuntimeError('Expected one change-log template marker')
insertion = '---\n\n' + '\n---\n\n'.join(parts) + '\n---\n\n## 後續條目模板'
path.write_text(text.replace(marker, insertion), encoding='utf-8')
