# SETUP-1: the matching build skeleton (Opus, own worktree)

You are SETUP-1. Read `CLAUDE.md`, `docs/WORKFLOW.md`, `docs/PLAN.md`, `docs/RESEARCH.md`.
Report to "Zoo orchestrator" on start, when blocked and when done.

**Precondition:** the user has put their own dumps in the main tree's `orig/`, and the orchestrator has recorded the
target build in `docs/PLAN.md`. If either is missing, report BLOCKED and stop.

## Goal

A build that splits the target ELF and rebuilds it byte-identical from assembly. Every later decomp workstream starts from this.

1. **Hash the dumps.**
   - Write `tools/hashes.py`. It prints the SHA-1 of each file in `orig/` and checks it against `config/<version>/checksums.sha1`.
   - Commit the checksum file. Hashes are not game data.
2. **Symbol check.**
   - Scan the target ELF, the other PS2 ELFs and the Aug 2003 prototype (if the user has it) for:
     - `.symtab`, `.strtab` and DWARF sections
     - `.mdebug`
     - `.comment` (this gives the compiler version)
     - leftover map files on the disc
   - Write the findings to `docs/research/symbols.md`.
   - This decides how much naming is free.
3. **Toolchain.**
   - Copy dogcomp's approach (https://github.com/IWILLCRAFT-M0d/dogcomp: splat, ninja, objdiff, ee-gcc 2.95.3 via its
     `tools/setup_prodg_linux.sh`).
   - Adapt it to Windows. Choose WSL or native, and record which and why.
   - Download the toolchains into `tools/bin/`, which is gitignored and shared by worktree junctions.
   - Confirm the compiler version against the ELF's `.comment`.
4. **Split.**
   - Write `config/<version>/splat.yaml` and run splat.
   - Write `configure.py`, which generates `build.ninja`.
   - `ninja` must rebuild the ELF. `tools/hashes.py --build` must print `MATCH <sha1>`.
5. **Progress.**
   - Write `tools/progress.py`. It prints `progress: N/M functions, X% code` from objdiff's report.
   - Add an `objdiff.json`.

## Owned

`configure.py`, `config/`, `tools/hashes.py`, `tools/progress.py`, `objdiff.json`, `docs/research/symbols.md` and the build files.

## Out of scope

Decompiling any function, and the port.

## Done

`MATCH` and the progress line, both recorded in `docs/sessions/logs/SETUP-1.md`, and landed on `main`.
Nothing from `orig/` may be in any commit: check `git show --stat` for each commit.
