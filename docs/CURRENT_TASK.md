# CURRENT_TASK.md

## Current Status

Stable tower targeting and gun aiming slice is complete.

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
- Placeholder towers that acquire the closest enemy within internal range, lock that target while it remains valid, and only reacquire after the target dies, leaves range, or is no longer tracked
- Placeholder tower turret/barrel visuals that rotate toward the current locked target
- A lightweight `ProjectileManager` with pooled magenta placeholder projectiles
- Straight placeholder projectile travel toward the target position captured at fire time
- Basic 1 HP placeholder enemies that are removed and recycled when hit
- A UI test that verifies projectiles appear and enemies disappear after tower placement
- Tap-to-select interaction for placed placeholder towers
- A subtle selected tower highlight using slight scale and a thin white ring
- A reused white range indicator centered on the selected tower's actual attack range
- Selection switching between placed towers and empty-space deselection
- A UI test that verifies selection, range display, switching, deselection, placement, and combat behavior
- A UI test that verifies the placeholder tower barrel aims toward an early locked target
- A small debug HUD showing wave and active enemy count
- No center branding text inside the battlefield
- No tower selection menu, upgrades, selling, economy, splash damage, status effects, multiple tower types, multiple enemy types, final art, or physics

## Next Task

Add the next prototype slice: introduce the first economy or win/lose loop without expanding into upgrades, selling, or monetization.

Before starting, review the documentation workflow in `docs/AGENTS.md`.

## Immediate Goal

Reach first playable prototype with:

- One map
- One enemy type moving along a path
- Build spots that can place one placeholder tower each
- Placeholder towers that lock targets, aim their barrel, fire straight projectiles, and destroy 1 HP enemies
- Placeholder tower selection with visible attack range and selected-state feedback
- One wave

## Blockers

None.
