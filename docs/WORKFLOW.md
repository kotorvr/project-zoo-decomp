# Project Zoo workflow

The KOTOR VR / EchoQuestCombat setup (one orchestrator, an always-on planner, an auditor, workstream chats, kickoff prompts,
handoff files, several accounts launched from the CLI), cut down for a decompilation. `CLAUDE.md` is the short rule sheet;
the user's decisions are in `docs/PLAN.md`.

## 1. The chats

| chat | always on? | does | never does |
|---|---|---|---|
| **Orchestrator** ("Zoo orchestrator") | yes, one | talks to the user; starts, wakes and archives chats; owns `docs/PLAN.md` (status table, decisions, the user's answers verbatim with dates); verifies each report against the repo | write game code |
| **Planner** ("Zoo planner") | yes, one | turns a goal into a workstream: scope, owned files/units, acceptance test, kickoff prompt `docs/sessions/kickoff/<ID>.md`; picks the next decomp units by size and dependency; re-plans when a workstream finds the plan wrong | write game code, start chats |
| **Auditor** (AUD) | on demand | reviews a land before it counts: reads the diff, re-runs the claimed check (`objdiff` / `ninja` / `progress`), tries to break the claim | edit code (findings go to the owner via the orchestrator) |
| **Workstream chats** (`DC-<unit>`, `PORT-1`, `TOOL-1`, ...) | as many as the work needs | one goal each, in its own worktree + branch; match, build, land | touch files or units another workstream owns; talk to the user |

- Only the orchestrator starts chats, and only on the user's own words in a turn (a turn started by another session's message
  cannot start sessions). It queues the starts and asks the user for a one-word go.
- Models: each kickoff names its model. Opus for matching hard functions, engine design, the port layer and debugging;
  Sonnet for mechanical work (splitting, symbol naming sweeps, data-only units, docs).
- The orchestrator archives a chat once its work is committed (it checks the commit exists first).

## 2. Reporting (every chat, unasked)

`SendMessage` to "Zoo orchestrator". First line: who you are and what happened.
1. On start: id, what this chat does.
2. When blocked: what is blocked, what is needed. Questions for the user go ONLY through the orchestrator, which batches them,
   recommendation first.
3. On done: branch landed, the progress line before/after, evidence path, its `PLAN.md` row.
4. On handoff: the handoff file path.

Messages are events, not chatter: no acks.

## 3. Handoff at 300-400k context

At ~300k (never past 400k) a chat stops starting new work, commits, and writes `docs/sessions/handoff/<ID>_<date>.md`: role and
scope; branch and last commit; what is uncommitted and why; what is proven and with which command; next steps; open questions.
It messages the orchestrator, which starts a fresh chat on "follow docs/sessions/kickoff/<ID>.md, then the handoff file".
The orchestrator replaces itself the same way via `docs/sessions/ORCHESTRATOR.md`.

## 4. Files

| file | owner | what |
|---|---|---|
| `CLAUDE.md` | orchestrator | the rule sheet (~3 KB) |
| `docs/WORKFLOW.md` | orchestrator | this document |
| `docs/PLAN.md` | orchestrator | goals, phases, decisions, ONE status row per workstream |
| `docs/RESEARCH.md` | planner | platform choice, prior art, port feature research, sources |
| `docs/ROADMAP.md` | planner | the feature list for the PC port and VR, ranked |
| `docs/units.md` | planner | which translation unit / address range each workstream owns |
| `docs/sessions/kickoff/<ID>.md` | planner | the kickoff prompt; each stands alone |
| `docs/sessions/handoff/<ID>_<date>.md` | each chat | handoff files |
| `docs/sessions/logs/<ID>.md` | each chat | its work log (`Status:` line at the top) |

## 5. Decomp rules

- **No game data in git, ever.** The user supplies their own dumps in `orig/` (gitignored). No asset, executable, extracted
  file, disassembly dump of whole sections or copyrighted text goes into a commit, an issue, a PR, a log pasted to GitHub or a
  scratch on decomp.me beyond the single function being matched. CI builds from the user's files only, locally.
- **Ownership is by unit.** A workstream owns the translation units (source files / address ranges) listed for it in
  `docs/units.md`; it never edits another's. Shared headers are spliced by hunk, never rewritten whole.
- **A unit counts as matched only on the tools' verdict:** `objdiff` 100 % for each function, the full build's checksum equal
  to the original (`ninja` then the SHA-1 check), and the `progress` report line. Record the exact lines in the log. A check
  that was not run is NOT RUN.
- **Matching first, port second.** `src/` holds matching code only. Port changes (64-bit, renderer, input, fixes) live behind
  `#if PORT` / in `port/`, so the matching build never breaks.
- Worktree per workstream (`tools/launch` creates `D:\ZooTrees\<id>`); land = rebase on `main`, then
  `git -C <main> merge --ff-only <branch>`. Stage explicit paths; never `commit -a`, `add -A`/`.`, `stash`,
  `--amend` mid-rebase.
- Token habits: never `cat` a file over 50 KB (`grep -n`, then `sed -n`); long builds run detached to a file with an end marker;
  read verdict lines, never exit codes; kill only your own PIDs.

## 6. Several accounts and CLI launches

`tools/launch/` is KOTOR's copy of Echo's launcher (`tools/launch/README.md` there has the full detail). Spec lines
`Id|Title|Model|BriefPath[|main][|<account>]`; each chat gets its own console, worktree, `--remote-control` (shows on the
phone) and `CLAUDE_SECURESTORAGE_CONFIG_DIR` for its account. Mode defaults to `bypassPermissions` like Echo and KOTOR.

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\kaibo\Desktop\Recomp\Project Zoo\tools\launch\launch.ps1" -Spec C:\path\spec.txt -Account auto
python "C:\Users\kaibo\Desktop\Recomp\Project Zoo\tools\launch\accounts.py" status
```

- Accounts A, C, D, E (Max) and API1-3 (headless), shared with KOTOR and Echo: `accounts.py` reads all three projects'
  status-line dumps, so `-Account auto` picks the account with headroom that resets soonest.
- Never `/login`, `/logout` or `claude auth login` inside a chat (it overwrites account A).
- A chat keeps its account for life; its successor at a handoff is picked anew.
- Stop a chat only by its own PID from `Intermediate\launch\launched_sessions.log`.
- Echo's doc flags Anthropic's terms for running several accounts; the user decided this for Echo and KOTOR.
