"""Project Zoo copy (2026-10-27) of KOTOR's accounts.py: it also reads KOTOR's dumps, since Zoo, KOTOR and
Echo all spend the same accounts.

Account picker and per-launch account check for tools/launch (LAUNCH-2, 2026-10-25; Echo's multi-account setup).

    python tools/launch/accounts.py status            one line per account: weekly %, 5-hour %, next weekly reset
    python tools/launch/accounts.py pick              prints the account to launch on (last line: PICK <acct>)
    python tools/launch/accounts.py check <acct> <claude pid> [--wait S]
                                                      ACCOUNT CHECK OK / FAILED for a launched chat

Usage data = the newest status-line dump per account, from BOTH projects (they draw on the same accounts):
KOTOR <main>/Intermediate/launch/sl_<x>/ (A also the LAUNCH-1 dir sl/) and Echo's artifacts/planner/sl_<x>/ (A = sl/).
A dump older than the account's last weekly reset counts as 0 % weekly; a 5-hour window whose resets_at has passed counts
as 0 %. Rules (the user's, from Echo): spend in weekly-reset order (the account that resets soonest first), skip an account
at its 5-hour limit (move to the one with headroom), every account may run to 100 % weekly,
but a NEW chat starts only below WEEKLY_MAX (95 %) since it keeps its account for life. API1-3 (headless, no limits
in the status line) are picked only when no subscription account has headroom.

The check: claude.exe writes <home>/.claude/sessions/<pid>.json (sessionId); the chat's status line writes
sl_<acct>/<sessionId>.json. seven_day_resets_at must fall on the account's own weekly reset (RESETS, UTC: A Tue 07,
C Wed 09, D Sat 00, E Sun 16). If claude.exe ever drops CLAUDE_SECURESTORAGE_CONFIG_DIR, a C/D/E chat runs on A and
shows A's reset: FAILED.
"""
import datetime as dt
import glob
import json
import os
import subprocess
import sys
import time

HOME = os.path.expanduser("~")
ECHO_PLANNER = r"C:\Users\kaibo\Desktop\Echo\EchoQuestCombat\artifacts\planner"
KOTOR_LAUNCH = r"C:\Users\kaibo\Desktop\KOTOR\Intermediate\launch"
# weekly resets in UTC, weekday Mon=0, hour. The user gave them in UK summer time (Echo memory account-logins-abcd, 10-16:
# A Tue 08, C Wed 10, D Sat 01, E Sun 17 BST); they are fixed instants, so from 2026-10-25 (GMT) they read an hour earlier
# on the PC clock. Measured: LAUNCH-T2 on D, seven_day_resets_at = Sat 2026-10-31 00:00 UTC.
# E measured 2026-10-25: two E chats' own dumps read seven_day_resets_at = Sun 17:00 UTC (not 16)
RESETS = {"A": (1, 7), "C": (2, 9), "D": (5, 0), "E": (6, 17)}
UTC = dt.timezone.utc
SUBS = ["A", "C", "D", "E"]
APIS = ["API1", "API2", "API3"]
WEEKLY_MAX = 95   # at or above: no headroom (a chat keeps its account for life, so it must start with room)
FIVE_MAX = 95


def main_tree():
    out = subprocess.check_output(["git", "-C", os.path.dirname(os.path.abspath(__file__)), "rev-parse",
                                   "--path-format=absolute", "--git-common-dir"], text=True).strip()
    return os.path.dirname(out)


def acct_dir(acct):
    return os.path.join(HOME, ".claude") if acct == "A" else os.path.join(HOME, ".claude-" + acct.lower())


def sl_dirs(acct):
    k = os.path.join(main_tree(), "Intermediate", "launch")
    x = acct.lower()
    dirs = [os.path.join(k, "sl_" + x), os.path.join(ECHO_PLANNER, "sl_" + x), os.path.join(KOTOR_LAUNCH, "sl_" + x)]
    if acct == "A":
        dirs += [os.path.join(k, "sl"), os.path.join(ECHO_PLANNER, "sl"), os.path.join(KOTOR_LAUNCH, "sl")]
    return dirs


def last_reset(acct, now, weeks=0):
    wd, hr = RESETS[acct]
    n = dt.datetime.fromtimestamp(now, UTC)
    r = (n - dt.timedelta(days=(n.weekday() - wd) % 7)).replace(hour=hr, minute=0, second=0, microsecond=0)
    if r > n:
        r -= dt.timedelta(days=7)
    return (r + dt.timedelta(days=7 * weeks)).timestamp()


