from __future__ import annotations

from pathlib import Path


EXACT_REPLACEMENTS: dict[str, list[tuple[str, str]]] = {
    "lib/main.dart": [
        (
            "final List<String> _titles = const ['今日', '物品', '新增', '履歷', '設定'];",
            "final List<String> _titles = const ['今日', '我的項目', '新增', '履歷', '設定'];",
        ),
        ("label: '物品',", "label: '我的項目',"),
    ],
    "lib/screens/add_screen.dart": [
        ("'你想記住什麼？'", "'你要新增什麼？'"),
        (
            "'先建立一個名稱、提醒或紀錄，讓需要承接的事不再散落在腦中。'",
            "'新增生活項目、提醒或完成紀錄，方便之後查看與管理。'",
        ),
        ("title: '先放著'", "title: '新增生活項目'"),
        (
            "description: '建立一個可追蹤的名稱，先把責任收進來。'",
            "description: '建立家電、車輛、房屋、證件或其他生活項目。'",
        ),
        ("title: '需要你記住的事'", "title: '新增提醒'"),
        (
            "description: '到期日、保固、證件、合約或其他提醒。'",
            "description: '設定到期日、保固、證件、合約或其他日期提醒。'",
        ),
        ("title: '完成紀錄'", "title: '補登完成紀錄'"),
        (
            "description: '記下處理過什麼、花多少錢、結果如何。'",
            "description: '記錄已完成的保養、修理、辦理事項、費用與結果。'",
        ),
    ],
    "lib/widgets/add_item_preview_sheet.dart": [
        ("content: Text('請輸入項目名稱')", "content: Text('請輸入生活項目名稱')"),
        ("'先放著'", "'新增生活項目'"),
        (
            "'先留下名稱，需要時再回來補充或安排。'",
            "'先填寫名稱，其他資料可以之後補充。'",
        ),
        ("label: '項目名稱'", "label: '生活項目名稱'"),
        ("content: Text('已先放著')", "content: Text('已新增生活項目')"),
    ],
    "lib/widgets/expiry_reminder_preview_sheet.dart": [
        ("content: Text('請選擇項目')", "content: Text('請選擇生活項目')"),
        ("content: Text('需要你記住的事已儲存')", "content: Text('提醒已儲存')"),
        ("'需要你記住的事'", "'新增提醒'"),
        (
            "'記下到期日、保固、證件、合約等需要留意的時間，完成後會儲存到本機。'",
            "'設定到期日、保固、證件、合約或其他需要留意的日期。'",
        ),
        ("label: '事項名稱'", "label: '提醒名稱'"),
    ],
    "lib/widgets/maintenance_record_preview_sheet.dart": [
        ("content: Text('請選擇項目')", "content: Text('請選擇生活項目')"),
        (
            "Text(\n            '完成紀錄',",
            "Text(\n            '補登完成紀錄',",
        ),
        (
            "'記下已完成的處理內容、費用與備註，按下儲存後會保存到本機。'",
            "'記錄已完成的保養、修理、辦理事項、費用與結果。'",
        ),
    ],
    "lib/widgets/preview_form_fields.dart": [
        ("_previewInputDecoration('選擇物品')", "_previewInputDecoration('選擇生活項目')"),
        (
            "hint: Text(isDisabled ? '請先建立「先放著」項目' : '請選擇物品')",
            "hint: Text(isDisabled ? '請先新增生活項目' : '請選擇生活項目')",
        ),
    ],
    "lib/widgets/items_header.dart": [
        (
            "'一個項目，一組提醒，一份長期紀錄。'",
            "'集中管理家電、車輛、房屋、證件與其他生活內容。'",
        ),
    ],
    "lib/screens/items_screen.dart": [
        ("'目前還沒有項目。'", "'目前還沒有生活項目。'"),
        ("title: '項目詳情'", "title: '生活項目詳情'"),
    ],
    "lib/widgets/reminder_list_sheet.dart": [
        (
            "Text(\n            '需要你記住的事',",
            "Text(\n            '提醒與到期事項',",
        ),
        ("'目前沒有需要你記住的事'", "'目前沒有已建立的提醒'"),
        ("'事項詳情'", "'提醒詳情'"),
        ("'事項名稱'", "'提醒名稱'"),
        ("'所屬項目：$itemName'", "'所屬生活項目：$itemName'"),
        ("label: '所屬項目'", "label: '所屬生活項目'"),
        ("return '項目不存在';", "return '生活項目不存在';"),
    ],
    "test/widget_test.dart": [
        ("expect(find.text('物品'), findsOneWidget);", "expect(find.text('我的項目'), findsWidgets);"),
    ],
}

GLOBAL_TERMINOLOGY = {
    "需要你記住的事": "提醒事項",
    "先放著": "新增生活項目",
    "物品": "生活項目",
}

FORBIDDEN_ACTIVE_TERMS = (
    "需要你記住的事",
    "先放著",
    "承接",
    "責任收進來",
    "物品",
)


def replace_exact(path: Path, replacements: list[tuple[str, str]]) -> None:
    text = path.read_text(encoding="utf-8")
    for old, new in replacements:
        count = text.count(old)
        if count == 0:
            raise RuntimeError(f"Expected wording not found in {path}: {old!r}")
        text = text.replace(old, new)
    path.write_text(text, encoding="utf-8")


def apply_global_terminology(root: Path) -> None:
    for path in sorted(root.rglob("*.dart")):
        text = path.read_text(encoding="utf-8")
        updated = text
        for old, new in GLOBAL_TERMINOLOGY.items():
            updated = updated.replace(old, new)
        if updated != text:
            path.write_text(updated, encoding="utf-8")


def audit_active_wording(root: Path) -> None:
    issues: list[str] = []
    for path in sorted(root.rglob("*.dart")):
        text = path.read_text(encoding="utf-8")
        for term in FORBIDDEN_ACTIVE_TERMS:
            if term in text:
                issues.append(f"{path}: still contains {term!r}")
    if issues:
        raise RuntimeError("PMS-era wording remains:\n" + "\n".join(issues))


def main() -> None:
    for relative_path, replacements in EXACT_REPLACEMENTS.items():
        replace_exact(Path(relative_path), replacements)

    apply_global_terminology(Path("lib"))
    apply_global_terminology(Path("test"))
    audit_active_wording(Path("lib"))


if __name__ == "__main__":
    main()
