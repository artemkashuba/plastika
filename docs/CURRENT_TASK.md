# CURRENT_TASK.md

## Current Status

Economy system is complete.

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
- Tap-to-open tower build menu interaction for empty build spots
- A compact three-option circular build menu below the active build spot
- Menu movement when tapping another empty build spot and menu hiding when tapping empty battlefield space
- Red, Green, and Blue prototype tower types selected from the build menu
- Occupancy tracking so the same build spot cannot place multiple towers
- A UI test that verifies an empty build spot tap opens the menu, Red placement requires selecting the Red option, and repeated taps do not duplicate towers
- Placeholder towers that acquire the closest enemy within internal range, lock that target while it remains valid, and only reacquire after the target dies, leaves range, or is no longer tracked
- Placeholder tower turret/barrel visuals that rotate toward the current locked target
- A lightweight `ProjectileManager` with pooled magenta placeholder projectiles
- Red towers with fast attack speed and direct projectile behavior
- Green towers with homing projectile behavior and slightly slower attack speed
- Blue towers with slow attack speed and slow direct projectile behavior
- A code TODO to add future predictive aiming for Blue towers once enemy speed and lead tuning exist
- Basic 1 HP placeholder enemies that are removed and recycled when hit
- A UI test that verifies projectiles appear and enemies disappear after tower placement
- Tap-to-select interaction for placed placeholder towers
- A subtle selected tower highlight using slight scale and a thin white ring
- A reused white range indicator centered on the selected tower's actual attack range
- Selection switching between placed towers and empty-space deselection
- A UI test that verifies build menu display, movement, hiding, and typed Red/Green/Blue tower placement
- A UI test that verifies selection, range display, switching, deselection, placement, and combat behavior
- A UI test that verifies the placeholder tower barrel aims toward an early locked target
- A debug HUD showing wave number, active enemy count, and current coin balance
- An `EconomyManager` with 150 starting coins, per-kill +10 credit, and 50-coin tower cost
- Build menu options dimmed (alpha 0.4) when the player cannot afford them
- Blocked tower placement when the player has insufficient coins
- A UI test that verifies the economy blocks placement when the player has spent all coins
- No center branding text inside the battlefield
- No upgrades, selling, splash damage, status effects, multiple enemy types, final art, physics, or win/lose conditions

## Next Task

Add win/lose conditions: base health that decreases when enemies reach the path end, a game-over state when base health reaches zero, and a victory state when all wave enemies are defeated.

Before starting, review the documentation workflow in `docs/AGENTS.md`.

## Immediate Goal

Reach first fully playable prototype with:

- One map
- One enemy type moving along a path
- Build spots that open a tower type menu and can place one prototype tower each
- Prototype towers that lock targets, aim their barrel, fire type-specific projectiles, and destroy 1 HP enemies
- Placeholder tower selection with visible attack range and selected-state feedback
- Red, Green, and Blue tower types with distinct visuals and projectile behavior
- One wave
- Economy (coins, tower cost, kill reward)
- Win/lose conditions

## Blockers

None.
