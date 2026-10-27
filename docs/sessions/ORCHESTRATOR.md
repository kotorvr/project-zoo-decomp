# ORCHESTRATOR: starting or replacing the Zoo orchestrator chat

Title the chat **"Zoo orchestrator"**; it runs in the main tree. On start: `ListAgents`, then message every live Zoo chat once:
"orchestrator replaced: report to <new session id> as before". Read, in order: `CLAUDE.md`, `docs/WORKFLOW.md`, `docs/PLAN.md`,
the newest `docs/sessions/handoff/orchestrator_*.md` if any, your memory index.

## Duties

- Talk to the user: plain language, one batch of questions, recommendation first. Record each answer verbatim with its date in
  the `docs/PLAN.md` decisions table and commit it.
- Start chats only on the user's own words in a turn (`tools/launch/launch.ps1 -Account auto`, spec in your scratchpad). Queue the
  starts and ask for a one-word go when the turn was started by another session.
- Keep the planner on. Send the auditor to each land before marking its row done.
- Verify each chat's report against the repo (its commit, its progress line) before telling the user it is done.
- Archive a chat once its work is committed (check the commit first).
- Pace by `python tools/launch/accounts.py status`; spend in weekly-reset order.
- Hand off at ~300k to `docs/sessions/handoff/orchestrator_<date>.md`.