def newest(acct):
    best = None
    for d in sl_dirs(acct):
        for f in glob.glob(os.path.join(d, "*.json")):
            if os.path.basename(f).startswith("settings_"):
                continue
            try:
                with open(f, encoding="utf-8") as fh:
                    r = json.load(fh)
            except (OSError, ValueError):
                continue
            if r.get("seven_day_pct") is None:
                continue
            if best is None or (r.get("t") or 0) > (best.get("t") or 0):
                best = r
    return best


def usage(acct, now):
    r = newest(acct)
    if r is None:
        return None, None, None
    wk = r["seven_day_pct"] if (r.get("t") or 0) >= last_reset(acct, now) else 0
    fh = r.get("five_hour_pct") or 0
    if (r.get("five_hour_resets_at") or 0) <= now:
        fh = 0
    return wk, fh, r


def logged_in(acct):
    return acct == "A" or os.path.isfile(os.path.join(acct_dir(acct), ".credentials.json"))


def rows(now):
    out = []
    for a in SUBS:
        wk, fh, r = usage(a, now)
        nxt = last_reset(a, now, 1)
        out.append((a, wk, fh, nxt, r))
    return out


def cmd_status(now):
    for a, wk, fh, nxt, r in rows(now):
        age = "no data" if r is None else "dump %d min old" % ((now - (r.get("t") or 0)) // 60)
        print("%s weekly %s%% 5h %s%% next weekly reset %s login %s (%s)" % (
            a, wk, fh, dt.datetime.fromtimestamp(nxt).strftime("%a %m-%d %H:%M local"),
            "yes" if logged_in(a) else "NO", age))
    for a in APIS:
        print("%s headless API key %s" % (a, "yes" if os.path.isfile(os.path.join(acct_dir(a), "key.txt")) else "NO"))
    return 0


def cmd_pick(now):
    cmd_status(now)
    ok = [(nxt, a) for a, wk, fh, nxt, r in rows(now)
          if logged_in(a) and wk is not None and wk < WEEKLY_MAX and fh < FIVE_MAX]
    if ok:
        print("PICK %s" % min(ok)[1])
        return 0
    for a in APIS:
        if os.path.isfile(os.path.join(acct_dir(a), "key.txt")):
            print("PICK %s" % a)
            return 0
    print("PICK NONE (every account at a limit)")
    return 1


def cmd_check(acct, pid, wait):
    if acct not in RESETS:
        print("ACCOUNT CHECK NOT RUN: %s has no rate limits in its status line (API key account)" % acct)
        return 2
    reg = os.path.join(HOME, ".claude", "sessions", "%s.json" % pid)
    end = time.time() + wait
    sid = sl = None
    while time.time() < end:
        if sid is None and os.path.isfile(reg):
            try:
                with open(reg, encoding="utf-8") as fh:
                    sid = json.load(fh).get("sessionId")
            except (OSError, ValueError):
                pass
        if sid:
            for d in sl_dirs(acct):
                f = os.path.join(d, sid + ".json")
                if os.path.isfile(f):
                    with open(f, encoding="utf-8") as fh:
                        r = json.load(fh)
                    if r.get("seven_day_resets_at"):
                        sl = (f, r)
                        break
        if sl:
            break
        time.sleep(5)
    if not sl:
        print("ACCOUNT CHECK FAILED: %s pid %s - no status-line dump with seven_day_resets_at after %d s (session %s)"
              % (acct, pid, wait, sid))
        return 1
    f, r = sl
    got = dt.datetime.fromtimestamp(r["seven_day_resets_at"], UTC)
    hit = [a for a, (wd, hr) in RESETS.items() if got.weekday() == wd and got.hour == hr]
    who = hit[0] if hit else "unknown"
    if who != acct:
        print("ACCOUNT CHECK FAILED: launched on %s but the chat runs on %s (weekly reset %s UTC, %s)"
              % (acct, who, got.strftime("%a %H:%M"), f))
        return 1
    print("ACCOUNT CHECK OK: %s pid %s session %s weekly %s%% reset %s UTC"
          % (acct, pid, sid, r.get("seven_day_pct"), got.strftime("%a %H:%M")))
    return 0


def main(argv):
    now = time.time()
    if argv[1:2] == ["status"]:
        return cmd_status(now)
    if argv[1:2] == ["pick"]:
        return cmd_pick(now)
    if argv[1:2] == ["check"] and len(argv) >= 4:
        wait = int(argv[argv.index("--wait") + 1]) if "--wait" in argv else 180
        return cmd_check(argv[2].upper(), argv[3], wait)
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
