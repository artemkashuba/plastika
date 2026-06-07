# CURRENT_TASK.md

## Current Status

Pink "Laser Lance" tower — complete.

The repository now has:

- A canonical `docs/` documentation structure
- A root `README.md`
- An iOS 17+ Xcode project
- A SwiftUI app entry point hosting SpriteKit through `SpriteView`
- A `GameScene` that loads a simple tabletop placeholder view
- Placeholder managers for the documented systems
- A `PathManager` with a hardcoded waypoint path
- A `WaveManager` that scripts a two-wave sequence with an inter-wave countdown
- Multiple pooled placeholder enemies moving along the path and disappearing at the end
- Five circular build spots around the path
- Tap-to-open tower build menu interaction for empty build spots
- A compact three-option circular build menu below the active build spot
- Menu movement when tapping another empty build spot and menu hiding when tapping empty battlefield space
- Red, Green, Blue, and Pink prototype tower types selected from the build menu (compact menu now scales to any number of types via a centered, formula-based layout)
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
- A victory overlay ("VICTORY") when all scripted waves are cleared
- A Restart button on both overlays that fully resets and restarts wave progression from wave 1
- Combat and input gated on `.sceneLoaded` phase; overlays block all gameplay input
- No center branding text inside the battlefield
- No upgrades, selling (per-wave), splash damage, status effects, multiple enemy types, or final art

## Next Task

Tower upgrades (next unchecked Phase 2 item in `TODO.md`).

## Immediate Goal

Decide on an upgrade model (e.g., per-tower tiers affecting damage/range/cooldown) and design the UI for triggering an upgrade from a selected tower.

## Previous Milestone — Pink "Laser Lance" Tower

A fourth tower type, the continuous-beam Laser Lance, is now live:

- New `TowerAttackStyle { case projectile; case beam }` cleanly separates the established discrete-shot combat model (Red/Green/Blue — completely untouched) from the new persistent-beam model (Pink only); `TowerType.dps` is now style-aware, deriving from `damage`/`attackCooldown` for projectile towers and reporting `laserDamagePerSecond` directly for beam towers
- Pink ("Laser Lance", 75 coins — vs. 50 for the others) locks onto a single target like every other tower, but instead of firing discrete shots it projects a persistent glowing magenta beam at that target for as long as the lock holds, dealing continuous damage every frame at ≈ 4.5 DPS — the highest single-target DPS in the roster, justifying its premium cost
- `PlaceholderEnemy.fractionalHealth: Double` is now the canonical health value (with `hitPoints: Int` as a ceiling-rounded derived mirror) — the health bar renders directly from the fractional remainder, so it drains in genuinely smooth, continuous steps under laser fire while remaining numerically identical to the old behavior for ordinary whole-HP hits from Red/Green/Blue
- `TowerManager.updateCombat` now tracks per-frame `deltaTime` and dispatches beam-style towers to a dedicated `updateBeamCombat` branch — drawing the beam visual every frame and applying `dps * deltaTime` fractional damage via the new `EnemyManager.applyContinuousDamage`/`PlaceholderEnemy.takeContinuousDamage` — entirely separate from (and without touching) the projectile-firing path below it
- `PlaceholderTower.showBeam(to:color:)`/`hideBeam()` draw a "glow + bright core" line pair (mirroring the existing muzzle-flash visual language) as children of `barrelNode`, so the beam inherits the turret's target-facing rotation "for free" and only needs its length redrawn each frame
- The beam now has a soft "neon sign" pulse — `startBeamPulse` runs a forever-looping, slightly-out-of-phase breathing animation on the glow (alpha + line-width oscillation) and core (faster alpha flicker, offset start) the instant the beam node is first created, so a locked-on laser reads as a living energy conduit rather than a static painted line. The loop runs independently of `showBeam`'s per-frame redraws and keeps cycling quietly even while hidden, so re-acquiring a target picks the breath back up mid-cycle instead of resetting it
- The beam now also leaves a "burn" mark on contact — `PlaceholderEnemy.showBeamBurn(color:)` shows a small flickering plasma cluster (tinted glow + white-hot core, mirroring the tower's own muzzle-flash language) at the enemy's anchor point, the exact spot the beam visually terminates. It lives on the enemy rather than the tower, so it tracks a moving target for free and vanishes automatically on death/recycle; `TowerManager.updateBeamCombat` shows it every locked-on frame and a same-tick "previous vs. new target" check in `updateCombat` hides it the instant the lock moves on (e.g. the target walks out of beam range while still alive)
- `TowerGunFactory` gained a dedicated Pink emitter assembly — slim housing + glowing lens — replacing the barrel/muzzle look with a beam-projector aesthetic; beam towers report `recoilDistance`/`muzzleFlashScale`/`attackCooldown` of 0 so they never recoil, flash, or show a reload ring
- `BuildSpotManager.menuOffset(for:)` is now a centered, index-based formula over `TowerType.allCases` instead of a hardcoded 3-case switch — reproduces the exact old Red/Green/Blue spacing while automatically and symmetrically slotting Pink in as a 4th option (and scaling cleanly to any future Nth type)
- `PauseMenuView`'s ARSENAL spec chips now branch on `attackStyle` — beam towers show MODE=BEAM / DPS / RANGE (no DMG/RELOAD, since they have no discrete shot or cooldown to quote)

## Previous Milestone — Second Wave + Countdown

Second wave + inter-wave countdown is now live:

- `WaveManager` now derives each wave from a formula-based difficulty curve (`waveDefinition(at:)`) instead of a single hardcoded prototype wave — every wave after the first automatically gets `enemyCountStepPerWave` more enemies and a `spawnIntervalStepPerWave`-shorter spawn interval (floored at `minimumSpawnInterval`). With today's tuning that's Wave 1 = 6 @ 0.85s, Wave 2 = 9 @ 0.70s; raising `scriptedWaveCount` alone adds further (automatically harder) waves with no per-wave hand-tuning
- `updateProgression(activeEnemyCount:...)` replaces the old inline victory check: once a wave finishes spawning and its last enemy dies, it either starts a 3-second inter-wave countdown (more waves remain) or signals "all waves cleared" exactly once so `GameScene` can trigger victory
- A keyed `SKAction` countdown sequence announces each second via the new `onWaveProgressChanged` callback ("WAVE 2 IN 3" → "WAVE 2 IN 2" → "WAVE 2 IN 1" → wave 2 begins), staying entirely within the existing `.sceneLoaded` phase so the player can keep building/playing through the break
- `UIManager.setWave(number:countdown:)` updates the HUD wave badge on demand (not every frame) — shows "WAVE N" normally and "WAVE N IN S" during a countdown, with a smaller font size for the longer countdown string
- `PauseStats` gained `waveNumber`/`totalWaveCount`; the Pause menu's enemy section header now reads "ENEMIES — WAVE 1/2" so the spawned/total stat is unambiguous about its per-wave scope
- `isAdvancingToNextWave` guards `updateProgression` against re-triggering the countdown while it's already running or already complete

## Previous Milestone — Shooting Feel Pass

Shooting feel pass is now live:

- Barrel recoil on every shot — `TowerGunFactory` now splits each gun into a fixed turret (`aimNode`) and a separate `barrelNode` holding only the forward weapon geometry, which kicks back along the firing axis and springs back via a keyed `SKAction` sequence
- Recoil distance scales with gun weight via `TowerType.recoilDistance` (Red 2.5pt < Green 4.5pt < Blue 7.5pt) — the Heavy Cannon visibly kicks much harder than the Autocannon
- Muzzle flash — a brief white-hot core inside a tinted glow (color-matched to the tower's projectile) spawns at `barrelTipPosition` at the instant of firing, sized per `TowerType.muzzleFlashScale`, and dissolves in ~0.13s
- Reload-timer ring — a small radial ring (faint static track + bright white arc) appears as a rim around the tower's base the instant it fires, sweeps from empty to a full circle over its `attackCooldown` duration via `SKAction.customAction`, and fades out the moment it's ready to shoot again — visible only while reloading
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
