# tools/launch: CLI chats for Project Zoo

A copy of KOTOR's `tools/launch/` (itself EchoQuestCombat's `tools/w24/` lane launcher), 2026-10-27. Full detail on accounts,
the account check and stopping chats: `C:\Users\kaibo\Desktop\KOTOR\tools\launch\README.md`.

Changes from KOTOR:
- worktrees go to `D:\ZooTrees\<id>`
- `accounts.py` also reads KOTOR's status-line dumps, so Zoo, KOTOR and Echo pick accounts from the same usage
- `tools/worktree.py setup` only junctions the shared `orig/` and `tools/bin/` into the worktree; there is no Unity copy

Spec file (outside the repo), one chat per line: `Id|Title|Model|BriefPath[|main][|A|C|D|E|API1|API2|API3]`

```
PLANNER|Zoo planner|claude-opus-5-5|C:\Users\kaibo\Desktop\Recomp\Project Zoo\docs\sessions\kickoff\PLANNER.md|main
SETUP-1|SETUP-1: matching build skeleton|claude-opus-5-5|C:\Users\kaibo\Desktop\Recomp\Project Zoo\docs\sessions\kickoff\SETUP-1.md
```
```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\kaibo\Desktop\Recomp\Project Zoo\tools\launch\launch.ps1" -Spec C:\path\spec.txt -Account auto
python "C:\Users\kaibo\Desktop\Recomp\Project Zoo\tools\launch\accounts.py" status
```
