from __future__ import annotations

from pathlib import Path


def replace_exact(
    path_name: str,
    old: str,
    new: str,
    expected: int = 1,
) -> None:
    path = Path(path_name)
    text = path.read_text(encoding="utf-8")
    count = text.count(old)
    if count != expected:
        raise RuntimeError(
            f"{path_name}: expected {expected} occurrences of {old!r}, found {count}"
        )
    path.write_text(text.replace(old, new), encoding="utf-8")


def update_today_identity() -> None:
    replace_exact(
        "lib/widgets/today_hero.dart",
        "Icons.verified_user_outlined",
        "Icons.home_outlined",
    )

    version_badge = """              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'v0.14.0',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
"""
    replace_exact("lib/widgets/today_hero.dart", version_badge, "")
    replace_exact(
        "lib/widgets/today_hero.dart",
        "            '軍規邏輯，民用保養',",
        "            '管理生活項目、提醒與處理紀錄',",
    )


def update_settings() -> None:
    version_card = """    _SettingCardData(
      title: '版本資訊',
      content: 'v0.14.0',
      icon: Icons.info_outline,
      highlighted: false,
    ),
"""
    replace_exact("lib/screens/settings_screen.dart", version_card, "")
    replace_exact(
        "lib/widgets/settings_header.dart",
        "            '本機資料、安全界線與版本資訊。',",
        "            '本機資料與安全界線。',",
    )


def update_metadata() -> None:
    replace_exact(
        "pubspec.yaml",
        'description: "A new Flutter project."',
        'description: "A Flutter app for managing life items, reminders, maintenance, and records."',
    )


def update_tests() -> None:
    replace_exact(
        "test/widget_test.dart",
        "    expect(find.text('v0.14.0'), findsOneWidget);\n"
        "    expect(find.text('v0.9.0'), findsNothing);\n",
        "    expect(find.text('管理生活項目、提醒與處理紀錄'), findsOneWidget);\n"
        "    expect(find.text('軍規邏輯，民用保養'), findsNothing);\n"
        "    expect(find.text('v0.14.0'), findsNothing);\n"
        "    expect(find.text('v0.9.0'), findsNothing);\n",
    )
    replace_exact(
        "test/honest_ui_test.dart",
        "    expect(find.text('版本資訊'), findsOneWidget);\n"
        "    expect(find.text('v0.14.0'), findsOneWidget);\n",
        "    expect(find.text('版本資訊'), findsNothing);\n"
        "    expect(find.text('v0.14.0'), findsNothing);\n",
    )


def update_change_log() -> None:
    path = Path("docs/control/06-change-log.md")
    text = path.read_text(encoding="utf-8")

    pending = "- squash commit 待合併後補記"
    if text.count(pending) != 1:
        raise RuntimeError(
            f"Expected one pending LM-009 commit entry, found {text.count(pending)}"
        )
    text = text.replace(
        pending,
        "- squash commit `7d2b27b7039453712d729471c3a518491d3a981b`",
    )

    marker = "---\n\n## 後續條目模板"
    if text.count(marker) != 1:
        raise RuntimeError(
            f"Expected one change-log template marker, found {text.count(marker)}"
        )

    entry = """---

## LM-010：移除舊定位與不可信的畫面版號

日期：2026-07-18  
類型：文案／產品治理

### 問題

首頁仍顯示「軍規邏輯，民用保養」，無法涵蓋目前的生活項目、提醒、證件、合約與完整處理紀錄。畫面另外手寫 `v0.14.0`，但 `pubspec.yaml` 建置版本為 `1.0.0+1`，repo 尚未建立唯一版本來源與正式發版規則，因此使用者看到的版號並不可信。

### 修改

- 首頁副標改為「管理生活項目、提醒與處理紀錄」。
- 首頁盾牌圖示改為一般生活管理圖示。
- 移除首頁手寫 `v0.14.0` 徽章。
- 移除設定頁手寫的版本資訊卡。
- 修正 `pubspec.yaml` 的 Flutter 範本描述，改為本 App 的實際用途。
- 更新測試，防止「軍規邏輯，民用保養」與舊手寫版號再次出現在一般畫面。

### 明確未修改

- 不更改 App 名稱「生活維護管家」。
- 不擅自猜測或建立新的公開版本號。
- 不修改 `pubspec.yaml` 的建置版本。
- 不修改任何資料、提醒、排程或紀錄功能。
- 不重做首頁版面與配色。

### 資料影響

無。

### 後續版本原則

未來若要重新顯示版本資訊，必須先建立單一可信來源，讓建置版本、設定頁、首頁與發版紀錄一致，不得再於多個 Widget 手寫不同版號。

### 驗收

- 一般畫面不再出現「軍規邏輯，民用保養」。
- 一般畫面不再出現手寫 `v0.14.0` 或 `v0.9.0`。
- 首頁直接說明生活管理用途。
- `flutter analyze`、`flutter test` 與 Web release build 全部通過後才合併。

### 批准

依產品憲法的直接、誠實與不製造假功能原則執行。

### PR／commit

- PR #172
- squash commit 待合併後補記

---

## 後續條目模板"""
    path.write_text(text.replace(marker, entry), encoding="utf-8")


def remove_one_time_files() -> None:
    for file_name in (
        ".github/workflows/remove-legacy-branding.yml",
        "tool/remove_legacy_branding.py",
    ):
        path = Path(file_name)
        if not path.exists():
            raise RuntimeError(f"Expected one-time file to exist: {file_name}")
        path.unlink()


def main() -> None:
    update_today_identity()
    update_settings()
    update_metadata()
    update_tests()
    update_change_log()
    remove_one_time_files()


if __name__ == "__main__":
    main()
