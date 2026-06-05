# CURRENT_TASK.md

## Current Status

Minimal tower placement interaction slice is complete.

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
- Five circular build spots around the path
- Tap-to-place placeholder tower interaction for empty build spots
- Occupancy tracking so the same build spot cannot place multiple towers
- A UI test that verifies one build spot tap places a tower and a repeated tap does not duplicate it
- A small debug HUD showing wave and active enemy count
- No center branding text inside the battlefield
- No tower selection menu, upgrades, selling, projectiles, combat, economy, range indicators, final art, or physics

## Next Task

Add the next prototype slice: introduce the first tower behavior and combat loop without expanding into upgrades, selling, or monetization.

Before starting, review the documentation workflow in `docs/AGENTS.md`.

## Immediate Goal

Reach first playable prototype with:

- One map
- One enemy type moving along a path
- Build spots that can place one placeholder tower each
- One wave

## Blockers

None.
