# CURRENT_TASK.md

## Current Status

Enemy death effect (livery-colored debris burst on a damage kill) — complete.
Enemy variety (Scout/Soldier/Tank) — complete.

The repository now has:

- A canonical `docs/` documentation structure
- A root `README.md`
- An iOS 17+ Xcode project
- A SwiftUI app entry point hosting SpriteKit through `SpriteView`
- A `GameScene` that loads a simple tabletop placeholder view
- Placeholder managers for the documented systems
- A `PathManager` with a hardcoded waypoint path
- A `WaveManager` that scripts a two-wave sequence with an inter-wave countdown
- Three pooled enemy types — Scout/Soldier/Tank, each with its own HP, path-speed multiplier, kill-reward value, and recolored/rescaled chassis livery on a shared toy-tank silhouette — moving along the path and disappearing at the end
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
- Green's "Missile Pod" stands apart visually: a unique rectangular "armored launch deck" chassis + solid launcher-hull gun assembly, and a tapered rocket projectile (nose cone, tail exhaust glow, drifting smoke trail) that rotates to face its direction of travel — replacing its old round chassis + thin twin tubes + plain glow-ball look (see `ProjectileVisualStyle`)
- Per-tower projectile colors: Red = orange, Green = lime, Blue = cyan
- Impact flash effect at the hit position, color-matched to the projectile
- Pooled, type-configurable placeholder enemies (Scout 5 HP / Soldier 8 HP / Tank 18 HP — bumped +50% from launch values in a balance pass) that are removed and recycled when killed
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
- Tower upgrades are in (2 tiers, damage/DPS-only scaling) and the enemy roster now has real variety (see milestones below); still no per-wave selling, splash damage, status effects, or final art

## Next Task

Add haptics (next unchecked Phase 2 item in `TODO.md`).

## Immediate Goal

Identify the moments that most deserve tactile feedback (tower placement, firing, enemy kills, base damage, wave start/clear, button taps?) and decide which haptic style (`UIImpactFeedbackGenerator` weight, `UINotificationFeedbackGenerator` for win/loss, etc.) fits each — keeping the same "small vertical slice" approach as every other feel-pass feature so far (recoil, muzzle flash, reload ring).

## Previous Milestone — Enemy Death Effect

Killing an enemy now has a real visual payoff instead of the node silently vanishing — the most-repeated moment in the game finally rewards the player:

- New `PlaceholderEnemy.spawnDeathEffect(in:)` builds a self-contained "blown-apart toy" burst at the enemy's current position: a hull-tinted glow, a brighter white-hot core, an expanding stroke-only shockwave ring, and six livery-colored debris shards (three hull chunks, the turret, two dark track bits) that fly outward on roughly even angles (with per-shard jitter), spinning, shrinking, and fading over ~0.4–0.5s. The whole burst is scaled by `type.chassisScale`, so a Tank dies bigger than a Scout
- Crucially, the effect is added to the **scene**, not as a child of the enemy `node` — the enemy is recycled the same frame it dies, so a child effect would be torn down instantly. Every effect node self-removes via `SKAction.removeFromParent()`, so there's no pooling or cleanup bookkeeping (mirrors the existing transient-effect language: `ProjectileManager.showImpactFlash`, `PlaceholderEnemy.showBeamBurn`, `UIManager.flyCoinReward`)
- Wired in at a single chokepoint: `EnemyManager.killAndRecycle(_:)` (new private helper) bumps `killCount`, fires the burst while the enemy node is still in the scene, then recycles — replacing the duplicated `killCount += 1; recycle(...)` in all three damage paths (`applyDamage`, `applyDamage(matchingLifeID:)`, `applyContinuousDamage`), so both projectile and beam kills get it for free. Deliberately kept **out** of `recycle` itself, because `recycle` is also used for enemies that *breach* the base — those should not explode
- No physics, no new assets, no per-frame cost — a handful of short-lived `SKShapeNode`s per kill, in keeping with the performance rules

