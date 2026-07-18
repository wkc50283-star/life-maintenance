from pathlib import Path


def replace_exact(path_name: str, old: str, new: str) -> None:
    path = Path(path_name)
    text = path.read_text(encoding='utf-8')
    if text.count(old) != 1:
        raise RuntimeError(f'{path_name}: expected one exact target')
    path.write_text(text.replace(old, new), encoding='utf-8')


replace_exact(
    'docs/control/09-core-data-roles.md',
    '狀態：正式控制文件候選  ',
    '狀態：正式控制文件  ',
)
replace_exact(
    'docs/control/09-core-data-roles.md',
    '- `safetyNotice`\n- `status`',
    '- `safetyNotice`\n- `steps`（建立時保存的使用者步驟快照）\n- `status`',
)
replace_exact(
    'docs/control/09-core-data-roles.md',
    'Schedule 可以屬於：\n\n- MaintenancePlan：週期性保養項目\n- Item：一般到期提醒或日期事項\n\n因此正式 schema 不得只留下模糊的 `cardId`。需建立明確來源角色，例如：\n\n- `sourceType = maintenancePlan | generalReminder`\n- `sourceId`\n\n或使用可被資料庫完整約束的等效設計。',
    'Schedule 可以屬於：\n\n- MaintenancePlan：週期性保養項目\n- Item：一般到期提醒或日期事項\n- Milestone：達標後需要形成提醒的階段性重點\n\n因此正式 schema 不得只留下模糊的 `cardId`。來源必須依 `ScheduleSourceReference` 與來源一致性契約表示，不得用空字串假裝外鍵，也不得讓多種來源同時存在。',
)
replace_exact(
    'docs/control/09-core-data-roles.md',
    '- `strictPeriodMode`',
    '- `anchorPolicy`（正式預設為 `fixedCalendarPeriod`）',
)

readme = Path('README.md')
text = readme.read_text(encoding='utf-8')
anchor = '9. [核心資料角色修正案](docs/control/09-core-data-roles.md)\n'
addition = anchor + '''10. [修正版 Drift schema v2 設計](docs/control/10-corrected-schema-v2-design.md)
11. [地基缺口修正計畫](docs/control/11-foundation-gap-corrections.md)
12. [生活項目類別策略](docs/control/12-item-category-strategy.md)
13. [正式產品名詞表](docs/control/13-product-terminology.md)

`docs/control/` 內標示為「正式控制文件」的文件共同生效，不再以固定「六份文件」限制控制範圍。
'''
if text.count(anchor) != 1 or '10. [修正版 Drift schema v2 設計]' in text:
    raise RuntimeError('README control document list is not in expected state')
text = text.replace(anchor, addition)
rule = '- Schedule 不得代替 MaintenancePlan。'
if text.count(rule) != 1:
    raise RuntimeError('README rule anchor missing')
text = text.replace(
    rule,
    rule + '\n- 「限－工程」只是假名；正式介面依情境使用突發事項、工程／修繕或辦理事項，底層使用 WorkCase。',
)
readme.write_text(text, encoding='utf-8')
