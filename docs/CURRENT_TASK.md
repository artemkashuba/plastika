# CURRENT_TASK.md

## Current Status

Red "Autocannon" twin-turret redesign (housing + barrels cycling into it) — complete.
Orphaned missiles land & detonate (homing missile commits to road on target loss) — complete.
Haptics (`HapticsManager` — tactile feedback on key moments, persisted pause-menu toggle) — complete.
Missile Pod rework (long-range support: +75% range, slow rockets, +30% DPS, visible trail) — complete.
Sluggish Mortar + per-type turret traverse (rate-limited aiming, target commitment) — complete.
Serpentine map + underground tunnel (gameplay + real-life portal visuals) — complete.
Visual feel pass (hit flash, screen shake, dust, rumble, spawn pop) — complete.
Environment depth pass (wood frame, vignette, cloud shadow, ambient sway) — complete.
Decorative tabletop scenery (trees/bushes/rocks/tufts + spawn & base markers) — complete.
Blue "Mortar" redesign (lobbed arc + splash explosion, area/crowd-control niche) — complete.
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

Add main menu, or add level select (next unchecked Phase 2 items in `TODO.md`). The remaining
"total time control" / "total information" UX items are also open.

## Previous Milestone — Red "Autocannon" Twin-Turret Redesign

The Red gun read as "two floating barrels on a disc" — it had only a small pivot circle and
two thin barrels, no gun body. Redesigned into a proper twin-autocannon turret (user-chosen
shape + recoil; see `DECISIONS.md` 2026-06-12):

- New geometry in `TowerGunFactory`'s `.red` case: a chunky rounded **housing** (rect 22×19,
  bright `turretColor`, glossy specular highlight, a domed commander's hatch with a glint) plus
  a darker front **mantlet** the barrels emerge through. All of this sits on `aimNode` — it
  rotates to aim but does NOT recoil
- The two barrels (now longer, 25pt, with dark muzzle bores) live on `barrelNode` and are
  layered *below* the housing/mantlet, so when only `barrelNode` recoils they visibly slide
  back **into** the turret and spring out — reading as a rapid-fire autocannon cycling rather
  than the whole turret kicking. `tipOffset` moved to (0, 29) for the longer barrels
- No gameplay change — purely the gun's look. Verified in the simulator (idle + rotated) via a
  throwaway debug placement, then removed; full UI suite green (Red pixel detection unaffected)
- Corrected a stale `GAME_DESIGN.md` figure while there: Red's cooldown is 0.28s (the doc said
  0.36s; the ≈3.6 DPS already matched 0.28)

## Previous Milestone — Orphaned Missiles Land & Detonate

A homing Green missile whose target died or breached mid-flight used to simply vanish in the
air (`completion(false)`, no impact) — an immersion break the user flagged. Now it commits to
the ground:

- `PlaceholderProjectile.startHomingTravel` tracks `lastKnownTargetPosition` (updated every
  frame the target is still live) and an `isCommittingToGround` flag. When
  `targetPositionProvider()` first returns nil, instead of aborting it flips the flag and keeps
  flying straight to that last-known road spot — still rotating and trailing smoke — then
  detonates on arrival
- The road detonation is **cosmetic**: `completion(false)` keeps it off the normal hit path
  (no damage, no `enemy_hit` sound, no standard impact flash), and a new
  `spawnLandingExplosion(at:)` draws a color-matched flash + expanding shockwave ring (the
  missile's own lime, deliberately small and *not* the Mortar's big fiery orange, so Green
  gains no AoE and the Mortar keeps its niche). Built from the same transient self-removing
  sibling-node pattern as `spawnSmokePuff`
- The 2.6s flight-timeout fallback also detonates if it was mid-commit, so the "a fired missile
  always resolves on the road" guarantee holds even for a rare long chase. The projectile's
  configured `color`/`radius` are now cached in `configure` for the color-matched blast
- Generalized in `startHomingTravel` (not Green-specific code), so any future homing projectile
  inherits the behavior. No balance change — purely the resolution of an already-spent shot

## Previous Milestone — Haptics

Tactile feedback is now wired across the game's key moments via a new `HapticsManager`,
mirroring the sound model end-to-end (see `DECISIONS.md` 2026-06-12):

- `HapticsManager` (new `Managers/` file, registered in the classic pbxproj) owns the UIKit
  feedback generators, keeps them warm with `prepare()`, and gates every fire path on a single
  `isEnabled` flag. Device-only — generators no-op on the simulator
- Persisted toggle lives on `GameStateManager` as `@Published isHapticsEnabled` +
  `setHapticsEnabled` (UserDefaults key `hapticsEnabled`, defaults ON), exactly paralleling
  `isSoundEnabled`; a new **Haptics** row in `PauseMenuView` mirrors the Sound row. GameScene
  syncs the flag and re-`prepareAll()`s via `onHapticsEnabledChange`
- Event mapping: tower **place** = medium, **upgrade** = rigid (crisper than place), **sell** =
  light; **mortar detonation** = heavy (paired with the explosion + screen shake); **enemy
  kill** = light but throttled; **base breach** = warning notification; **victory** = success,
  **defeat** = error; **HUD buttons** (pause/restart) = selection
