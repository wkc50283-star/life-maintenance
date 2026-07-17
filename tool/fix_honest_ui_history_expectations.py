from __future__ import annotations

from pathlib import Path


def main() -> None:
    test_path = Path("test/history_screen_test.dart")
    text = test_path.read_text(encoding="utf-8")

    old_block = """    expect(find.text('任務 ID'), findsOneWidget);
    expect(find.text('task-new'), findsOneWidget);
"""
    new_block = """    expect(find.text('任務 ID'), findsNothing);
    expect(find.text('task-new'), findsNothing);
"""

    count = text.count(old_block)
    if count != 1:
        raise RuntimeError(
            f"Expected exactly one stale internal-ID expectation block, found {count}"
        )

    test_path.write_text(text.replace(old_block, new_block), encoding="utf-8")

    one_time_files = (
        ".github/workflows/capture-honest-ui-failure.yml",
        ".github/trigger-honest-ui-diagnostic.txt",
        "diagnostics/honest-ui-test-failure.txt",
        "tool/fix_honest_ui_history_expectations.py",
    )
    for file_name in one_time_files:
        path = Path(file_name)
        if not path.exists():
            raise RuntimeError(f"Expected one-time file to exist: {file_name}")
        path.unlink()


if __name__ == "__main__":
    main()
