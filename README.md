# Project Zoo Decomp

A work-in-progress **matching decompilation** of *Wallace & Gromit in Project Zoo* (2003, Frontier Developments / BAM!
Entertainment), aiming at a native PC port with modern settings, and later a VR mode.

> **This repository contains no game assets or executables.** You need your own legally obtained copy of the game. The build
> uses it to check that the decompiled code is byte-for-byte identical, and the port will read its data at runtime.

## Status

Phase 0: setting up. Nothing builds yet.

| | |
|---|---|
| Target | PS2 NTSC-U `SLUS-20647` (proposed, see [docs/RESEARCH.md](docs/RESEARCH.md)) |
| Engine | Frontier FGDK3, shared with *Dog's Life* |
| Progress | 0 % |

## Goals

1. A true decomp: C/C++ that rebuilds the original executable exactly.
2. A native PC port: any resolution and aspect ratio, uncapped framerate, graphics presets, modern controllers with rebinding,
   mods. See [docs/ROADMAP.md](docs/ROADMAP.md).
3. A VR mode (OpenXR) with diorama, third-person and first-person cameras.

## Thanks

- [dogcomp](https://github.com/IWILLCRAFT-M0d/dogcomp): the *Dog's Life* decomp, on the same engine and toolchain.
- [Gibbed.FGDK3](https://github.com/gibbed/Gibbed.FGDK3) and [dogs-life-docs](https://github.com/Dogmander/dogs-life-docs): FGDK3 file formats.
- splat, objdiff, decomp.me, decomp.dev.

## Legal

This project is not affiliated with Aardman Animations, Frontier Developments or the rights holders of Wallace & Gromit.
It contains no copyrighted game data. This project is AI-assisted.