## Previous Milestone — Enemy Variety (Scout/Soldier/Tank)

The enemy roster now has real, documented variety — Scout/Soldier/Tank, exactly as named in `GAME_DESIGN.md`'s Enemies section and `TODO.md`'s Phase 2 entry:

- New `EnemyType: CaseIterable` (mirroring `TowerType`'s static-per-type-stats shape) declares `maxHitPoints`, `speedMultiplier`, `killReward`, chassis livery colors, and `chassisScale` for each of the three types. Soldier is the untouched original baseline (5 HP, 1.0× speed, 10-coin reward, original maroon livery, 1.0× scale); Scout trades HP for speed (3 HP, 1.35× speed, 6-coin reward, smaller bright-orange chassis at 0.82×); Tank inverts that trade (12 HP, 0.65× speed, 18-coin reward, larger dull-armored chassis at 1.28×)
- `PlaceholderEnemy` gained a `configure(type:)` method (mirroring `PlaceholderProjectile.configure`'s "fully reset on reuse" pooling contract) that reapplies every per-type stat and chassis detail — HP, kill reward, hull/turret recolor, uniform rescale of `bodyNode` — since pooled instances may have last lived as a completely different type. `EnemyManager.spawnPlaceholderEnemy(in:path:type:)` now takes an `EnemyType` and calls `configure` before `startMoving` (which immediately calls `reset()`, deriving `hitPoints`/`fractionalHealth` from the just-set `maxHitPoints`)
- Solved the "enemies all move at one fixed speed" architectural constraint without restructuring `GamePath` (whose `movementSpeed` stays a fixed, path-level constant): `startMoving` now computes `let speed = path.movementSpeed * type.speedMultiplier` and uses that for its travel-duration/velocity math — Soldier's 1.0× exactly reproduces the original behavior, while Scout/Tank get meaningfully different paces with a one-line change at the point of consumption
- Visual identity comes from recoloring the shared toy-tank hull/turret and uniformly rescaling the chassis — the same "shared silhouette, distinct livery" technique two of the four towers (Red/Blue) already use, and squarely in `AGENTS.md`'s "use placeholder assets" spirit. Tracks, barrel, and highlight stay a shared neutral "machine" palette across all three types — only the "paint job" and size change
- `WaveManager.WaveDefinition` gained `availableEnemyTypes: [EnemyType]`; each spawn now calls a new `randomEnemyType(from:)` to pick uniformly at random from that wave's set — wave 1 mixes Soldier/Scout only (easing the player in), wave 2 onward folds in the Tank. A simple, formula-friendly ramp that mirrors how `enemyCount`/`spawnInterval` already scale with wave index
- Stats were chosen to keep every counter "soft," per the documented guidance: every type remains killable — if inefficiently — by the whole tower roster (no hard counters, no enemy favored or punished by exactly one tower type)
- Corrected a stale `GAME_DESIGN.md` claim ("basic 1 HP combat health") to describe the real roster and stats — the actual baseline has been 5 HP (now Soldier's value, since rebalanced — see below) since the fractional-health work landed
- **Follow-up balance pass (same day)**: bumped `maxHitPoints` +50% across the board per the user's direct request — Scout 3→5, Soldier 5→8, Tank 12→18 (× 1.5, rounded to the nearest whole point, rounding the two half-point cases up so "increase HP" reliably means more HP for every type). Relative ratios — and therefore the soft-counter balance already checked against tower DPS — are preserved; every fight just takes proportionally longer now (see `DECISIONS.md`)

## Previous Milestone — Green "Missile Pod" Visual Redesign

The Green tower and its projectile have a distinct new look — no longer a re-tinted copy of the round chassis + glow-ball every other type uses:

- New `makeArmoredDeck(type:)` gives Green its own rectangular "armored launch deck" chassis (rounded rect + specular highlight + four corner rivets), sized so its footprint matches the shared round plate's radius — replacing the round base plate the same way Pink's hexagonal "energy platform" already stands apart from it. `PlaceholderTower.init`'s chassis branch is now a three-way `switch` over `type` (Pink / Green / Red+Blue) instead of an `if`/`else` framed around Pink alone
- `TowerGunFactory`'s Green case was rebuilt from "circular turret + floating pod + paired tubes" into "rectangular swivel mount + one solid launcher hull + twin recessed launch holes" — a single rectangular mass fills the tower's center (no more empty-feeling circle peeking out from behind thin barrels), and even the rotation pivot itself now reads as a piece of hardware
- New `ProjectileVisualStyle { case orb; case rocket }` enum (+ `TowerType.projectileVisualStyle`, `.rocket` only for Green) lets `PlaceholderProjectile` carry two complete look-and-feel variants — the shared glow-behind-core "orb" every type still defaults to, and a new "rocket": an elongated tapered body + nose cone (tinted in the tower's signature color) + tail-mounted glow-behind-core exhaust (warm orange "rocket flame," recolored from the same visual grammar as the orb). Both variants are built once in `init` and toggled per-use in `configure(color:radius:style:)`, so pooled projectiles can switch styles cleanly between reuses
- The rocket rotates to face its direction of travel in flight — `startHomingTravel` reuses `aim(at:)`'s exact `atan2(dy, dx) - (.pi / 2)` formula on the per-frame `dx`/`dy` it already tracks (the direction toward a homing target IS its heading, so no new state is needed), and periodically drops a small drifting smoke puff (`spawnSmokePuff`, the same spawn → scale+fade-out → remove pattern as `showImpactFlash`) as a sibling node in the scene — building a trail that stays put in world space while the rocket streaks onward
- `ProjectileManager.firePlaceholderProjectile`/`TowerManager`'s call site now thread a `style: ProjectileVisualStyle` parameter through to `configure`, alongside the existing `color`/`radius`

## Previous Milestone — Tower Upgrades

Tower upgrades are now live — every tower can be improved twice after placement (3 total "stages": base, +1, +2):

- Tap a selected tower to reveal *two* badges now: the existing gold "refund" sell badge below it, and a new cyan "▲ cost" upgrade badge above it — same dark-pill tap-to-act shape and `nodes(at:)` name-matching pattern (`"UpgradeBadge"`), just recolored (cash-out gold vs. spend-to-improve cyan), repositioned (below vs. above), and iconified differently (coin vs. up-chevron) so the two opposite-intent actions read unambiguously at a glance without crowding either pill
- Tapping the upgrade badge spends coins (gated through the same `EconomyManager.canAfford`/`spend` the placement and selling flows already use), bumps the tower's `upgradeLevel` by one, refreshes the badge in place (new cost, or it disappears entirely once `TowerType.maxUpgradeLevel` is reached), and adds one more small glowing "tier pip" to a cluster sitting just under the tower's base plate — a permanent, at-a-glance readout of how invested this specific tower is, tinted in its own `turretColor` and built from the same "glow behind a bright core" visual language as the energy-vent glows and muzzle flashes
- Per the confirmed design, upgrades scale **damage/DPS only** — `range`, `attackCooldown`, and every other per-type stat stay fixed identity, untouched by upgrade level. Each tier adds a flat +50% of the tower's *base* output (1.0× → 1.5× → 2.0×, additive not compounding) — equally-sized, easy-to-communicate jumps. `TowerType.damageMultiplier(atUpgradeLevel:)` is the single source of truth for the curve; `PlaceholderTower.currentDamage`/`currentDPS` apply it per-instance (mirroring how `TowerType.dps` already derives style-aware base figures) and are now what `TowerManager.updateCombat`/`updateBeamCombat` actually fire with — `tower.type.damage`/`.dps` remain the *base* reference figures the static ARSENAL panel quotes
- `currentDamage` *ratchets* each tier up by at least +1 over the previous rather than independently rounding `base × multiplier` — a real failure mode surfaced during design: Red's base damage of 1 makes `1 × 1.5 = 1.5` and `1 × 2.0 = 2.0` both round to 2, so its second upgrade would otherwise be a pure no-op (the player pays coins for literally nothing). The ratchet guarantees every purchased tier visibly does *something* for every tower in the roster, while leaving towers whose curve already lands cleanly (Green, Blue) completely untouched
- Cost ramps per tier off the tower's own placement price — tier 1 ≈ 60% of cost, tier 2 = 100% of cost (`TowerType.upgradeCost(fromLevel:)`) — so fully maxing out one tower is a deliberate, escalating commitment rather than an afterthought once coins pile up. `upgradeLevel` lives directly on `PlaceholderTower` (`private(set) var`, mutated only via `upgrade()`) — it's part of "what this tower currently is," alongside its immutable `type`, not combat-scheduling bookkeeping like `TowerManager`'s per-buildspot cooldown/lock dictionaries
- `sellRefund` is no longer a flat `cost / 2` constant — `TowerType.sellRefund(atUpgradeLevel:)` now returns half of the tower's *total* investment (`totalInvestedCost` = placement + every upgrade purchased), so selling an upgraded tower returns a fair share of everything spent on it. `TowerManager.totalCoinsInvested` (the Pause-menu stat) was updated the same way

## Previous Milestone — Pink "Laser Lance" Tower

A fourth tower type, the continuous-beam Laser Lance, is now live:

- New `TowerAttackStyle { case projectile; case beam }` cleanly separates the established discrete-shot combat model (Red/Green/Blue — completely untouched) from the new persistent-beam model (Pink only); `TowerType.dps` is now style-aware, deriving from `damage`/`attackCooldown` for projectile towers and reporting `laserDamagePerSecond` directly for beam towers
- Pink ("Laser Lance", 75 coins — vs. 50 for the others) locks onto a single target like every other tower, but instead of firing discrete shots it projects a persistent glowing neon-red beam at that target for as long as the lock holds, dealing continuous damage every frame at ≈ 4.5 DPS — the highest single-target DPS in the roster, justifying its premium cost. Its housing keeps a pink/magenta chassis identity, but the beam itself (and the plasma-burn mark it leaves on contact) glows a vivid "laser red" — a deliberate contrast chosen to read as hot and electric
- Pink also stands apart structurally, not just chromatically: `PlaceholderTower.init` now branches on `type` so the Laser Lance sits on a unique angular hexagonal "energy platform" (built from a new `polygonPath(sides:radius:rotation:)` trig helper) ringed with three small glowing power vents — tinted in its own neon-red `projectileColor` — instead of the round toy-turret base + specular highlight every other tower shares. A new `startEnergyVentPulse` loop kicks off once, at placement time (not lazily on first fire, unlike the beam's pulse), idly breathing each vent out of phase with the others — the "always charged and ready" personality is visible the instant the tower is placed, before it ever locks a target
- The Laser Lance also now *sounds* different, not just looks different: the instant its beam locks onto a target — "the laser starts heating" — a punchy "ignition" cue plays once. It's the project's first real recorded sample (every other sound is procedurally synthesized): the first second of a user-supplied laser-gun recording, trimmed and converted via `ffmpeg` to the project's standard 22050Hz mono 16-bit format (`tower_beam_pink_start.wav`). Architecturally it's the simplest possible fit — a plain one-shot fired through the same `SKAction.playSoundFileNamed(_:waitForCompletion: false)` every other tower sound already uses, gated on `isSoundEnabled`, with zero new looping/scheduling machinery. The only new piece is detecting *when* to fire it: `TowerManager.triggerLaserIgnition` compares each frame's "is the beam projecting now" against a per-build-spot `beamActiveByBuildSpotID` memory of last frame's state, and fires exactly on the off → on transition — once per lock-on, never on every frame the beam stays lit. That memory is reset to `false` (not left stale) the instant the beam goes silent — lock lost, target killed, tower sold, or scene reset — so the next lock-on always ignites fresh
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
