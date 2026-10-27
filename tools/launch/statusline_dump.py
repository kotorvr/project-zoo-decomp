"""statusLine command for CLI chats started by tools/launch/launch.ps1 (copied from EchoQuestCombat
tools/night/statusline_dump.py, LAUNCH-1 2026-10-25; LAUNCH-2 adds seven_day_resets_at).

Each chat gets a per-session statusLine (its own --settings file; nothing global changes) that runs:

    <python> tools/launch/statusline_dump.py <out_dir>

Claude Code pipes the status JSON on stdin. This writes the fields the planner's usage tick needs to
<out_dir>/<session_id>.json (atomic replace) and prints one short status line. rate_limits appears only on Pro/Max
plans and only after the session's first API response; missing fields are written as null.
"""
import json
import os
import re
import sys
import time


def pick(d, *path):
    for k in path:
        if not isinstance(d, dict):
            return None
        d = d.get(k)
    return d


def record(data):
    return {
        "t": int(time.time()),
        "session_id": data.get("session_id"),
        "session_name": data.get("session_name"),
        "cwd": pick(data, "workspace", "current_dir") or data.get("cwd"),
        "model": pick(data, "model", "id"),
        "five_hour_pct": pick(data, "rate_limits", "five_hour", "used_percentage"),
        "five_hour_resets_at": pick(data, "rate_limits", "five_hour", "resets_at"),
        "seven_day_pct": pick(data, "rate_limits", "seven_day", "used_percentage"),
        # LAUNCH-2: the weekly reset names the account (accounts.py check)
        "seven_day_resets_at": pick(data, "rate_limits", "seven_day", "resets_at"),
        "ctx_pct": pick(data, "context_window", "used_percentage"),
        "ctx_size": pick(data, "context_window", "context_window_size"),
    }


def main(argv):
    if len(argv) != 2:
        print("usage: statusline_dump.py <out_dir>")
        return 2
    out_dir = argv[1]
    try:
        data = json.loads(sys.stdin.read() or "{}")
    except ValueError:
        print("sl: bad json")
        return 0
    if not isinstance(data, dict):
        print("sl: bad json")
        return 0
    rec = record(data)
    # the session id names the file: keep it to a safe file name
    sid = re.sub(r"[^0-9A-Za-z_.-]", "_", str(rec["session_id"] or "unknown"))[:80] or "unknown"
    os.makedirs(out_dir, exist_ok=True)
    final = os.path.join(out_dir, sid + ".json")
    tmp = final + ".tmp"
    with open(tmp, "w", encoding="utf-8", newline="\n") as f:
        json.dump(rec, f)
    os.replace(tmp, final)
    print("5h %s%% wk %s%% ctx %s%%" % (rec["five_hour_pct"], rec["seven_day_pct"], rec["ctx_pct"]))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
