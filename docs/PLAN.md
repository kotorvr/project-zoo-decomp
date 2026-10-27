# Plan

## Goals (the user, 2026-10-27)

1. **A true decomp** of Wallace & Gromit in Project Zoo: matching C/C++ that rebuilds the original executable byte for byte,
   from the best build, "even if more work". The user supplies their own legally obtained game files.
2. **A native PC port** on top of it, at the level of God of War PC, Dusklight and Silent Hill 1 PC: modern systems, controllers,
   settings, graphics presets (`docs/ROADMAP.md`).
3. **A VR mode** (second goal).
4. Public on GitHub; listed on recompsoftware.com and recomplauncher.com.

## Phases

| phase | done when |
|---|---|
| P0 setup | target build okayed; the user's dumps hashed in `orig/`; symbol check done on both ELFs + prototype; splat config splits the ELF; `ninja` rebuilds a byte-identical ELF from asm; CI-free local `progress` line |
| P1 engine | FGDK3 engine units shared with Dog's Life matched (reuse dogcomp's matches where the code is identical), libraries identified (SCE libs, libc) |
| P2 game | the Zoo game code matched; progress published on decomp.dev |
| P3 port bring-up | `port/` builds a native x64 exe from the decomp: PS2 hardware calls replaced (GS/VU renderer -> native RHI, IOP/audio, pad, memory card, file I/O); boots to the title screen |
| P4 port 1.0 | the ROADMAP "must have" list; release on GitHub; submitted to the two sites |
| P5 VR | the ROADMAP VR section |

P3 can start before P2 ends: a port runs mixed matched C and translated/non-matching functions, as long as `src/` keeps matching.

## Decisions

| date | decision | by |
|---|---|---|
| 2026-10-27 | workflow = KOTOR/Echo's (orchestrator, planner, auditor, workstreams, CLI launcher, all accounts, bypassPermissions) | the user ("look at my workflow for kotor and echoquestcombat") |
| 2026-10-27 | primary target PS2 NTSC-U SLUS-20647 (disc VER=1.01, ISO SHA-1 `28BD5257ECC56F9802105A9A1B05B9452252DCFB`, in `orig/SLUS-20647/`); PC EU build + Aug 2003 prototype as references when the user has them | the user supplied this disc: "please check my downloads for the ROM and you start the orchestrator" |
| 2026-10-27 | **proposed**: renderer = native renderer replacing GS/VU code (OpenGOAL route) on an RHI, per-view matrices from day one for VR | awaiting the user |

## Status (one row per workstream)

| id | goal | branch | state |
|---|---|---|---|
| SETUP-0 | repo, workflow, research, roadmap | main | done 2026-10-27 |