- Per-shot firing is deliberately **not** hapticized — the Autocannon fires every 0.28s, which
  would buzz continuously; the Mortar's heavy detonation carries the "heavy weapon" beat instead
- Kill/detonation taps share a throttle (0.11s) in `HapticsManager`: the mortar's forced heavy
  boom resets the window so a splash that kills a cluster collapses to one boom, not a buzz.
  Wired into the two combat hubs via weak refs (`EnemyManager.killAndRecycle` for all damage
  kills, `TowerManager`'s mortar onImpact for the detonation), set once in `setupCallbacks`
- Also widened the fires-test clear-field poll (40 → 70 iterations): it was racing the narrow
  gap between wave 1 dying and the larger wave 2 spawning under full-suite load (unrelated to
  haptics, which no-op in tests). Full suite green

## Previous Milestone — Missile Pod Rework (Long-Range Support)

Green's stats and presentation were reworked to the user's numbers (see `DECISIONS.md`
2026-06-12):

- `TowerType.range` is per-type for the first time: Green 306 (+75%), everyone else 175.
  `TowerManager`'s redundant `placeholderAttackRange` constant was removed in favor of
  `tower.type.range`, and the shared selection range indicator re-sizes its circle path per
  selection (`moveRangeIndicator(to:radius:in:)`) instead of being built once at 175
- Rockets cruise at 168 (−30%) — homing guarantees the hit, and the slower flight shows off
  the trail across the long range
- Damage +30% as a heavier 3-damage warhead on a 0.75s cooldown → DPS exactly 4.0 (integer
  damage can't express 2.6, so the cooldown absorbs the remainder)
- Smoke trail is now clearly visible: brighter puffs (white 0.82 @ 0.85 alpha vs the old
  near-transparent 0.60 @ 0.50×0.55), bigger (3.0pt), denser (every 0.045s), longer-lived
  (0.7s fade)

## Previous Milestone — Sluggish Mortar + Per-Type Turret Traverse

User feedback: the Blue tower targeted too fast ("circle speed" too high) and needed
sluggishness. Implemented per the discussed decisions (see `DECISIONS.md` 2026-06-12):

- `PlaceholderTower.aim(at:deltaTime:)` is now rate-limited — shortest-arc rotation capped at
  `TowerType.traverseSpeed × deltaTime` per frame (Red 10 / Pink 12 / Green 6 / Blue 1.8 rad/s).
  Cosmetic only: firing never waits for alignment, so combat output is unchanged
- `updateMortarCombat` commits to its target via the shared `TargetLock` dictionary (valid
  while targetable + in range — tunnel dives break it) instead of re-picking the lead enemy
  every frame, which was the real source of the tube whipping around
- Mortar tempo deepened: 1.85s cooldown (reload ring sweeps slower automatically) with a
  heavier 5-damage shell — DPS ≈2.70 vs the old ≈2.86, near-parity by design
- Aim UI test moved to spot id 0 with a 1.3s post-placement wait (covers the slow traverse);
  fires-test projectile check now asserts lime-pixel *variance* over 16 samples instead of
  racing a single baseline screenshot against the fire cycle. Full suite green

## Previous Milestone — Tunnel Visuals + Visual Polish Pass

The serpentine relayout's tunnel got its proper "real life" presentation, and the whole board
got a feel/depth pass:

- **Tunnel reads as underground**: `PathManager.makeAbovegroundRoadPath` strokes the road only
  over above-ground segments (a `move(to:)` restarts it past each tunnel), so grass simply
  continues over the buried stretch — no colored band or outline of any kind (user direction:
  "like in real life, indicated at the enter/exit"). `tunnelPortal(at:rotation:)` builds a
  grassy hillside mound + stone facade + dark arched opening at each mouth, rotated so the
  opening lines up with the *above-ground* road it connects to (entrance faces the arriving
  road, exit faces the resuming road) — the asphalt runs straight into the dark mouth.
- **Dive/emerge animations**: `PlaceholderEnemy.setInTunnel` now no-ops on non-transitions and
  animates real transitions — sink (scale 0.35 + fade, 0.16s) into the entrance, pop-out
  (overshoot to 1.1 then settle) at the exit, both kicking up portal dust (`spawnTunnelDust`).
  Gameplay state still flips instantly; `reset()` clears the transition action and restores
  node scale/alpha for pooling safety.
- **Enemy motion life**: an idle "engine rumble" (seamless sine bob + micro-roll on a new
  `hullGroupNode` holding hull/turret/barrel/highlight, tracks staying planted), a periodic
  dust trail behind driving enemies (`spawnTrailDust`, throttled by type speed, skipped
  underground), and a spawn pop (scale-up with overshoot + fade-in) when placed on the table.
- **Hit feedback**: a pre-built white `hitFlashNode` overlay flashes on every discrete hit
  (beam damage deliberately excluded — it has the plasma burn). Mortar detonations and base
  breaches now shake the screen via a center-anchored `SKCameraNode` (render-identical to no
  camera) and a `shakeScreen` SKScene extension that always lands back exactly at center.
- **Environment depth**: a wooden tabletop frame (+ faint grain lines) under the grass mat, a
  soft two-ring vignette over the grass, a barely-there cloud shadow drifting across the table
  on a long loop, gentle out-of-phase sway on trees/bushes/grass tufts (deterministic
  per-position phase), and fluttering camp/base pennants (xScale flap around the pole).
- **UI tests realigned**: all six tests updated for the 8-spot serpentine layout; fixed the
  stale 3-option menu-offset assumption (4 options since Pink: `(index − 1.5) × 52`) and the
  stale magenta projectile predicate (now Green's lime); fires-test reinforces the defense,
  polls for a clear battlefield, and excludes the HUD (red hearts match the deep-red enemy
  predicate). Full suite green.

## Previous Milestone — Decorative Tabletop Scenery

The battlefield was a bare green slab with a road through it; it's now dressed with static toy
scenery and objective markers, breaking up the empty green and improving readability without
touching gameplay.

- New `SceneryFactory` (enum, mirroring `TowerGunFactory`'s shape) builds one container node
  of all scenery: round "lollipop" trees, triangular pines, bushes, rocks, and grass tufts —
  a mix of ~8 trees/bushes plus rocks and tufts — each with the roster's toy-plastic language
  (soft drop shadow, clean fill, dark outline, specular highlight).
- Two objective markers anchor the route: a khaki enemy **camp** (tent + dark entrance + maroon
  flag) at the spawn, and a friendly **base** bunker (cyan flag) at the path end the player
  defends. They take the path's `start`/`end` points (new `GamePath.endPoint` from the Mortar
  work, reused here) and are nudged slightly inward so they sit on the table, not its edge.
- All hand-placed at **fixed** scene positions in the empty pockets away from the road and the
  five build spots (verified in the simulator — nothing overlaps the road or build plates), so
  the map reads as designed rather than randomized per launch.
- The whole container sits at `zPosition` 6 — above the road (5), below gameplay units
  (enemies 20 / towers / projectiles) — so combat always draws clearly on top (e.g. tanks
  emerge *over* the spawn camp).
- Added once in `GameScene.buildPlaceholderScene` (alongside the table), which runs a single
  time, so the scenery persists across restarts like the table — no per-frame cost, no pooling.
- Purely cosmetic placeholder art in the spirit of `ART_ASSET_BRIEF.md`: the eventual Phase 3
  reskin can swap these procedural shapes for sprites without touching any gameplay wiring.

## Previous Milestone — Blue "Mortar" Redesign

The Blue tower was reworked from a confusing predictive direct-fire "Heavy Cannon" into a
proper **Mortar** — the roster's first area/crowd-control tower. (The old predictive aim fired
*ahead* of the enemy onto empty road, reading as "hitting a random place"; the mortar makes
landing on the road the whole point.)

- **Behavior**: new `TowerProjectileBehavior.mortar`. `TowerManager.updateMortarCombat` picks
  the *lead* enemy (nearest the path end, via new `EnemyManager.leadEnemy`), predicts where it
  will be after the shell's flight time (`position + velocity × mortarFlightDuration`), and lobs
  an exploding shell onto that road point. On impact, `EnemyManager.applyAreaDamage` damages
  every enemy within `TowerType.splashRadius` (55pt), crediting + coin-flying each kill and
  firing each one's death burst. Bypasses the single-target lock/beam path entirely.
- **Shell**: new `ProjectileVisualStyle.shell` + `PlaceholderProjectile.startLobbedTravel` — a
  dark finned bomb whose true `node.position` tracks the straight ground line to the landing
  point (so impact/splash/shadow are exact) while the body floats above on a sine-curve arc and
  a ground shadow grows as it descends. Faked height, no real 3rd dimension. The shell also
  rotates to follow its ballistic tangent (nose-up climbing → level at apex → nose-down
  plunging), derived from its apparent screen-space velocity (ground travel + lift rate of
  change), so it reads as a real arcing round rather than a fixed-upright bomb.
- **Explosion**: `ProjectileManager.fireMortarShell` + `showExplosion` — a fiery orange
  fireball, white-hot core, expanding shockwave ring, and scattered smoke puffs sized to the
  blast radius (same transient-`SKShapeNode` language as the impact flash / death burst).
- **Visual**: `TowerGunFactory` Blue rebuilt as a chunky high-angle mortar — baseplate, bipod
  legs, an upward-flaring tube with cylinder sheen + reinforcement bands, and a 3D angled
  elliptical mouth (steel rim, dark bore, specular glint). The tube swivels to the landing
  bearing and recoils down on launch.
- **Sound**: the existing blue artillery boom moved from the launch to the **explosion** moment.
- **Balance** (per user's calls): kept slow & heavy (~1.4s reload), 4 damage, 55pt blast,
  lead-enemy targeting, fiery-orange look. Single-target DPS unchanged (≈2.9); the upgrade is
  the area damage. Pause ARSENAL now shows a SPLASH chip for it. The other three towers are
  untouched.

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
