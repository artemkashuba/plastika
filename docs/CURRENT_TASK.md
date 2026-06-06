# CURRENT_TASK.md

## Current Status

Shooting improvements pass is complete.

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
- Blue tower predictive aiming — fires at the enemy's quadratic intercept position based on velocity and projectile speed
- Homing (Green) missiles that chase their target until impact, regardless of the tower's attack range
- Per-tower projectile colors: Red = orange, Green = lime, Blue = cyan
- Impact flash effect at the hit position, color-matched to the projectile
- Basic 1 HP placeholder enemies that are removed and recycled when hit
- A UI test that verifies projectiles appear and enemies disappear after tower placement
- Tap-to-select interaction for placed placeholder towers
- A subtle selected tower highlight using slight scale and a thin white ring
- A reused white range indicator centered on the selected tower's actual attack range
- Selection switching between placed towers and empty-space deselection
- A UI test that verifies build menu display, movement, hiding, and typed Red/Green/Blue tower placement
- A UI test that verifies selection, range display, switching, deselection, placement, and combat behavior
- A UI test that verifies the placeholder tower barrel aims toward an early locked target
- A debug HUD showing wave number, active enemy count, coin balance, and base health
- An `EconomyManager` with 150 starting coins, per-kill +10 credit, and 50-coin tower cost
- Build menu options dimmed (alpha 0.4) when the player cannot afford them
- Blocked tower placement when the player has insufficient coins
- A `BaseHealthManager` with 3 starting lives
- Lives decremented when an enemy reaches the path end
- A game-over overlay ("DEFEAT") when all lives are lost
- A victory overlay ("VICTORY") when all wave enemies are defeated
- A Restart button on both overlays that fully resets and restarts the wave
- Combat and input gated on `.sceneLoaded` phase; overlays block all gameplay input
- No center branding text inside the battlefield
- No upgrades, selling, splash damage, status effects, multiple enemy types, or final art

## Next Task

Begin Phase 2 — Vertical Slice: add placeholder UI (coin display, health bar, wave counter as proper in-game UI rather than a debug overlay), sound effects, or tower upgrades.

Alternatively, continue Phase 1 polish: add more enemy variety, second wave, or tower selling/upgrading.

Before starting, review the documentation workflow in `docs/AGENTS.md`.

## Immediate Goal

The first playable prototype loop is now complete:

- One map with enemies moving along a hardcoded path
- Build spots with a tower type selection menu
- Red, Green, and Blue towers with distinct projectile behavior
- One wave of 6 enemies
- Economy: coins, tower cost, kill reward
- Win/lose: base health, game-over and victory overlays, restart

## Blockers

None.
