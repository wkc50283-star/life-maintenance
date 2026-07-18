from pathlib import Path

path = Path('lib/models/milestone.dart')
text = path.read_text(encoding='utf-8')
old = "  bool get isReached => status != MilestoneStatus.pending;\n"
new = """  bool get isReached =>
      reachedAt != null ||
      status == MilestoneStatus.reached ||
      status == MilestoneStatus.acknowledged ||
      status == MilestoneStatus.inProgress ||
      status == MilestoneStatus.completed;
"""
if text.count(old) != 1:
    raise SystemExit(f'Expected one milestone isReached definition, found {text.count(old)}')
path.write_text(text.replace(old, new), encoding='utf-8')

for file_name in (
    '.github/workflows/fix-milestone-reached.yml',
    'tool/fix_milestone_reached.py',
):
    file_path = Path(file_name)
    if not file_path.exists():
        raise SystemExit(f'Expected one-time file: {file_name}')
    file_path.unlink()
