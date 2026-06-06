# CURRENT_TASK.md

## Current Status

First combat slice is complete.

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
- Placeholder towers that automatically target the nearest enemy within internal range
- A lightweight `ProjectileManager` with pooled magenta placeholder projectiles
- Basic 1 HP placeholder enemies that are removed and recycled when hit
- A UI test that verifies projectiles appear and enemies disappear after tower placement
- A small debug HUD showing wave and active enemy count
- No center branding text inside the battlefield
- No tower selection menu, upgrades, selling, economy, range indicators, splash damage, status effects, multiple tower types, multiple enemy types, final art, or physics

## Next Task

Add the next prototype slice: introduce the first economy or win/lose loop without expanding into upgrades, selling, or monetization.

Before starting, review the documentation workflow in `docs/AGENTS.md`.

## Immediate Goal

Reach first playable prototype with:

- One map
- One enemy type moving along a path
- Build spots that can place one placeholder tower each
- Placeholder towers that fire projectiles and destroy 1 HP enemies
- One wave

## Blockers

None.
