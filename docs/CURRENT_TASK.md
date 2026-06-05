# CURRENT_TASK.md

## Current Status

Battlefield visual prototype slice is complete.

The repository now has:

- A canonical `docs/` documentation structure
- A root `README.md`
- An iOS 17+ Xcode project
- A SwiftUI app entry point hosting SpriteKit through `SpriteView`
- A `GameScene` that loads a simple tabletop placeholder view
- Placeholder managers for the documented systems
- A `PathManager` with a hardcoded waypoint path
- A `WaveManager` that spawns a finite prototype wave
- Multiple pooled placeholder enemies moving along the path and disappearing at the end
- Five visual-only circular build spots around the path
- A small debug HUD showing wave and active enemy count
- No center branding text inside the battlefield

## Next Task

Add the next prototype slice: introduce minimal tower placement interaction without projectiles, combat, or economy.

Before starting, review the documentation workflow in `docs/AGENTS.md`.

## Immediate Goal

Reach first playable prototype with:

- One map
- One enemy type moving along a path
- Visual build spots ready for one tower type
- One wave

## Blockers

None.
