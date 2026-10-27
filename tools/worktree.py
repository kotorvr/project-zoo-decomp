"""Readies a workstream worktree (called by tools/launch/launch_one.ps1 as `status` / `setup --branch <id>`).

The user's own game dumps live only in the main tree's `orig/` (gitignored, never committed or uploaded). A worktree gets
directory junctions to the main tree's `orig/` and `tools/bin/` (downloaded toolchains), so every chat builds and diffs
against the same files without copying them.

  python tools/worktree.py status          -> prints READY / NOT READY (exit 0 / 1)
  python tools/worktree.py setup --branch X -> creates the junctions, prints READY
"""
import argparse
import os
import subprocess
import sys

SHARED = ["orig", os.path.join("tools", "bin")]


def git(*args, cwd):
    return subprocess.check_output(["git", "-C", cwd, *args], text=True).strip()


def trees():
    here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    tree = git("rev-parse", "--show-toplevel", cwd=here)
    main = os.path.dirname(git("rev-parse", "--path-format=absolute", "--git-common-dir", cwd=here))
    return os.path.normpath(tree), os.path.normpath(main)


def missing(tree, main):
    if tree == main:
        return []
    return [p for p in SHARED if os.path.isdir(os.path.join(main, p)) and not os.path.exists(os.path.join(tree, p))]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", choices=["status", "setup"])
    ap.add_argument("--branch")
    a = ap.parse_args()
    tree, main_tree = trees()
    todo = missing(tree, main_tree)
    if a.cmd == "setup":
        if a.branch:
            cur = git("rev-parse", "--abbrev-ref", "HEAD", cwd=tree)
            if cur != a.branch:
                print(f"REFUSED: tree is on {cur}, not {a.branch}")
                return 2
        for p in todo:
            dst = os.path.join(tree, p)
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            # a junction needs no admin rights or developer mode, unlike a symlink
            subprocess.check_call(["cmd", "/c", "mklink", "/J", dst, os.path.join(main_tree, p)], stdout=subprocess.DEVNULL)
        todo = missing(tree, main_tree)
    print("READY" if not todo else "NOT READY: missing " + ", ".join(todo))
    return 0 if not todo else 1


if __name__ == "__main__":
    sys.exit(main())
