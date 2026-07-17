from __future__ import annotations

from pathlib import Path


def replace_exact(path_name: str, old: str, new: str, expected: int = 1) -> None:
    path = Path(path_name)
    text = path.read_text(encoding="utf-8")
    count = text.count(old)
    if count != expected:
        raise RuntimeError(
            f"{path_name}: expected {expected} occurrences of {old!r}, found {count}"
        )
    path.write_text(text.replace(old, new), encoding="utf-8")


def update_item_dropdown() -> None:
    replace_exact(
        "lib/widgets/preview_form_fields.dart",
        "import '../data/mock_data.dart';\n",
        "",
    )
    replace_exact(
        "lib/widgets/preview_form_fields.dart",
        "    this.onChanged,\n    this.allowMockFallback = true,\n",
        "    this.onChanged,\n",
    )
    replace_exact(
        "lib/widgets/preview_form_fields.dart",
        "  final ValueChanged<String?>? onChanged;\n  final bool allowMockFallback;\n",
        "  final ValueChanged<String?>? onChanged;\n",
    )
    replace_exact(
        "lib/widgets/preview_form_fields.dart",
        "    final localItems = _localItems;\n"
        "    final items = localItems == null || localItems.isEmpty\n"
        "        ? widget.allowMockFallback\n"
        "              ? MockData.items\n"
        "              : const <Item>[]\n"
        "        : localItems;\n"
        "    final isDisabled = !widget.allowMockFallback && items.isEmpty;\n",
        "    final items = _localItems ?? const <Item>[];\n"
        "    final isDisabled = items.isEmpty;\n",
    )

    for path_name in (
        "lib/widgets/expiry_reminder_preview_sheet.dart",
        "lib/widgets/maintenance_record_preview_sheet.dart",
    ):
        replace_exact(
            path_name,
            "            allowMockFallback: false,\n",
            "",
        )


def update_change_log() -> None:
    path = Path("docs/control/06-change-log.md")
    text = path.read_text(encoding="utf-8")

    old_bullet = "- 刪除包含假生活項目、排程、任務與履歷的 `mock_data.dart`。\n"
    new_bullets = (
        "- 刪除包含假生活項目、排程、任務與履歷的 `mock_data.dart`。\n"
        "- 生活項目下拉選單只讀本機真實項目；沒有資料時保持停用，不再支援假資料 fallback。\n"
    )
    if text.count(old_bullet) != 1:
        raise RuntimeError(
            f"Expected one LM-011 mock-data deletion bullet, found {text.count(old_bullet)}"
        )
    text = text.replace(old_bullet, new_bullets)

    old_acceptance = "- repo 不再存在 `MockData` 或 `mock_data.dart`。\n"
    new_acceptance = (
        "- repo 不再存在 `MockData` 或 `mock_data.dart`。\n"
        "- 新增提醒與補登紀錄表單不會在缺少真實項目時顯示假選項。\n"
    )
    if text.count(old_acceptance) != 1:
        raise RuntimeError(
            f"Expected one LM-011 acceptance bullet, found {text.count(old_acceptance)}"
        )
    path.write_text(text.replace(old_acceptance, new_acceptance), encoding="utf-8")


def remove_one_time_files() -> None:
    for file_name in (
        ".github/workflows/capture-catalog-analyze.yml",
        ".github/trigger-catalog-analyze.txt",
        "diagnostics/catalog-analyze-failure.txt",
        "tool/remove_mock_item_fallback.py",
    ):
        path = Path(file_name)
        if not path.exists():
            raise RuntimeError(f"Expected one-time file to exist: {file_name}")
        path.unlink()


def main() -> None:
    update_item_dropdown()
    update_change_log()
    remove_one_time_files()


if __name__ == "__main__":
    main()
