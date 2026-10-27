# Roadmap: PC port and VR features (draft for the user, 2026-10-27)

The bar: God of War PC, Dusklight, Silent Hill 1 PC - a native port built from the decomp, not an emulator wrapper.
Ranked inside each group; nothing here is okayed yet (see `docs/PLAN.md` decisions).

## Must have for 1.0

- **Setup:** first-run wizard: point at your own disc image / ISO, hash check against known dumps, extract to a data folder. No
  game data ever ships.
- **Display:** any resolution, windowed / borderless / exclusive, V-Sync, display picker, DPI-aware.
- **Aspect:** 16:9, 21:9, 32:9 with HUD anchoring (left/centre/right), FOV fix (Hor+), cutscenes in original aspect unless
  unlocked.
- **Framerate:** 30 / 60 / 120 / 144 / uncapped, by interpolating transforms between game ticks (game logic stays at its native
  rate, so physics and timings do not break). High-fps bug fixes listed per bug.
- **Graphics presets:** Original / Low / Medium / High / Ultra / Custom, each mapping to:
  internal resolution scale, MSAA (2/4/8x), FXAA/SMAA, anisotropic filtering, texture filtering (original / bilinear /
  bicubic), shadow quality, draw distance and LOD bias, depth-of-field / bloom on-off, and a "PS2 look" toggle (dither,
  original filtering, CRT shader).
- **Input:** SDL3: Xbox / PlayStation / Switch / Steam Deck pads with automatic button prompts, rumble, gyro for aiming
  gadgets, full rebinding (pad and keyboard + mouse), mouse camera, sensitivity and invert per axis, dead zones.
- **Menus:** an in-game options menu usable with a pad from the title and pause screens; a separate ImGui dev overlay (F1).
- **Audio:** master / music / SFX / voice sliders, output device picker, mute in background.
- **Saves:** memory-card saves mapped to a save folder, autosave, multiple slots; cloud-sync-friendly paths.
- **Platforms:** Windows x64, Linux (Steam Deck verified), macOS (Apple silicon) if the RHI allows.
- **Performance:** precompiled shader pipelines (no stutter), low-latency swapchain.

## Should have

- Texture and model replacement packs (dump + load folder, hot reload), an HD texture pack workflow.
- Mod loader: asset mods first, then code hooks.
- Accessibility: subtitles for all dialogue with size and background, camera shake off, colour-blind filters, high-contrast
  HUD, hold-to-toggle options, game speed slider.
- QoL: skip cutscenes, faster loading, camera centring options, invert-free camera, quick restart.
- Achievements (local, in-game toasts, like UnleashedRecomp).
- Speedrun: in-game timer, load removal, practice warps, input display.
- Debug: free camera, level select, restored debug flags (TCRF's `Options.txt` set), collision view, frame stepping.
- Restored cut content where it exists in the data (TCRF), behind an option.
- Localised menus for every language the discs ship.

## VR mode (goal 2, after 1.0)

- OpenXR, loaded at runtime only when VR is chosen (the flat build never depends on it). PC VR first (SteamVR, Quest Link /
  Virtual Desktop); a native Quest build later.
- Game logic at its native tick; the HMD pose applies per eye on top of the game camera, so the headset never fights the
  gameplay camera.
- Camera modes, cycled by a button (the Super Mario 3D World VR model):
  1. **Diorama**: a fixed world anchor, the level as a tabletop you look into, Gromit / Wallace in third person.
  2. **Close third person**: a smoothed chase camera, pitch and roll removed.
  3. **First person** (experimental): Gromit's eyes, for the vehicle and shooting sections.
- HUD and menus on a quad layer; cutscenes on a virtual screen or in-world.
- Comfort: snap / smooth turn, vignette, height and scale calibration, seated / standing.
- Motion controls: aim the gadgets with a controller (gyro aim path reused), pad fallback.
- Renderer requirement from day one: per-view camera matrices, stereo via two passes or multiview, render-to-texture HUD.

## Distribution

- GitHub Releases per OS with stable asset names; submit to recompsoftware.com and recomplauncher.com / RecompStore.
- Clear "bring your own disc" wording, no assets, an honest "AI-assisted" tag.
