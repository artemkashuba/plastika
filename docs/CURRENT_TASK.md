# CURRENT_TASK.md

## Current Status

Shooting feel pass (recoil + muzzle flash + coin-fly reward) — complete.

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

Second wave with inter-wave countdown.

## Immediate Goal

Add a second wave that spawns after a short inter-wave countdown once all wave-1 enemies are defeated.

## Previous Milestone

Shooting feel pass is now live:

- Barrel recoil on every shot — `TowerGunFactory` now splits each gun into a fixed turret (`aimNode`) and a separate `barrelNode` holding only the forward weapon geometry, which kicks back along the firing axis and springs back via a keyed `SKAction` sequence
- Recoil distance scales with gun weight via `TowerType.recoilDistance` (Red 2.5pt < Green 4.5pt < Blue 7.5pt) — the Heavy Cannon visibly kicks much harder than the Autocannon
- Muzzle flash — a brief white-hot core inside a tinted glow (color-matched to the tower's projectile) spawns at `barrelTipPosition` at the instant of firing, sized per `TowerType.muzzleFlashScale`, and dissolves in ~0.13s
- Reload-timer ring — a small radial ring (faint static track + colored arc, tinted to the tower's turret color) appears as a rim around the tower's base the instant it fires, sweeps from empty to a full circle over its `attackCooldown` duration via `SKAction.customAction`, and fades out the moment it's ready to shoot again — visible only while reloading
- All three effects fire from `PlaceholderTower.playFireEffects()`, called from `TowerManager.updateCombat` in the same instant as the shoot sound and projectile spawn
- Coin-fly reward animation — on enemy kill, a small glowing coin arcs from the death position to the HUD coin counter (`UIManager.flyCoinReward`), then the counter pulses on landing; purely cosmetic, decoupled from the actual economy credit
- Sound toggle now actually works — replaced unreliable `audioEngine.mainMixerNode` volume manipulation with explicit `isSoundEnabled` gating checked at every `SKAction.playSoundFileNamed` call site (`TowerManager` + `GameScene`)
- Pause menu ARSENAL section — scrollable reference list of all tower types with proper names (Autocannon / Missile Pod / Heavy Cannon), descriptions, and DMG/RELOAD/RANGE/DPS spec chips

## Previous Milestone — Tower Selling

Tower selling is now live:

- Tap a placed tower to select it → a sell badge appears below: dark pill with golden border, coin icon + refund amount ("25"), matching the HUD coin style
- Tap the badge to sell: tower node removed, build spot freed, 25 coins refunded, HUD coin count updates immediately
- Badge hides on deselect, on tower switch, on scene reset
- `TowerType.sellRefund` = `cost / 2` (25 coins for a 50-coin tower)
- `BuildSpotManager.markUnoccupied(buildSpotID:)` frees the slot so it can be rebuilt
- Tap detection via `nodes(at:)` name-matching ("SellBadge"), consistent with RestartButton pattern

## Previous Milestone — HUD

The top-bar HUD is now live:

- Full-width dark bar at the top of the scene (z=40)
- Left: yellow coin circle icon + coin count (updates every frame)
- Center: "WAVE 1" green pill badge
- Right: three ♥ hearts — red when alive, dimmed gray when lost (deplete right-to-left)
- End-of-game overlays (VICTORY/DEFEAT) and restart button are unchanged
- `UIManager.update()` now takes `(coins: Int, health: Int)` — `activeEnemyCount` removed

## Blockers

None.
