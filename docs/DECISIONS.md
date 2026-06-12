# DECISIONS.md

## 2026-06-05

Decision:
Use SpriteKit instead of Unity.

Reason:

- iOS only
- Better native integration
- Lower memory footprint
- Faster iteration

Decision:
Use fixed tower build spots.

Reason:

- Easier balancing
- Faster implementation
- Better mobile UX

Decision:
Monetization will be:

- Remove Ads
- Cosmetic skins

Reason:
Avoid pay-to-win mechanics.

Decision:
Use `docs/` as the canonical project documentation location.

Reason:

- Documentation is the project source of truth
- Future implementation work needs one clear workflow entry point
- Duplicate editable documentation paths create drift

Decision:
Use a SwiftUI app entry point with `SpriteView` to host SpriteKit scenes.

Reason:

- Provides native iOS lifecycle support
- Keeps scene loading explicit and lightweight
- Avoids adding UIKit boilerplate before it is needed

Decision:
Use placeholder manager types composed through `GameSystems`.

Reason:

- Matches the documented manager architecture
- Keeps `GameScene` from owning unrelated implementation details directly
- Establishes boundaries before gameplay systems are implemented

Decision:
Do not use MVVM for the initial game shell.

Reason:

- The current scope is scene loading and game state management
- SpriteKit gameplay logic does not benefit from MVVM yet
- Simpler structure supports faster prototype iteration

Decision:
Use a `PathManager` with hardcoded `CGPoint` waypoints for the first gameplay slice.

Reason:

- Keeps the first path visible and easy to tune
- Avoids map data parsing before the prototype needs it
- Gives future movement and wave systems a clear source for route data

Decision:
Move the placeholder enemy with SpriteKit actions instead of physics.

Reason:

- Smooth waypoint movement does not need physics simulation
- Avoids unnecessary per-frame logic for the first slice
- Reuses a single enemy node instead of creating and destroying nodes repeatedly

Decision:
Use finite prototype wave data in `WaveManager`.

Reason:

- Keeps spawn count and spawn cadence explicit
- Replaces the temporary single looping enemy with a real wave slice
- Lets `GameScene` stay thin by delegating spawn timing to a manager

Decision:
Use a lightweight placeholder enemy pool in `EnemyManager`.

Reason:

- Avoids repeated node creation during gameplay
- Gives `EnemyManager` ownership of active and reusable enemies
- Keeps enemy removal and reuse separate from `GameScene`

Decision:
Use `BuildSpotManager` for visual-only fixed build spots.

Reason:

- Keeps static battlefield placement visuals out of `GameScene`
- Preserves the fixed build spot decision without adding tower gameplay yet
- Allows build spot nodes to be created once per scene instead of during updates

Decision:
Use `UIManager` for the small prototype debug HUD.

Reason:

- Keeps HUD node ownership separate from scene setup
- Allows `GameScene` to provide only lightweight state values
- Avoids placing large explanatory text in the battlefield center

Decision:
Use `BuildSpotManager` for build spot hit testing and occupancy tracking.

Reason:

- Keeps fixed build spot state close to the build spot data
- Lets `GameScene` route tap input without owning placement rules
- Prevents duplicate tower placement on the same build spot before economy exists

Decision:
Use `TowerManager` to place placeholder tower nodes keyed by build spot id.

Reason:

- Keeps tower node ownership separate from build spot rendering
- Gives the first tower placement slice a clean upgrade path toward combat later
- Avoids adding selection, economy, range, or projectile behavior before the prototype needs it

Decision:
Use a narrow UI test for tower placement verification.

Reason:

- Verifies the real tap path without adding debug-only gameplay hooks
- Confirms placeholder tower pixels appear after the first tap
- Confirms a repeated tap on the same build spot does not create another visible tower

## 2026-06-06

Decision:
Use `TowerManager` for the first combat tick.

Reason:

- Keeps `GameScene` thin by making it call one manager update method
- Keeps tower cooldown, range, and targeting behavior close to placed tower state
- Allows future tower behavior to expand without moving combat logic into scene code

Decision:
Use nearest-enemy targeting within an internal placeholder range.

Reason:

- Simple enough for the first combat slice
- Easy to verify visually
- Avoids adding range indicators, targeting modes, or tower type complexity early

Decision:
Use `ProjectileManager` for pooled placeholder projectile travel.

Reason:

- Keeps projectile node ownership and reuse separate from towers
- Avoids SpriteKit physics for the first combat loop
- Lets projectiles remain visible placeholder feedback without adding collision systems yet

Decision:
Use `EnemyManager` for basic HP damage, death, removal, and recycling.

Reason:

- Enemy lifecycle already belongs to `EnemyManager`
- Prevents towers or projectiles from mutating active enemy tracking directly
- Keeps one-hit prototype enemy death simple and leak-resistant

Decision:
Use a UI test for the first combat loop.

Reason:

- Exercises the real tap-to-place path
- Confirms placeholder projectile pixels appear after tower placement
- Confirms enemy pixels disappear after the tower has time to attack the wave

Decision:
Extend `TowerManager` for tower selection and range visualization instead of adding a separate manager.

Reason:

- Selection state is currently tied to placed tower ownership and attack range
- Keeps `GameScene` thin by routing taps through the existing tower boundary
- Avoids a new abstraction before upgrades, selling, or tower menus exist

Decision:
Reuse one `SKShapeNode` range indicator for the selected tower.

Reason:

- Visualizes the actual placeholder attack range without duplicating range constants
- Avoids repeatedly allocating range nodes during selection switching
- Keeps the indicator lightweight with a thin translucent white outline

Decision:
Let `PlaceholderTower` own its selected visual treatment.

Reason:

- Keeps highlight rendering close to the tower node hierarchy
- Allows `TowerManager` to manage selection state without micromanaging child nodes
- Supports smooth 0.18 second scale animation and a thin white selection ring

Decision:
Add UI verification for selection, switching, and deselection.

Reason:

- Confirms tapping a placed tower shows a range indicator and highlight
- Confirms tapping another placed tower moves selection and range
- Confirms tapping empty battlefield clears the selection without breaking placement or combat tests

Decision:
Store tower target locks in `TowerManager` by build spot id.

Reason:

- Tower ownership, attack range, cooldowns, and target selection already live in `TowerManager`
- Keeps `GameScene` unchanged and thin
- Prevents towers from switching targets while a locked target remains alive, in range, and tracked

Decision:
Validate target locks with enemy life ids managed by `EnemyManager`.

Reason:

- Enemy nodes are pooled and can be recycled
- A life id prevents a recycled enemy object from being treated as the same target life
- Damage application can safely ignore projectile impacts against stale targets

Decision:
Fire projectiles at a captured target position instead of a live enemy node.

Reason:

- Each shot travels in a straight line toward the target position at fire time
- Projectile pooling remains unchanged
- Target validity and damage remain under `EnemyManager`

Decision:
Rotate only the placeholder tower turret/barrel node for aiming.

Reason:

- Makes aiming visually clear without rotating the tower base or selection ring
- Keeps placeholder art lightweight
- Avoids adding final art, physics, or extra tower systems during the prototype

Decision:
Use `TowerType` as the single model for prototype tower identity and tuning.

Reason:

- Keeps each tower's color, attack cooldown, projectile speed, and projectile behavior together
- Lets `TowerManager` create typed towers without branching across scene input code
- Gives Red, Green, and Blue towers a small, explicit upgrade path for future balancing

Decision:
Let `BuildSpotManager` own the lightweight tower build menu.

Reason:

- Build spot hit testing, active empty spot state, and occupancy already live in `BuildSpotManager`
- Reusing one menu node avoids unnecessary allocation while tapping between spots
- `GameScene` can keep routing taps without owning menu layout or placement rules

Decision:
Support direct and homing projectile behaviors in `ProjectileManager` while keeping projectile nodes pooled.

Reason:

- Red and Blue towers can fire direct projectiles with their own speeds
- Green towers can follow a valid locked target without adding physics
- Projectile ownership, reuse, and cleanup remain separate from tower and enemy managers

Decision:
Leave Blue tower predictive aiming as a documented future TODO.

Reason:
- Predictive aiming depends on enemy speed, lead tuning, and broader combat balance
- The current slice only needs Blue to be a slow direct projectile tower
- Deferring it keeps this implementation scoped to the tower type menu and first typed behavior pass

## 2026-06-06 (Shooting Improvements)

Decision:
Fix homing (Green) projectile range abort by separating target-locking validity from in-flight validity.

Reason:
- isValidTarget includes a range check meant for acquiring new targets, not for mid-flight tracking
- A fired homing missile should follow its target until impact regardless of tower attack range
- Added isTrackedAndAlive to EnemyManager — checks lifeID validity only, no range — used exclusively in the targetPositionProvider for in-flight homing projectiles

Decision:
Add per-tower projectile colors instead of a uniform magenta.

Reason:
- Distinct colors (Red = orange, Green = lime, Blue = cyan) make combat much more readable
- Matches the tower's visual identity and helps the player track shots
- Trivial to implement via configure(color:) on PlaceholderProjectile

Decision:
Implement predictive aiming for Blue tower using quadratic intercept math.

Reason:
- Blue fires slow projectiles making it nearly miss any moving target at current position
- PlaceholderEnemy now tracks velocity per path segment, enabling exact intercept calculation
- The intercept point is clamped to the projectile's travel time; if no valid intercept exists, falls back to current enemy position

Decision:
Add an impact flash effect at the projectile's hit position.

Reason:
- Gives the player clear visual feedback that a hit occurred rather than the projectile silently disappearing
- Implemented as a pooled-free short-lived SKShapeNode (expand + fade in 0.18s) added directly in ProjectileManager
- Color matches the tower's projectile color for consistent visual language

## 2026-06-06 (Economy)

Decision:
Set all prototype tower costs to 50 coins and all kill rewards to 10 coins, with 150 starting coins.

Reason:
- Uniform cost keeps the prototype simple and easy to balance later
- 150 coins allows exactly 3 towers before the player must earn more
- 10 coins per kill means 5 kills recover one tower placement, keeping the economy loop tight
- Specific values can be tuned per tower type in a later pass

Decision:
Store tower cost on `TowerType` and kill reward on `PlaceholderEnemy`.

Reason:
- Cost belongs to the tower type definition alongside cooldown and projectile behavior
- Kill reward belongs to the enemy entity so different enemy types can reward different amounts later
- Keeps `EconomyManager` free of game-balance constants

Decision:
Credit kill rewards in `TowerManager.updateCombat` via the `onImpact` closure.

Reason:
- Kill confirmation already happens inside the impact closure
- Avoids adding an economy callback to `EnemyManager`, which would couple it to economy
- Captures `killReward` by value at fire time so a recycled enemy cannot affect the credit amount

## 2026-06-06 (Enemy HP and Tower Damage)

Decision:
Set prototype enemy HP to 5 and keep all projectile damage at 1 except Blue which deals 2.

Reason:
- 5 HP makes combat readable and enemies feel durable without being bullet sponges
- Red and Green stay differentiated by fire rate and projectile behavior alone
- Blue's 2 damage compensates for its 0.90s cooldown, giving it a distinct role as a slow heavy hitter
- HP and damage values are easy to tune per enemy and tower type in future passes

Decision:
Show a color-coded health bar above each enemy only after the first hit.

Reason:
- Hiding the bar at full health avoids visual clutter when enemies first spawn
- Green → yellow → red color coding gives instant health-state readability without numbers
- Left-aligned xScale shrink avoids recreating the SKShapeNode path each frame

Decision:
Dim unaffordable build menu options to alpha 0.4 and block their taps silently.

Reason:
- Visual dimming gives the player immediate feedback without adding a separate error UI
- Silent block is consistent with the existing silent duplicate-placement block
- Alpha 0.4 is visually clear on the colored option circles without requiring new art

## 2026-06-06 (Proper HUD)

Decision:
Replace the debug overlay with a full-width top-bar HUD: coin icon + count (left), wave badge (center), heart icons for lives (right).

Reason:
- The debug panel was sized and styled for debugging, not player readability
- A top bar is the standard TD HUD pattern and matches the game's tabletop framing
- Placeholder shapes (circle coin, ♥ hearts) keep the implementation simple while being immediately readable

Decision:
Drop `activeEnemyCount` from `UIManager.update()`.

Reason:
- Enemy count was a debug convenience, not a designed UI element
- The proper HUD does not show it; the wave badge + lives convey the same gameplay state
- Removes unnecessary coupling between UIManager and EnemyManager count

Decision:
Represent lives as individual heart `SKLabelNode` nodes (♥ character) colored red (alive) or dark gray (lost).

Reason:
- Avoids bezier path heart geometry for placeholder art
- Individual nodes make per-life state updates trivial
- Easy to swap for sprite art later

Decision:
Animate heart loss with a pop-then-fade: scale up to 1.55× (0.09s), then simultaneously scale back to 1.0× and interpolate `fontColor` from red to dim grey (0.22s). Dim target is `white: 0.50, alpha: 0.90`.

Reason:
- Instant color change on a small ♥ glyph is easy to miss — the pop gives a physical "hit" sensation
- `SKAction.customAction` lets us interpolate `fontColor` smoothly, which SpriteKit has no built-in action for on `SKLabelNode`
- All three RGB channels must target the same grey value (0.50); original code had a copy-paste bug where the blue channel used the alpha target (0.72) instead of the grey target (0.28/0.50), producing a barely visible blue-tinted heart
- `white: 0.50` at `alpha: 0.90` is clearly visible against the dark HUD bar; `white: 0.28` was too dark
- Using `withKey: "heartLoss"` prevents stacking if two enemies breach in quick succession
- `currentHealth` is tracked on `UIManager` and reset in `resetForNewScene()` so restart always starts clean at 3

Decision:
Force `uiManager.update()` in `handleEnemyReachedEnd()` and delay the game-over overlay by 0.36s.

Reason:
- When the last life is lost, `markGameOver()` stops the `GameScene.update()` loop immediately; without a forced update, `updateHearts(health: 0)` is never called and the last heart never animates
- Explicit `uiManager.update()` call in `handleEnemyReachedEnd()` triggers the animation for every life loss, not just non-final ones
- Gameplay stops immediately (`markGameOver()` before the delay), so no enemy movement or input processes during the 0.36s window
- 0.36s > total animation duration (0.09 + 0.22 = 0.31s), so the overlay appears just after the animation finishes

## 2026-06-06 (Tower Selling)

Decision:
Show the sell action as a coin icon + refund amount pill below the selected tower, matching the HUD coin cluster style.

Reason:
- Consistent UI language — player already knows the coin icon means currency
- No "Sell" text label needed; the coin amount communicates both action and value instantly
- Matches the build menu's vertical offset pattern (badge appears below the tower, same as build options appear below empty spots)

Decision:
Set sell refund to 50% of tower cost (25 coins for a 50-coin tower).

Reason:
- Penalises misplacement slightly without discouraging experimentation
- Simple fixed ratio; per-tower tuning deferred to balancing pass

Decision:
Manage the sell badge node inside TowerManager alongside the range indicator.

Reason:
- TowerManager already owns selection state, tower nodes, and the range indicator
- Keeping the badge there avoids coupling GameScene or UIManager to per-tower sell logic
- Badge lifecycle (show on select, hide on deselect/sell/reset) mirrors range indicator lifecycle exactly

Decision:
Use `nodes(at:)` name matching ("SellBadge") for sell badge tap detection in GameScene.

Reason:
- Consistent with how RestartButton tap detection already works
- Avoids maintaining a separate tap-radius constant for the badge
- Works correctly regardless of badge position or scene transforms

## 2026-06-06 (Notch / HUD fix)

Decision:
Use `SKScene.convertPoint(fromView:)` to translate `view.safeAreaInsets.top` into scene coordinates and position the HUD bar relative to that boundary.

Reason:
- `SpriteView` uses `.ignoresSafeArea()`, so the scene extends under the notch/island/status bar
- `safeAreaInsets.top` is in UIKit coordinates (top-left origin, y downward); the scene uses bottom-left origin with y upward — direct arithmetic gives wrong results without conversion
- `convertPoint(fromView:)` handles scale, anchor point, and coordinate flip correctly for every device variant (no-notch, notch, Dynamic Island)
- Value is computed once in `didMove(to:)` and reused on restart, avoiding repeated view lookups

Decision:
Hardcode wave number as "WAVE 1" in the HUD for now.

Reason:
- Only one wave exists; making wave number dynamic is deferred to the multi-wave milestone
- Avoids adding a wave parameter to `UIManager.update()` prematurely

## 2026-06-06 (Sound Effects)

Decision:
Generate procedural tactical WAV sounds for each tower type rather than sourcing audio assets.

Reason:
- No external asset dependency; sounds can be regenerated and tuned at any time
- Tactical aesthetic: Red = suppressed crack (0.18s, high-pass noise burst), Green = missile whoosh (0.40s, layered band noise), Blue = artillery boom (0.58s, low sine kick + noise body)
- 22050 Hz mono 16-bit WAV — small file size, native SpriteKit support
- `SKAction.playSoundFileNamed(_:waitForCompletion: false)` run on the tower node at fire time — fire-and-forget, no AudioNode overhead
- `TowerType.shootSound` keeps the filename mapping next to other per-tower constants

## 2026-06-06 (Win/Lose)

Decision:
Use 3 base lives for the prototype.

Reason:
- Tight enough to create pressure against 6 enemies
- Allows the player to learn but punishes ignoring the base
- Easy to tune upward once difficulty and enemy variety exist

Decision:
Use BaseHealthManager as a dedicated manager for base health.

Reason:
- Mirrors EconomyManager pattern — small, single-purpose, easy to reset
- Keeps GameScene thin by delegating health state and reset logic
- Provides a clear home for future base HP upgrades or shield mechanics

Decision:
Detect enemy breach via onEnemyReachedEnd callback on EnemyManager.

Reason:
- The existing movement completion closure already fires only when an enemy reaches the end (reset() strips the action before it can complete when killed)
- No new coupling between managers — GameScene registers the callback and owns the health decrement
- The same callback pattern is used across the codebase

Decision:
Detect victory by polling waveManager.isSpawningComplete and enemyManager.activeEnemyCount in update().

Reason:
- Simpler than a callback chain across WaveManager and EnemyManager
- The phase guard in update() prevents double-triggering
- No window where victory can fire before all enemies are spawned (isSpawningComplete blocks it)

Decision:
Show end-game overlays as in-scene SKNode panels rather than a new scene or SwiftUI layer.

Reason:
- Consistent with the existing SKNode-based UI approach
- No scene transition overhead
- The RestartButton name allows SpriteKit nodes(at:) hit-testing without UIManager needing a public hit-test method

## 2026-06-07

Decision:
Split each tower's gun assembly into a fixed turret (on `aimNode`) and a separate `barrelNode`
holding only the forward weapon geometry (barrels/pod/cannon), exposed via `TowerGunFactory.Assembly`.

Reason:
- Lets the barrel kick backward along the local +y (firing) axis on every shot without moving
  or distorting the turret pivot that the tower rotates around
- Keeps `barrelTipPosition`/`aim(at:)` correct and untouched — recoil is purely cosmetic and
  layered on top of the existing aiming math
- Reuses the existing `Assembly` struct so `BuildSpotManager`'s scaled gun previews are unaffected

Decision:
Drive recoil distance and muzzle-flash size from new `TowerType.recoilDistance` /
`muzzleFlashScale` properties (Red < Green < Blue) rather than reusing `damage` directly.

Reason:
- Keeps the "feel" tuning independent from balance numbers — damage values can change later
  without accidentally throwing off the recoil/flash visuals
- Matches the user's request that heavier guns (Blue Heavy Cannon) recoil more than lighter
  ones (Red Autocannon), using the same weight ordering as damage for consistency
- Explicit per-type constants are easy to tune by feel during playtesting

Decision:
Trigger `playFireEffects()` (recoil + muzzle flash) from `TowerManager.updateCombat` at the
exact moment the shoot sound plays, as a method on `PlaceholderTower` rather than a helper
elsewhere.

Reason:
- `PlaceholderTower` already owns `aimNode`/`barrelTipOffset` — the effects need direct access
  to that internal geometry and rotation state
- Co-locating with the shot-fired call site keeps sound, recoil, flash, and projectile spawn
  visibly synchronized in one place
- Matches the established pattern (selection ring, sell badge) of keyed `SKAction` sequences
  owned by the entity that displays them

Decision:
Render the reload-timer ring as a radial fill (faint static track + arc redrawn every frame
via `SKAction.customAction`) rather than a literal clock face or discrete pie-wedge steps,
shown only while the tower is reloading (fades in on fire, fades out once ready).

Reason:
- User chose "radial fill ring" + "only while reloading" when offered the visual/visibility
  options — a clock face or stepped wedge would either look busier or move less smoothly
- `SKAction.customAction(withDuration:actionBlock:)` lets the arc's `CGPath` be recomputed
  every frame from `elapsed/duration`, giving a perfectly smooth sweep tied to the tower's
  actual `attackCooldown` with no separate timer bookkeeping in `TowerManager`
- Hiding it when idle (rather than always-on or selection-only) gives moment-to-moment
  feedback on when each tower will fire again without permanently cluttering the battlefield
- Lives on `PlaceholderTower` (a sibling of `aimNode`, not a child) so it doesn't rotate with
  the turret and reuses the same keyed-`SKAction` ownership pattern as recoil/selection

Decision:
Use a single bright white for the reload-ring's progress arc on every tower type, instead of
tinting it to each tower's turret color (`type.turretColor`).

Reason:
- User feedback: per-tower tinting made the ring's color feel inconsistent across the
  battlefield; a uniform white reads as one consistent UI element regardless of tower type
- White also guarantees contrast against all three base-plate colors (red/green/blue) and the
  battlefield background, where a tinted arc could blend into a same-hued tower's own visuals

## 2026-06-07 — Art direction reference & Phase 3 prep

Decision:
Adopt a user-shared reference screenshot (a polished "claymation/plastic-toy" mobile
tower-defense UI) as the north star for the eventual full art pass, source the new
assets via AI image generation, and treat the pass itself as the already-roadmapped
Phase 3 "Replace placeholder art" item rather than starting it now. As immediate prep,
draft `docs/ART_ASSET_BRIEF.md` — a style guide, asset inventory, technical spec sheet,
and AI-prompt-template set the eventual pass can pick up and run with.

Reason:
- The reference screenshot lines up almost exactly with the "Plastic toy appearance" /
  "Tabletop battlefield presentation" already written into `GAME_DESIGN.md`'s Art
  Direction section — it's a confirmation of the existing vision, not a pivot
- User chose "AI image generation" as the art source and "treat it as the planned
  Phase 3 polish pass" when offered the options — gameplay work (second wave, upgrades)
  continues uninterrupted, and the reskin happens on its already-planned schedule
- A full reskin requires actual rendered/illustrated assets that don't yet exist —
  writing a brief now (style descriptors, full asset inventory, SpriteKit integration
  plan, ready-to-adapt prompt templates) means that work can start fast and stay
  visually consistent across dozens of generations whenever Phase 3 begins
- The brief explicitly maps onto the existing turret/barrel split
  (`Assembly.aimNode`/`Assembly.barrelNode`) so recoil, aiming, and the reload ring
  keep working unchanged once sprite-based art replaces the procedural shapes

## 2026-06-07 — Second wave & inter-wave countdown

Decision:
Replace the single hardcoded `prototypeWave` with a formula-driven wave script: a
`scriptedWaveCount` constant plus a private `waveDefinition(at:)` generator that derives
each wave's enemy count and spawn interval from a linear difficulty curve (base values +
a fixed per-wave step, spawn interval floored at a minimum). Drive wave-to-wave
progression from a new `WaveManager.updateProgression(...)` call in `GameScene.update(_:)`,
and announce a 3-second "WAVE 2 IN 3…2…1…" countdown via a new `onWaveProgressChanged`
callback the moment all of a wave's enemies are cleared — all without introducing a new
`GamePhase`.

Reason:
- **Formula over a hardcoded per-wave array**: the user explicitly asked that "each level
  should have increased amount of enemies, so the difficulty should grow" as a *standing
  rule*, not a one-off tweak between two waves. A generator centralizes that rule —
  `scriptedWaveCount` alone controls how many waves exist, and every wave it produces is
  guaranteed harder than the last by construction. Adding wave 3, 4, ... later requires no
  manual balancing of individual entries, and the curve (steps + floor) is the single place
  to retune overall pacing
- **Linear curve with a spawn-interval floor**: `baseEnemyCount` (6) + `enemyCountStepPerWave`
  (3) and `baseSpawnInterval` (0.85s) − `spawnIntervalStepPerWave` (0.15s), clamped at
  `minimumSpawnInterval` (0.4s) — reproduces the original hand-picked Wave 1 (6 @ 0.85s) /
  Wave 2 (9 @ 0.70s) numbers exactly, while guaranteeing later waves keep escalating without
  ever spawning so fast it becomes unreadable or unfair
- **No new game phase**: the countdown is cosmetic pacing, not a distinct mode — the
  player can keep building, selling, and watching combat resolve during the break, so
  staying in `.sceneLoaded` keeps input/update gating simple and avoids a phase whose
  only job would be "like sceneLoaded, but don't check for the next wave yet"
- **3-second countdown**: long enough to read clearly as "3…2…1…go" and give the player
  a breather/regroup moment, short enough that it doesn't feel like dead air on a short
  multi-wave slice
- **`isAdvancingToNextWave` guard**: `updateProgression` runs every frame while
  `activeEnemyCount == 0`; without a latch it would re-enter and restart the countdown
  (or re-trigger victory) on every subsequent frame until the next wave's first enemy spawns
- **Callback fires on every wave start, including the first**: rather than special-casing
  "is this the initial wave," `WaveManager` always announces progress through
  `onWaveProgressChanged`. The very first announcement lands before `GameScene` wires the
  callback (ordering of `buildGameplaySlice()` vs. `setupCallbacks()`/`configureOverlay`),
  so `GameScene` explicitly calls `setWave(number:)` once, right after `configureOverlay`
  builds the HUD, to sync the initial "WAVE 1" badge — keeping `WaveManager` simple and
  consistent rather than reordering `didMove`/`restartGame` and risking subtler side effects
- **`PauseStats` gained `waveNumber`/`totalWaveCount`**: the existing "spawned: X/Y" pause
  stat only ever meant "this wave's spawn count," but that was invisible/ambiguous with a
  single wave. Surfacing "ENEMIES — WAVE 1/2" in the section header makes the scope explicit
  now that there's more than one wave to track

## 2026-06-07

Decision:
Add a fourth tower type, Pink ("Laser Lance") — a 75-coin continuous-beam tower that
locks onto a single target and burns it down with a persistent laser, draining its HP
smoothly rather than in discrete per-shot bursts.

Reason:

- The existing roster (Red/Green/Blue) is entirely discrete-projectile; a beam tower
  gives the player a meaningfully different tactical tool (guaranteed, always-on
  single-target damage vs. burst/splash/homing variety) and a reason to pay the premium
- The user explicitly asked for "a laser… aiming to one target… HP star [bar] draining
  smoothly," and selected the "true continuous beam" / "highest DPS (~4.5)" / "new
  beam-focused visual" options when offered alternatives — locking in a from-scratch
  beam combat model rather than reusing the rapid-pulse projectile system

Decision:
Introduce `TowerAttackStyle { case projectile; case beam }` and branch combat/visuals on it,
rather than retrofitting the projectile pipeline to fake a beam.

Reason:

- The existing combat model (`ProjectileManager`, discrete cooldown → fire → impact cycle,
  recoil/muzzle-flash/reload-ring) is fundamentally shot-based; forcing a beam through it
  would mean firing dozens of invisible "projectiles" per second — wasteful and fragile
- A clean style switch lets `TowerManager.updateCombat` and `PlaceholderTower`'s effect
  calls dispatch to the right model with zero risk of changing Red/Green/Blue behavior —
  100% of the existing projectile machinery is untouched
- `dps` becomes style-aware too: projectile towers keep deriving it from `damage`/
  `attackCooldown`; beam towers report `laserDamagePerSecond` directly, since they have
  no discrete shot to derive a rate from

Decision:
Make `PlaceholderEnemy.fractionalHealth: Double` the canonical health value, with the
existing `hitPoints: Int` becoming a ceiling-rounded derived mirror.

Reason:

- "Smooth HP drain" needs sub-1 damage increments (a beam ticks `dps * deltaTime`, often
  a fraction of a hitpoint per frame); an `Int`-only model can only snap the bar between
  whole-HP steps
- Layering `SKAction` tweens onto an `Int` bar (the rejected "rapid-pulse" alternative)
  would fight the bar's existing instant-update logic and complicate kill detection
- Ceiling-rounding `hitPoints` from `fractionalHealth` keeps every existing Int-based
  consumer (`takeDamage`, `hitPoints == 0` kill checks, `isAlive`) numerically identical
  for whole-number damage — Red/Green/Blue see zero behavior change — while
  `updateHealthBar()` now renders the exact fractional remainder for genuinely continuous
  draining under laser fire

Decision:
Draw the beam as a glow+core `SKShapeNode` line pair, parented to `barrelNode` (inside
`aimNode`), redrawn each frame from the barrel tip outward by the tip-to-target distance —
with no recoil, muzzle flash, or reload ring for beam towers.

Reason:

- Because `aimNode` is already rotated toward the locked target via the existing `aim(at:)`
  call, a beam drawn as its child inherits that rotation "for free" — `showBeam` only ever
  needs to recompute the beam's *length*, never its angle, eliminating separate world-space
  math
- Mirrors the existing muzzle-flash "tinted glow behind a bright core" visual language, so
  the new beam reads as part of the same tower roster's visual identity rather than a
  bolted-on effect
- A persistent always-on beam has no discrete "shot" moment to recoil/flash/reload around;
  keeping those effects at `recoilDistance = 0` / `muzzleFlashScale = 0` / `attackCooldown = 0`
  for `.pink` (rather than running them on a fake cadence) avoids visual noise that would
  contradict the "continuous beam" concept

Decision:
Tune Pink to ~4.5 DPS — the highest single-target DPS in the roster — and price it at
75 coins (vs. 50 for Red/Green/Blue).

Reason:

- User-selected option: "Highest DPS, ~4.5" was chosen over "mid-pack DPS (~3) but
  always-on accuracy" when offered the choice
- Existing roster context: Red ≈ 3.57, Green ≈ 3.08, Blue ≈ 2.86 DPS — Pink at 4.5
  is a clear step up, giving the 50% cost premium (75 vs. 50) a concrete payoff
- A guaranteed-hit, always-on-target beam is inherently more reliable than projectile
  travel time/misses/splash falloff, so pairing that reliability with the top DPS makes
  Pink a premium "win more" choice rather than a strictly-better default

Decision:
Give the laser beam a continuous "neon sign" breathing pulse — looping, slightly
out-of-phase alpha and line-width oscillation on its glow and core layers — rather
than leaving it as a static painted line.

Reason:

- A perfectly static beam reads as flat/lifeless next to the rest of the roster's
  animated "feel" (recoil, muzzle flash, reload rings, coin-fly rewards) — direct
  user feedback called the laser out as "looking a bit static"
- Two layers pulsing at different periods with a phase offset (rather than one
  uniform pulse, or both layers in lockstep) is what makes it read as an organic,
  "alive" energy conduit instead of a mechanical blink — mirrors how real neon
  tubes/lasers look slightly unstable rather than perfectly steady
- Driving it off `SKAction.repeatForever`/`customAction` started once at beam-node
  creation (not every `showBeam` frame) keeps it cheap and decoupled from the
  per-frame path redraw — and keeps the loop quietly running while the beam is
  hidden, so re-acquiring a target resumes mid-breath rather than resetting

Decision:
Give the laser a "burn" impact effect — a small flickering plasma cluster (tinted
glow + white-hot core) — at the point where the beam makes contact, owned by
`PlaceholderEnemy` (`showBeamBurn(color:)`/`hideBeamBurn()`) rather than by the
tower or `ProjectileManager`.

Reason:

- Direct user suggestion ("a mini fire animation should appear on the end of laser
  beam"); reinforces the Laser Lance's "burns it down" flavor and pairs naturally
  with the just-finished beam pulse — both push the laser from "static" to "alive"
- The existing one-shot `ProjectileManager.showImpactFlash` is fundamentally the
  wrong shape for this: it's a scene-space flash that fires once and disappears,
  whereas a beam stays locked on a *moving* target for as long as range allows, so
  its impact mark needs to be persistent and need to track that motion every frame
- Parenting the effect to the enemy (at its anchor point — the exact position
  `updateBeamCombat` already aims the beam at) means it tracks the target for free
  with zero per-frame position math, and disappears for free on death/recycle via
  the existing `reset()` path — no new bookkeeping in `TowerManager` beyond
  show/hide calls keyed off the lock state it already tracks
- Colors mirror the tower's own muzzle-flash language (`color`-tinted glow around a
  white-hot core) — a magenta-tinted "plasma burn" rather than generic orange fire,
  so the mark visibly belongs to *this* laser and pops against the enemy's
  red-orange chassis instead of blending into it
- The flicker uses fast, irregular sine-wave combinations (distinct cadence from
  the beam's slow "neon" breathing) so it reads as an erratic flame-lick rather
  than a second metronomic pulse competing with the first

Decision:
Recolor the Laser Lance's beam (and, by extension, its plasma-burn impact mark —
both are tinted from `TowerType.projectileColor`) from hot magenta to a vivid
neon red, while leaving its chassis/housing/lens pink-magenta as before.

Reason:

- Direct user request: "make this laser red, and neon style." When offered the
  choice between recoloring the whole tower (chassis + beam, for visual cohesion)
  or just the beam, the user explicitly chose "just the beam"
- `projectileColor` already does double duty as each tower's "signature effect
  color" distinct from its chassis identity — the Red Tower's chassis is brick-red
  but its actual projectile/effect color is orange, so a beam color that diverges
  from its housing's hue has direct precedent in this roster, not a one-off oddity
- Picked a saturated, blue-leaning crimson (`1.0, 0.10, 0.22`) rather than a warm
  red — it stays clearly distinct from the Red Tower's orange-red effect color, the
  towers' brick-red chassis tones, and the enemy's red-orange hull, so "this is a
  different, electric kind of red" reads instantly rather than blending in
- No code changes were needed beyond the single `projectileColor` case: the beam
  (`showBeam`), its neon pulse (`startBeamPulse`), and its plasma-burn mark
  (`showBeamBurn`) all derive their tint from that one property already

Decision:
Generalize `BuildSpotManager.menuOffset(for:)` from a hardcoded 3-case switch to an
index-based, centered formula over `TowerType.allCases`.

Reason:

- A 4th tower type breaks the old `-spacing/0/+spacing` switch, which had no slot for it
- `CGFloat(index) - CGFloat(allCases.count - 1) / 2) * spacing` reproduces the exact
  existing Red/Green/Blue offsets for 3 entries while automatically and symmetrically
  spacing any future Nth tower type — no further hand-editing required when the roster grows

Decision:
Give the Pink Laser Lance a unique chassis silhouette — a flat-topped hexagonal
"energy platform" ringed with three idle-pulsing power vents (tinted in its own
neon-red `projectileColor`) — replacing, for `.pink` only, the round toy-turret
base + specular highlight every other tower type shares. The vent glow starts
breathing once, at placement time, and runs forever regardless of combat state.

Reason:

- Direct user request: "let's implement unique design for this tower." Offered a
  choice between a few directions, the user explicitly picked "Angular chassis +
  idle energy glow" — a new silhouette *and* an always-on living-energy "tell"
- Investigation showed all four tower types previously rendered from one hardcoded
  base-plate skeleton in `PlaceholderTower.init` (shadow ellipse, circular plate,
  specular highlight, selection ring) — only the gun assembly inside `aimNode`
  differed per type. Branching `init` on `type` was the smallest change that lets
  Pink diverge structurally without touching the other three towers at all
- Kept the shadow ellipse, plate stroke color/width, and circular selection ring
  shared across all four types — soft blurred shadows and a glossy cool-white rim
  read as "toy plastic" regardless of base shape, and the selection ring is a UI
  affordance (not a chassis design element), so changing it would only break
  cross-tower consistency without adding to Pink's identity
- Chose a hexagon over other angular shapes because a flat-topped silhouette
  (`polygonPath(sides: 6, radius: 17, rotation: 0)`) reads as a "landing pad" /
  tech platform from the top-down camera angle this game uses — instantly distinct
  from a circle without looking out of place next to the rest of the roster
- Tinted the vent glows with `type.projectileColor` (the same neon-red that colors
  the beam and its plasma-burn mark) rather than introducing a new accent color —
  ties the chassis's idle "tell" into the same living-energy identity established
  by the beam pulse and burn flicker, instead of adding an unrelated visual motif
- Made the idle pulse start once, in `init` (immediately, not lazily on first fire
  like `startBeamPulse`) — the Laser Lance's "always charged and ready" personality
  should be visible the moment it's placed, before it ever locks a target, setting
  it apart as a fundamentally different *kind* of machine even at rest
- Reused the established `customAction` + sine-wave idle-animation pattern (see
  `startBeamPulse`/`startBeamBurnFlicker`) and gave each of the three vents a
  different phase offset spread evenly across the loop — sine is 2π-periodic
  regardless of additive offset, so every vent still loops seamlessly while never
  breathing in lockstep with the others, reading as a cycling energy core
- Added `polygonPath(sides:radius:rotation:)` as a `private static` helper next to
  `radialArcPath`, mirroring its angle-math approach to building shape paths via
  trigonometry — keeps the file's established style for custom `CGPath` geometry

Decision:
Adopt a small set of external tower-defense design principles as standing guidance
for upcoming roster work, and record them directly in the relevant `GAME_DESIGN.md`
sections plus new `TODO.md` entries (Phase 2 — Vertical Slice):
- Keep the tower roster tight; every type must own a clear "best at X" niche
- Design enemy counters "soft" — no lock-and-key enemies, no flying/path-ignoring types
- Add "total time control" (act while paused, speed-up toggle) and "total information"
  (tap-to-inspect stat readouts, wave previews) as concrete Phase 2 features

Reason:

- User asked me to read a r/gamedesign thread on TD design principles and fold
  anything useful into our plans. Reddit itself is not directly fetchable from this
  environment, so I cross-referenced the thread's likely subject — Lars Doucet's
  widely-cited "Optimizing Tower Defense for FOCUS and THINKING" (Defender's Quest
  postmortem) — plus a general survey of TD design-pillar writeups, and picked the
  handful of principles that map cleanly onto where this project is headed next
- "No lock-and-key enemies" / "no air units" land squarely on the still-unbuilt
  Scout/Soldier/Tank roster named in `GAME_DESIGN.md`'s Enemies section — better to
  bake the guidance in now, before any enemy-specific stats or resistances exist,
  than to retrofit balance later
- "Pointless variety" validates a pattern this project already follows by accident:
  the existing four towers are direct/homing/predictive/beam — four genuinely
  different damage mechanics, not reskinned DPS variants — so the guidance is framed
  as "keep doing this" for the Rifle/Cannon/Glue concepts already on the future list
- "Total time control" and "total information" are concrete, well-precedented mobile-TD
  UX features (pause-and-build, speed-up, tap-to-inspect) that fit naturally alongside
  the upgrade/haptics/menu work already queued in Phase 2 — added as their own TODO
  items rather than folded into "Improve animations"/"Polish" since they're systems
  work, not a visual pass
- Declined to adopt principles that conflict with decisions already made for this
  project: e.g. "No 3D" / "No scrolling" / fixed-vs-mazing are non-issues here (2D
  SpriteKit, fixed camera, fixed build spots around a hardcoded path were chosen long
  ago for exactly the reasons the source articles give), so they weren't re-litigated

## 2026-06-08 (Laser Sound)

Decision:
Give the Pink Laser Lance a one-shot "ignition" sound — fired exactly once, at the
instant its beam locks onto a target ("the laser starts heating") — built from a real
recorded sample the user supplied, rather than a synthesized continuous loop.

Reason:

- The first design explored here was a *continuous* "energy hum" re-triggered every
  loop-length while the beam stayed locked on — a from-scratch synthesized,
  integer-Hz-periodic clip, fully implemented and numerically verified as seamless. The
  user then supplied a real laser-gun recording with a fundamentally simpler brief —
  "use the first second of this clip; it should play every time the laser starts
  heating" — and, when asked how the two should combine, explicitly chose to replace the
  hum outright rather than layer them. A literal reading of "starts heating" is a
  discrete *ignition* transient, not a sustained drone, so the one-shot brief is also the
  textually correct interpretation — the hum mechanism was removed wholesale (rather
  than kept alongside as dead code) once the simpler, user-directed design was clear
- The one-shot reading is also the architecturally simplest: it slots directly into the
  project's existing, 100%-fire-and-forget sound model
  (`SKAction.playSoundFileNamed(_:waitForCompletion: false)`, gated on `isSoundEnabled`)
  with **zero** new looping/scheduling machinery — a direct sibling of the regular
  shot-sound trigger already in `updateCombat`, just hung on a state transition instead
  of a cooldown. This is a strict simplification versus the removed hum design, which
  needed its own re-trigger schedule (`beamHumNextTriggerTimesByBuildSpotID`) to fake
  sustained playback on top of an API with no native looping
- The only genuinely new piece is detecting *when* to fire it — the precise "beam just
  switched on" transition. `TowerManager` now tracks a per-build-spot
  `beamActiveByBuildSpotID: [Int: Bool]` ("was the beam projecting last frame?"), and
  `triggerLaserIgnition` fires the clip exactly when that flag isn't already `true` while
  the beam is active *this* frame, then sets it `true` so the rest of the lock stays
  silent. The flag resets to `false` — not left stale — the instant the beam goes quiet:
  lock lost (`updateCombat`'s no-target branch), target killed (`updateBeamCombat`'s
  `killed` branch), tower sold (`sellSelectedTower`), or scene reset
  (`resetForNewScene`) — the same four sites the removed hum schedule used to clear, so
  the next lock-on always ignites fresh rather than staying mute on a stale flag
- Chose to honor the user's real recorded sample rather than synthesizing a replacement:
  a punchy, textured "power-up" transient is exactly the kind of sound where a real
  recording's natural harmonic complexity reads more convincingly than procedural
  synthesis, and the user explicitly supplied one for this purpose. That makes
  `tower_beam_pink_start.wav` the project's first sound built from a real sample —
  every other one (including the removed hum) is procedurally synthesized — without
  breaking the fire-and-forget playback model those synthesized sounds also rely on
- Trimmed and converted with `ffmpeg -t 1.0 -ar 22050 -ac 1 -acodec pcm_s16le` to take
  precisely the user-specified "first second" and match the project's established
  22050Hz mono 16-bit WAV format byte-for-byte (verified: exactly 22050 frames / 1.0000s)
- Named it `tower_beam_pink_start.wav`, extending the established
  `tower_<type>_<effect>` convention with a descriptor ("start") that names the *moment*
  it plays — ignition/start-up — distinguishing it from both the discrete
  `tower_shoot_*` per-shot family and the sustained-loop `_hum` concept it replaces
- `TowerType.laserStartSound: String?` replaces the removed `laserHumSoundFile: String?`
  / `laserHumLoopDuration: TimeInterval` pair: a one-shot needs only a filename — there's
  no loop length to track once nothing re-triggers, so the second property simply
  disappears rather than becoming dead weight
- Added the new filename to `GameScene.preloadSounds()` as a like-for-like swap (still 9
  entries) so the audio engine warms it up at scene-load time, avoiding a
  first-ignition stutter the same way the existing preload avoids a first-tap one

## 2026-06-08 (Tower Upgrades)

Decision: Every placed tower can now be upgraded twice after placement (3 total
"stages": base, +1, +2), via a second cyan "▲ cost" badge that appears above a
selected tower (mirroring the existing gold sell badge below it). Each tier adds
a flat +50% of the tower's *base* damage/DPS — additive, not compounding — and
nothing else about the tower changes: `range`, `attackCooldown`, projectile
behavior, and visual identity all stay exactly as placed. Cost ramps per tier off
the tower's own placement price (tier 1 ≈ 60% of cost, tier 2 = 100% of cost), and
selling now refunds half of total investment (placement + every upgrade bought),
not just half of placement cost.

Reason:

- **Scope confirmed up front, not improvised mid-build**: the two open questions
  ("what should an upgrade improve?" and "how many tiers?") were resolved before
  any code was written — damage/DPS only, 2 upgrades for 3 stages. Keeping the
  scaled dimension singular (no creeping into range/cooldown/multi-stat curves)
  keeps the curve trivially easy to communicate to the player at a glance ("this
  tower hits harder now") and trivially easy to balance later — one knob, not five
- **+50% per tier, additive not compounding**: chosen over a compounding curve
  (1.0× → 1.5× → 2.25×) specifically because additive steps are *equal-sized* —
  tier 2 feels exactly as impactful as tier 1, rather than the curve runaway-ing
  or flattening depending on which direction you compound. Equal steps are easier
  to playtest-and-tune later: nudging the constant moves both tiers proportionally
  with no risk of one tier becoming pointless relative to the other
- **Cost curve (60% then 100% of placement price)**: deliberately escalating, so
  fully committing to one tower (130 coins all-in for Red/Green/Blue — 50 + 30 +
  50 — and 195 for Pink — 75 + 45 + 75) reads as a real strategic choice — "do I
  max this one tower, or spread coins across the board?" — rather than a trivial
  top-up
  once kill income starts piling up. Anchoring both tiers to the tower's own
  `cost` (rather than flat constants) keeps the curve self-consistent across the
  whole roster without per-type tuning, in keeping with AGENTS.md's
  simplest-workable-curve-first philosophy
- **The ratchet fix (a real bug caught during design, not at runtime)**:
  independently rounding `base × multiplier` per tier breaks down for
  low-base-damage towers — Red's base damage of 1 makes both `1 × 1.5 = 1.5` and
  `1 × 2.0 = 2.0` round to 2, so naively its *second* upgrade would cost full
  price and change literally nothing (the worst possible player experience: pay
  coins, get nothing, with no error or warning). Fixed by walking the curve
  tier-by-tier and enforcing `value = max(previousValue + 1, scaled)` — every
  tier is guaranteed to strictly improve on the last, for every tower in the
  roster, while towers whose curve already lands cleanly (Green: 2→3→4, Blue:
  4→6→8) are completely untouched by the ratchet (it never has to kick in).
  Recording this here specifically because it's the kind of subtle
  integer-rounding correctness issue a future contributor extending the curve
  (e.g. adding a 5th tower with base damage 1 or 2) would otherwise silently
  reintroduce
- **`upgradeLevel` lives on `PlaceholderTower`, not in a `TowerManager`
  dictionary**: `TowerManager`'s existing per-buildspot `[Int: X]` dictionaries
  (cooldowns, target locks, beam-active state) are reserved for
  combat-*scheduling* bookkeeping — transient state about "what's happening this
  frame," not "what this tower fundamentally is." `upgradeLevel` is squarely the
  latter: it's part of the tower's identity going forward, exactly like its
  immutable `let type`. Placing it as `private(set) var upgradeLevel = 0`,
  mutated only through a single `upgrade()` entry point, keeps that identity
  consistent and trivially greppable, and avoids yet another buildspot-keyed
  dictionary that has to be kept in sync on placement/sell/reset
- **`TowerType.damageMultiplier`/`upgradeCost`/`sellRefund`/`totalInvestedCost`
  as level-parameterized functions, not stored properties**: `TowerType` itself
  carries no instance state (it's a `CaseIterable` enum of static identities), so
  every upgrade-aware figure has to be a function of an explicit level. This
  converts `sellRefund` from a flat `cost / 2` constant into
  `sellRefund(atUpgradeLevel:)` built atop a new `totalInvestedCost(atUpgradeLevel:)`
  — a clean signature change with zero architectural relocation, and it composes
  naturally with `PlaceholderTower.currentDamage`/`currentDPS`, which apply the
  curve per-instance using the tower's own `upgradeLevel` (mirroring exactly how
  `TowerType.dps` already derives style-aware *base* figures from `damage` /
  `attackCooldown` / `laserDamagePerSecond`)
- **Dual-badge differentiation by position + color + icon, not by relabeling**:
  rather than overload the existing sell badge or introduce a wholly new
  interaction pattern, the upgrade badge reuses the *exact* established
  tap-to-act pill shape and `nodes(at:)` name-matching convention
  (`"UpgradeBadge"`, paralleling `"SellBadge"`), differentiated only by three
  simultaneous, mutually-reinforcing signals: opposite vertical position (above
  vs. below the tower), opposite-intent accent color (cyan "spend to improve" vs.
  gold "cash out"), and a distinct icon (up-chevron vs. coin). Three signals
  rather than one means the two pills read unambiguously even at a glance, with
  no risk of mis-taps between "improve" and "liquidate" — about as costly a
  mix-up as this UI could produce
- **Tier-pip visual feedback, tinted per-type**: a small glowing pip appears
  under the tower's base plate per upgrade purchased — permanent, at-a-glance
  proof of investment that persists even when the tower isn't selected (unlike
  the badges, which only show on selection). Built from the same
  "glow-behind-bright-core" visual language as the energy-vent glows and muzzle
  flashes, and tinted in the tower's own `turretColor` so it reads as part of
  *that* tower's identity rather than a generic overlay
- **Reused `tower_place.wav` for the upgrade sound**: rather than commission a
  new asset for a single tap action, reasoned that both moments — placing a
  tower and upgrading one — represent the same player feeling ("coins committed,
  tower changed for the better"), and mirrored how Pink already reuses Blue's
  `shootSound` for an unused slot. Keeps with AGENTS.md's avoid-unnecessary-work
  simplicity principle; a dedicated "upgrade chime" can be revisited if
  playtesting shows the reuse reads as flat or confusing

## 2026-06-08 (Green "Missile Pod" Visual Redesign)

Decision:
Give the Green tower its own chassis and gun silhouette (mirroring how Pink
already stands apart from the shared round-plate look), and give its projectile
a distinct "guided missile" visual treatment — tapered rocket body, nose cone,
tail exhaust glow, and a drifting smoke trail — replacing the small re-tinted
glow-ball every type otherwise fires. Driven directly by user feedback: the
round chassis read as "empty in the center" with only "thin guns in front," and
the homing warhead looked like "a small green circle," not a missile.

Reason / key choices:

- **Full chassis redesign over "gun assembly only"**: presented the user with
  two scopes — touch up just the turret/barrel geometry, or replace the whole
  base-plate-plus-gun silhouette the way Pink's hexagonal "energy platform"
  already does. The user picked the full redesign ("Full chassis redesign"),
  so the round base plate is now also replaced for Green, not just its gun —
  consistent with the user's stated complaint that the *tower's center*, not
  just its barrels, felt empty
- **Rectangular "armored launch deck" instead of a hexagon**: Pink's angular
  hexagonal platform already owns the "geometric/energy" silhouette language;
  giving Green a rectangular vehicle-hull plate instead (rounded rect +
  specular highlight + four corner rivets) reads as "rocket truck" and keeps
  the two non-round chassis types visually distinct from each other, not just
  from the shared round plate. Sized at 28×20 (cornerRadius 5) — its
  corner-to-center reach (~17pt) deliberately matches the existing round
  plate's footprint radius, so it sits inside the selection ring (radius 22)
  and reload-indicator ring (radius 20) at the same visual scale as every other
  tower, rather than looking under- or over-sized relative to the roster
- **One solid launcher hull instead of a floating pod + separate tubes**: the
  old assembly (small circular turret + a separate rectangular "pod" floating
  above it + two thin tube rectangles perched on top) was exactly what read as
  "thin guns stuck onto an empty circle." Replaced with a single rectangular
  "launcher hull" mass (24×18) that fills the tower's center, plus a small
  rectangular "swivel mount" plate (replacing the bare circular turret pivot)
  so even the rotation pivot itself reads as hardware — and twin launch holes
  recessed directly into the hull's face (dark sockets with a faint rim) rather
  than tubes sitting on top of it, so the armament reads as *built into* the
  hull, not bolted on as an afterthought
- **`ProjectileVisualStyle` enum + `TowerType.projectileVisualStyle`, mirroring
  the `projectileBehavior`/`projectileColor`/`projectileRadius` pattern**:
  rather than special-case Green inside `PlaceholderProjectile`, gave every
  tower type a declared visual-style identity (`.orb` for the shared
  glow-behind-core ball every type defaults to, `.rocket` only for Green) —
  the same "static per-type stat drives shared entity behavior" shape the
  codebase already uses everywhere else, so a future 5th tower can declare its
  own projectile look with a one-line addition instead of a special case
- **Both visual variants built once in `PlaceholderProjectile.init`, toggled
  per-use in `configure`**: `PlaceholderProjectile` is pooled — any instance
  can be reused across tower types/styles between fires — so rebuilding node
  trees on every shot would mean constant churn, while building both the orb
  parts (glow + core) and the rocket parts (body, nose cone, exhaust glow,
  exhaust core) once and flipping `isHidden` per `configure(color:radius:style:)`
  call is cheap, avoids node churn entirely, and trivially handles an instance
  switching styles between reuses — `configure` now resets every bit of visual
  state (geometry, color, rotation, visibility) so no stale state survives a
  pooling handoff
- **Rocket heading derived "for free" from the existing homing step, reusing
  `aim(at:)`'s exact rotation formula**: `startHomingTravel`'s per-frame
  `dx`/`dy` (direction toward the target) already *is* the rocket's direction
  of travel each frame — no separate velocity tracking needed. Applying
  `atan2(dy, dx) - (.pi / 2)` to `node.zRotation` — the identical formula
  `PlaceholderTower.aim(at:)` already uses to rotate turrets toward targets
  (and `PlaceholderEnemy` uses to face its movement direction) — guarantees the
  rocket's nose visually points the same way every other rotating entity in the
  game points when heading somewhere, with zero new state and zero risk of a
  formula mismatch reading as "off" by comparison
- **Smoke puffs spawned as scene siblings, not projectile children**: a puff
  needs to stay fixed in world space while the rocket continues on, so each one
  is added via `node.parent?.addChild(_:)` — `parent` is the scene, set once and
  persisting across pooling reuse — rather than as a child of the moving
  projectile node (which would drag every prior puff along with it). Spawned
  on a fixed real-time cadence (`smokeAccumulator` against a `0.06s` interval,
  not a per-frame spawn) so the trail's density stays consistent regardless of
  frame rate, and each puff reuses the exact spawn → animate
  (scale + fade-out group) → `removeFromParent` sequence already established by
  `ProjectileManager.showImpactFlash` — one more application of an existing
  pattern rather than a new one

## 2026-06-08 (Enemy Variety — Scout/Soldier/Tank)

Decision: Built the documented Scout/Soldier/Tank roster exactly as named in
`GAME_DESIGN.md`'s Enemies section and `TODO.md`'s Phase 2 entry — no additional
types beyond that trio (the user's own Swarm/Armored brainstorm ideas from this
same conversation were explicitly deferred; see Reason). Added `EnemyType:
CaseIterable` (mirroring `TowerType`'s static-per-type-stats shape) with
`maxHitPoints`, `speedMultiplier`, `killReward`, and chassis livery/scale.
Soldier keeps the original baseline exactly (5 HP, 1.0× speed, 10-coin reward,
original maroon paint, 1.0× scale); Scout trades HP for speed (3 HP, 1.35×
speed, 6-coin reward, smaller bright-orange chassis); Tank inverts that trade
(12 HP, 0.65× speed, 18-coin reward, larger dull-armored chassis). `WaveManager`
now picks a random `EnemyType` per spawn from a per-wave roster: wave 1 mixes
Soldier/Scout only, wave 2+ folds in Tank.

Reason:

- **Scoped to exactly the documented trio, not the user's own broader
  brainstorm**: when asked "which enemies would you add," I floated Scout/
  Soldier/Tank (the documented roster) plus two original ideas of my own —
  "Swarm/Pack" (many low-HP clustered enemies, would create real pressure
  toward adding splash damage, which doesn't exist) and "Armored/Shielded"
  (flat per-hit damage reduction, would need a brand-new mitigation mechanic).
  The user said "let's implement" in direct reply to that whole message, so
  scope was genuinely ambiguous. I chose the documented trio: it's *exactly*
  what `TODO.md` Phase 2 already calls for, requires zero new combat
  mechanics (fits cleanly into the existing single-target discrete/continuous
  damage model), and keeps this a small vertical slice per `AGENTS.md`. Swarm/
  Armored remain good *future* ideas but belong in their own slices once
  splash damage / damage mitigation exist as systems worth building around —
  bundling them in now would have ballooned this into a multi-mechanic feature
- **Solved the speed-architecture blocker with a multiplier, not a
  restructure**: `GamePath.movementSpeed` is a fixed, path-level constant
  consumed directly inside `PlaceholderEnemy.startMoving`'s travel-duration
  math — there was no per-enemy speed lever at all. Rather than restructure
  how `GamePath` reports/stores speed (a bigger, riskier change touching
  shared path math), `EnemyType.speedMultiplier` is layered on top:
  `let speed = path.movementSpeed * type.speedMultiplier`. Soldier's 1.0×
  reproduces the original fixed-speed behavior exactly — zero risk of
  regressing the existing baseline — while Scout (1.35×) and Tank (0.65×)
  get meaningfully different paces with a one-line change at the point of
  consumption. `GamePath` itself stays untouched, simplest-solution-wins
- **HP/speed/reward chosen to keep every counter "soft," per the documented
  guidance**: Soldier (5 HP) sits at ≈1.1–1.7s time-to-kill against the
  existing tower roster's sustained DPS (≈2.9–4.5); Scout (3 HP) dies in
  under a second to anything, rewarding towers that can land a hit before it
  crosses the screen; Tank (12 HP) takes ≈2.7–4.1s, rewarding sustained
  heavy-hitters (Blue/Pink) without making fast-but-light options
  (Red/Green) *unable* to finish the job — just less efficient. No enemy
  type is hard-countered or hard-favored by exactly one tower; every type
  stays killable, if inefficiently, by the whole roster — directly honoring
  the "no lock-and-key" guidance flagged back in the 2026-06-06 roster
  entry (lines ~901–903) as the reason this trio's stats needed care
- **Visual differentiation via recolor + rescale of the shared chassis, not
  new geometry per type**: `GAME_DESIGN.md` calls for "meaningfully different
  *stats* (not palette swaps)" — a contrast about *stats*, not a ban on
  recoloring. Recoloring a shared silhouette is exactly how two of the four
  towers (Red/Blue) already differentiate, and matches `AGENTS.md`'s
  "use placeholder assets until gameplay is proven fun." So each `EnemyType`
  recolors `PlaceholderEnemy`'s existing hull/turret (tracks, barrel, and
  highlight stay a shared neutral "machine" palette — only the "paint job"
  changes) and applies a uniform `chassisScale` to `bodyNode` (Scout 0.82×,
  Soldier 1.0×, Tank 1.28×) — small, cheap, and reinforces each type's stat
  identity at a glance without inventing three new chassis silhouettes
- **`configure(type:)` mirrors `PlaceholderProjectile.configure`'s "fully
  reset on reuse" contract**: `PlaceholderEnemy` is pooled — any instance can
  be reconfigured as a different `EnemyType` between lives — so `configure`
  reapplies every stat (`maxHitPoints`, `killReward`) and visual (hull/turret
  colors, chassis scale) explicitly, with nothing left to carry over
  implicitly from a prior life. Called from `EnemyManager.spawnPlaceholderEnemy`
  before `startMoving` (which immediately calls `reset()`, deriving
  `hitPoints`/`fractionalHealth` from the just-set `maxHitPoints`) — same
  "configure, then reset/start" sequencing the projectile pool already uses
- **Per-wave type mix via uniform-random selection from a per-wave roster,
  mirroring `waveDefinition`'s existing formula-based shape**: rather than
  hand-scripting individual spawns, `WaveDefinition` gained an
  `availableEnemyTypes: [EnemyType]` alongside `enemyCount`/`spawnInterval`,
  and each spawn calls `randomEnemyType(from:)` to pick uniformly from that
  wave's set. Wave 1 = `[.soldier, .scout]` (eases the player in — no Tanks
  until they've had a chance to place towers and bank coins), wave 2+ adds
  `.tank`. Simplest possible "real variety, ramping with difficulty" shape;
  exact per-wave proportions can be tuned later from actual playtesting
  without touching the selection mechanism itself
- **Corrected a stale fact while in the area**: `GAME_DESIGN.md` claimed
  enemies have "basic 1 HP combat health," but the actual (and now Soldier's
  baseline) value has been 5 HP since the fractional-health work landed.
  Fixed it to describe the real roster and stats while updating this section
  anyway, rather than leave a known-wrong fact for the next person to trip on

## 2026-06-08 (Enemy HP Rebalance — +50% across the roster)

**Decision**: Bumped `EnemyType.maxHitPoints` +50% for all three types — Scout
3 → 5, Soldier 5 → 8, Tank 12 → 18 (each the original value × 1.5, rounded to
the nearest whole point: 4.5 → 5, 7.5 → 8, 18 stays 18). Nothing else about
the roster changed — speed multipliers, kill rewards, and chassis livery/scale
are untouched.

**Reason**:

- **A direct, requested balance tweak, not a redesign**: the user asked
  specifically to "increase each enemy HP by 50%." The cleanest way to honor
  that exactly is a uniform per-type multiplier on the existing baseline
  values rather than picking new round numbers from scratch — it's
  predictable, reversible, and easy to re-tune again from the same anchor
- **Rounding choice**: `× 1.5` lands on a whole number only for Tank (12 → 18);
  Scout (4.5) and Soldier (7.5) both sit on a round-half boundary. Rounded
  both up (5 and 8) rather than down — "increase HP" should unambiguously mean
  more HP for every type, and rounding either of those two down would leave
  one type effectively un-bumped (Scout 4.5 → 4 is only +33%, not +50%)
- **Relative ratios — and therefore the soft-counter balance — are preserved**:
  the three values were already chosen as a deliberate ratio (low/baseline/high
  HP trading against speed and reward), and multiplying each by the same 1.5×
  factor keeps Scout:Soldier:Tank proportionally where they were (roughly
  5:8:18 ≈ the old 3:5:12, i.e. Scout ≈ 0.6× Soldier ≈ 0.3× Tank in both sets).
  The "every type stays killable, if inefficiently, by every tower" guarantee
  from the original balance pass (checked against the roster's ≈2.9–4.5
  sustained DPS) still holds — every matchup just now takes proportionally
  longer, which is exactly what a flat HP-up pass should do
- **New approximate time-to-kill ranges** (vs. the same ≈2.9–4.5 DPS spread):
  Scout (5 HP) ≈ 1.1–1.7s (was ≈0.7–1s), Soldier (8 HP) ≈ 1.8–2.8s (was
  ≈1.1–1.7s), Tank (18 HP) ≈ 4–6.2s (was ≈2.7–4.1s). All three remain
  comfortably inside "fights that matter but don't drag," and no matchup
  crosses into "unkillable in practice" territory for any tower
- **Scope stayed minimal on purpose**: only `EnemyType.maxHitPoints` changed.
  Speed, reward, and visuals were left exactly as they were — the user asked
  for an HP change, and touching anything else would be scope creep on a
  one-line balance request

## 2026-06-08 (Enemy Death Effect)

**Decision**: On a damage kill, an enemy now spawns a self-contained "blown-apart
toy" burst — a hull-tinted glow, a white-hot core, an expanding shockwave ring,
and six livery-colored debris shards flying outward — instead of its node
silently disappearing. Implemented as `PlaceholderEnemy.spawnDeathEffect(in:)`,
fired from a new `EnemyManager.killAndRecycle(_:)` chokepoint that all three
damage paths now funnel through.

**Reason**:

- **Highest-value game-feel gap, picked deliberately**: investigating where to
  push polish, enemy death stood out — it's the single most-repeated event in a
  run (dozens of kills per game) and had zero visual payoff beyond the coin-fly
  and death sound; the node was yanked from the scene the same frame it died.
  The user, asked to choose a polish direction and then a specific slice, picked
  "Polish & game feel" → "Enemy death effect" out of the candidate list (death /
  screen shake / hit reaction / spawn-in)
- **Added to the scene, not the enemy node**: the enemy is recycled (and removed
  from its parent) the same frame it dies, so an effect parented to `node` would
  be torn down before it could play. Spawning the burst as scene-level transient
  nodes that each `removeFromParent()` themselves when their animation ends is
  the same pattern every other one-shot effect in the project already uses
  (`ProjectileManager.showImpactFlash`, `UIManager.flyCoinReward`) — no pooling,
  no cleanup bookkeeping, no per-frame cost
- **Single chokepoint, not three copies**: the three damage entry points
  (`applyDamage`, `applyDamage(matchingLifeID:)`, `applyContinuousDamage`) each
  had an identical `killCount += 1; recycle(enemy)` kill branch. Folding that
  into one private `killAndRecycle(_:)` and adding the death-effect call there
  means projectile kills and beam kills both get the burst with no duplication,
  and there's exactly one place to evolve kill-time behavior later
- **Kept out of `recycle` itself, on purpose**: `recycle` is also the path an
  enemy takes when it *breaches the base* (reaches the path end). A breach is a
  loss, not a kill — celebrating it with an explosion would be the wrong signal —
  so the effect lives one level up, only on the damage-death path. This is the
  key correctness subtlety a future contributor might otherwise miss by "just
  putting it in recycle"
- **Sized by `type.chassisScale`**: reusing the existing per-type scale for the
  burst (glow radius, shard spread/size) makes a Tank die bigger and messier
  than a Scout for free, reinforcing the roster's size identity at the moment it
  matters most, with no new per-type constants
- **No new assets**: built entirely from short-lived `SKShapeNode`s tinted from
  the enemy's own `EnemyType` colors (hull / turret) plus the shared track color,
  consistent with the placeholder-art philosophy — final art can replace it in
  the Phase 3 reskin without changing the trigger wiring

## 2026-06-08 (Blue "Mortar" Redesign)

**Decision**: Reworked the Blue tower from a predictive direct-fire "Heavy Cannon" into a
**Mortar** — a lobbed-shell, splash-damage area tower. It picks the lead enemy, lobs an
arcing shell onto that enemy's predicted point on the road, and detonates in a fiery orange
explosion that damages every enemy within a 55pt blast radius. New chunky high-angle tube
visual (baseplate + bipod + flared tube + 3D angled mouth) and a dark finned shell that arcs
with a ground shadow, replacing the cyan orb. Reload kept slow (~1.4s), 4 damage, lead-enemy
targeting, fiery-orange blast — all chosen by the user.

**Reason**:

- **Fixes the actual complaint, and fills a real gap**: the user disliked that Blue's
  predictive aim fired *ahead* of the enemy onto open road ("hitting into a random place").
  A mortar makes landing on the road the entire point, and splash means an imperfect landing
  still hits. It also gives the roster its missing **area/crowd-control** niche — Red/Green/Pink
  are all single-target (direct / homing / beam), so this is genuine mechanical variety, not a
  DPS reskin (squarely in line with GAME_DESIGN's "every tower owns a clear best-at-X" rule).
- **Slow & heavy over faster reload (user reversal, honored)**: the opening message said
  "increase reload speed," but when offered the trade the user picked "keep it slow & heavy
  (~1.4s)" so the big splash is the payoff. Single-target DPS is therefore unchanged (≈2.9) —
  the upgrade is purely the area damage, which keeps it balanced against the soft-counter
  tuning while making it shine specifically against bunched waves.
- **New `.mortar` behavior + `.shell` style, not retrofitting `.direct`**: a lobbed AoE shell
  has a fundamentally different flight (parabolic arc), impact (area, on the ground, always
  detonates — even on empty road), and targeting (lead enemy, predicted landing) than a
  straight single-target shot. A dedicated behavior + a dedicated `updateMortarCombat` branch
  keeps it cleanly separate from the untouched direct/homing/beam paths, mirroring how the
  beam tower already got its own branch.
- **Lead-enemy targeting (not nearest)**: a mortar should bombard the *front* of the advance
  (the enemies about to breach), so `EnemyManager.leadEnemy` picks the one closest to the path
  end within range. The path end comes from a new `GamePath.endPoint`, threaded into
  `updateCombat` as `pathEndPoint` rather than coupling `TowerManager` to `PathManager`.
- **Faked arc, real impact point**: `startLobbedTravel` moves the projectile's true
  `node.position` along the straight ground line to the landing point — so the explosion,
  splash, and shadow are all exactly where intended — while only the *visual* body floats up
  on a `sin(t·π)` lift and the shadow grows as it descends. No real 3D, no physics; the same
  cheap top-down trick the rest of the game uses, and it keeps damage math trivial.
- **Explosion reuses the established transient-FX language**: `showExplosion` is the same
  spawn → scale/fade → self-remove `SKShapeNode` pattern as the impact flash and enemy death
  burst, just bigger and tuned orange to read as fire. The artillery boom sound was moved from
  launch to the explosion moment so the satisfying audio lands on the hit, not the lob.
- **Beefed-up tube visual (user-requested follow-up)**: the first pass was a minimal dark
  slit that barely read as a mortar. Rebuilt with a baseplate, bipod, an upward-flaring tube
  with cylinder sheen + reinforcement bands, and a 3D angled elliptical mouth (steel rim, dark
  bore, specular glint) — verified in the simulator to read clearly as a high-angle mortar from
  the top-down camera.
- **Corrected stale GAME_DESIGN figures along the way**: the doc still listed Blue as
  "0.90s / 2 dmg"; the real values were 1.40s / 4 dmg. Updated to the accurate (new) numbers
  rather than leave a known-wrong spec.
- **Ballistic shell rotation (user follow-up)**: the first pass left the shell visually upright
  for the whole arc, which read as unnatural. The shell now orients to its *apparent screen-space
  velocity* — the constant ground travel `(dx, dy)` plus the lift's rate of change
  `cos(t·π)·π·peakHeight` (screen-up). The flight duration is a common factor in both
  components so it cancels inside `atan2`, leaving a clean per-frame
  `zRotation = atan2(dy + cos(t·π)·π·peakHeight, dx) − π/2` on the lift node (the shadow, parented
  to the true ground position, stays flat). Because the lift term dominates the bounded ground
  delta, the result is a strong, smooth arc: nose-up on the climb, level at the apex, nose-down
  plunging onto the impact — the standard "orient to trajectory tangent" approach.

## 2026-06-08 (Decorative Tabletop Scenery)

**Decision**: Dressed the bare green battlefield with static decorative toy scenery — a mix of
round and pine trees, bushes, rocks, and grass tufts in the empty pockets — plus two objective
markers: an enemy "camp" (tent + flag) at the spawn and a player "base" bunker (flag) at the
path end. Implemented as a new `SceneryFactory` enum, added once in `GameScene`. Scope chosen by
the user (mix of tree shapes, sparse density, *and* both markers + rocks/tufts).

**Reason**:

- **The map read as empty**: the tabletop was a single green slab with a road — fine
  functionally, flat visually. Minimalist toy scenery is squarely in the documented art
  direction ("plastic toy appearance / clean silhouettes / tabletop battlefield presentation")
  and is the cheapest, lowest-risk way to add life. The user proposed trees; offered options,
  they picked a mix of shapes, sparse density, and adding the spawn/base markers + ground detail.
- **Markers earn their place on readability, not just looks**: the board had no visual for
  *what* you defend or *where* enemies come from. A camp at the start and a base at the end make
  the route legible at a glance and reinforce the toy-army theme — a genuine UX win folded into
  the cosmetic pass (the spawn/base use the same `GamePath.start/endPoint` the Mortar already
  needed).
- **`SceneryFactory` enum, mirroring `TowerGunFactory`**: scenery is pure node-construction with
  no state, so a namespaced enum of static builders fits the established pattern exactly and
  keeps `GameScene` thin (one `makeScenery` call). New `.swift` file registered in the classic
  pbxproj (no synchronized groups in this project) the same way `EnemyType`/`TowerGunFactory`
  are.
- **Fixed positions, not procedural placement**: a single hand-tuned map reads as *designed* and
  guarantees nothing overlaps the road or the five build spots / their menus. A
  randomize-and-avoid algorithm would add complexity and risk ugly placements for zero benefit
  on one fixed map — hardcoded points were verified clear in the simulator.
- **Added in `buildPlaceholderScene`, at `zPosition` 6**: that method runs once (guarded), like
  the table, so scenery persists across restarts without re-adding — and z6 sits above the road
  (5) but below every gameplay unit (enemies 20 / towers / projectiles), so combat never gets
  occluded (tanks visibly emerge over the spawn camp). No per-frame cost, no pooling — it's
  inert decoration.
- **Placeholder, reskin-ready**: built from procedural `SKShapeNode`s tinted to match the
  roster's toy-plastic look (soft shadow + fill + outline + specular). Per `ART_ASSET_BRIEF.md`,
  the Phase 3 art pass can replace these with sprites without touching any gameplay wiring.

## 2026-06-11 (Tunnel Visuals + Visual Polish Pass)

**Decision**: The underground tunnel segment is indicated **only at its two mouths** — the road
is simply not drawn along the buried stretch (grass continues over it), and a grassy hillside
portal (mound + stone facade + dark arched opening) marks each end, oriented so its opening
lines up with the above-ground road it connects to. No colored band, outline, or marker runs
along the tunnel's length. Enemies *dive* into the entrance (shrink + fade + dust) and *pop out*
of the exit (scale-up with overshoot + dust) instead of blinking out/in via `isHidden`.

**Reason**:

- **User direction, with a real-world rationale**: "like in real life, it should be indicated
  at the enter/exit of it." A tunnel seen from above is invisible except at its portals; the
  earlier bright-orange trench band read as a surface feature, not an underground one. The
  gameplay tell (enemies are safe underground) is carried by the portals, the visible dive/
  emerge moments, and the road gap itself.
- **Road gap via subpaths**: `makeAbovegroundRoadPath` restarts the road stroke (`move(to:)`)
  after each tunnel segment — one CGPath, no extra nodes, works for any number of tunnels.
- **Animated transitions prevent "bug" reads**: an instantly vanishing enemy looks like a
  defect; a 0.16s sink into a dark mouth (with dust kicked up at the portal) looks like a
  mechanic. Gameplay state still flips instantly at the segment boundary — `isTargetable`
  is unchanged — only the presentation is eased.

**Decision**: Added a broad visual-feel pass on top of the tunnel work: enemy hull "engine
rumble" idle bob, dust trails behind driving enemies, a spawn pop (scale-up + fade-in), a white
hit-flash on every discrete hit, screen shake on mortar detonations and base breaches (via a
center-anchored `SKCameraNode` + `shakeScreen` SKScene extension), a wooden tabletop frame with
grain lines under the grass mat, a soft vignette over the grass, a drifting ambient cloud
shadow, gentle sway loops on trees/bushes/grass tufts, and fluttering marker flags.

**Reason**:

- **Motion reads as life**: the board was static outside of combat; tiny forever-looping
  oscillations (sine-based, seamless, deterministic per-position phase offsets) make the
  tabletop feel alive for near-zero per-frame cost — no new nodes, no allocations during play.
- **Hits needed feedback**: kills had a death burst but ordinary hits showed nothing except a
  health-bar tick. The flash overlay is pre-built in `init` (pooling-safe) and restarted per
  hit; beam damage deliberately does not flash (it has the plasma burn, and per-frame flashing
  would strobe).
- **Camera at scene center is render-identical to no camera**, so adding `SKCameraNode` for
  shake required no coordinate/UI changes; `shakeScreen` always lands the camera exactly back
  at center and replaces any in-flight shake, so overlapping impacts can't displace the view.
- **Tabletop framing**: the wood border + vignette sell the documented "toys on a table"
  presentation that the flat green slab never did.

**Decision**: Realigned the UI test suite to the serpentine layout (8 build spots) and fixed
two stale assumptions: the build menu has had **4** options since Pink landed (offsets are
`(index − 1.5) × 52`, not `−52/0/+52` — the old taps landed between options and selected
nothing), and the projectile-pixel predicate still looked for the long-gone magenta placeholder
(now matches Green's lime). The fires-test now baselines lime pixels after placement, reinforces
with two more towers so wave 1 dies on the battlefield, polls for a clear field instead of a
fixed sleep (the serpentine takes ~19s to traverse), and scans only the battlefield region —
the HUD's red hearts match the deep-red "enemy pixel" predicate and sat in the old full-screen
scan.

**Reason**: the suite was failing for layout/staleness reasons unrelated to what it verifies;
each fix preserves the original intent of its test while making it deterministic on the new map.

## 2026-06-12 (Sluggish Mortar + Per-Type Turret Traverse)

**Decision**: Turrets no longer snap-aim instantly. `PlaceholderTower.aim(at:deltaTime:)` rotates
toward the target along the shortest arc at a per-type maximum `TowerType.traverseSpeed`
(rad/s): Red 10, Pink 12, Green 6, **Blue 1.8** (≈2s to come about 180°). The traverse is
purely cosmetic — firing schedules never wait for alignment. The Mortar additionally
**commits to its target** (reusing the existing `TargetLock` machinery instead of re-picking
the lead enemy every frame), and its tempo got heavier: 1.40s → **1.85s** cooldown with damage
4 → **5** per shell (DPS ≈2.86 → ≈2.70, near-parity).

**Reason**:

- **User feedback**: "blue tower is very fast targeting and circle speed is high as well —
  add sluggishness." Discussed options; the user chose: slow both the tube traverse *and* the
  reload tempo, keep the lag cosmetic (no fire-alignment gate, zero balance surprise), have
  the Mortar lock its target, and roll traverse out to the whole roster scaled by gun weight
  (mirroring how `recoilDistance` already scales Red < Green < Blue).
- **Lead-targeting was the real spin source**: "lead enemy in range" changes constantly as
  enemies stream past, so the tube whipped to a new bearing every few frames. Committing to
  one target until it dies/breaches/tunnels/leaves range removes the whipping at the source;
  the rate-limited traverse smooths what remains.
- **Damage 4 → 5 alongside 1.40s → 1.85s** keeps the Mortar's single-target DPS within ~6% of
  its old value while making each volley feel heavier — the goal was character, not a nerf.
  The reload ring sweeps the new 1.85s automatically (it derives from `attackCooldown`), which
  also answers the "circle speed is high" half of the feedback honestly.
- **Pink stays near-instant (12 rad/s)** because its beam is drawn along the barrel axis — a
  slow sweep would visibly detach the beam from the burn mark on its target. At 12 rad/s the
  catch-up reads as the beam sweeping onto the target for a fraction of a second.
- **Aim UI test** moved to a left-column spot and waits 1.3s (covering the slow traverse) —
  the locked target there stays to the tower's right for the test's whole window. The
  projectile check also switched from a racy single-baseline comparison to sampling lime-pixel
  variance over ~4s, since missiles/flashes make the count fluctuate while a silent field
  holds it constant.

## 2026-06-12 (Missile Pod Rework — Long-Range Support)

**Decision**: Reworked Green per the user's direct numbers: acquisition range +75% (175 → 306,
making `TowerType.range` per-type for the first time — everyone else stays at 175), rocket
speed −30% (240 → 168), damage +30% — delivered as a heavier 3-damage warhead on a 0.75s
cooldown (old: 2 dmg / 0.65s), landing DPS at exactly 4.0 (= 3.08 × 1.3), since per-shot
damage is integer and 2.6 isn't representable. The rocket's smoke trail was also made clearly
visible (brighter `smokeColor` 0.82/0.85 vs 0.60/0.50, bigger puffs at 3.0pt, denser 0.045s
cadence, longer 0.7s fade) — it was nearly transparent before.

**Reason**:

- **User feedback with explicit numbers** ("increase firing range +75%, missile trace more
  visible — now it's transparent mostly, decrease missile speed by 30%, damage +30%").
- **The combination defines a real niche**: huge reach + slow guaranteed-hit rockets + heavier
  warheads = long-range artillery support, clearly distinct from Red's short-range DPS hose,
  Blue's area mortar, and Pink's premium beam. The slow rocket is a fair trade for homing
  (it can never miss) and visually showcases the new trail across the long flight.
- **The shared range indicator now re-sizes per selection** (`moveRangeIndicator` takes a
  radius and rewrites the circle path) instead of being built once at a fixed 175 — required
  since ranges differ per type; `TowerManager`'s redundant `placeholderAttackRange` constant
  was removed in favor of `tower.type.range` everywhere.
- Corrected stale `GAME_DESIGN.md` Green stats while in there (it claimed 1 dmg / 0.58s; the
  code had been 2 dmg / 0.65s since an earlier balance pass).

## 2026-06-12 (Haptics)

**Decision**: Added tactile feedback via a new `HapticsManager`, mirroring the existing sound
architecture end-to-end. Event → haptic mapping: tower place = medium impact, upgrade = rigid,
sell = light; mortar detonation = heavy; enemy kill = light (throttled); base breach = warning
notification; victory = success; defeat = error; HUD button taps = selection. Per-shot firing
gets **no** haptic. Persisted ON-by-default toggle in the pause menu (`hapticsEnabled`
UserDefaults key), beside the sound toggle.

**Reason**:

- **Documented next Phase 2 task**, and the immediate-goal note asked to pick *which* moments
  deserve feedback and *which* style fits each — this is that decision, recorded.
- **Mirror the sound model rather than invent a parallel one**: `isHapticsEnabled` is a
  `@Published` on `GameStateManager` (so the SwiftUI toggle binds to it) with a
  `setHapticsEnabled` + `onHapticsEnabledChange` callback, exactly like sound. `HapticsManager`
  holds the UIKit generators and a plain `isEnabled` bool that GameScene keeps in sync — the
  same shape as `TowerManager.isSoundEnabled`. Cheapest possible fit, no new patterns.
- **No per-shot firing haptic — deliberate**: the Autocannon fires every 0.28s; a tap per shot
  with multiple towers would buzz almost continuously and hammer the Taptic Engine. The Mortar's
  detonation (already the heaviest visual + the screen-shake moment) carries the "heavy weapon"
  tactile beat for the whole roster instead. This was the key judgment call the task asked for.
- **Throttled kill taps**: kills funnel through `EnemyManager.killAndRecycle` (the single
  damage-kill chokepoint — covers projectile, beam, and splash alike). A mortar splashing four
  enemies would otherwise fire four light taps in one frame. A shared 0.11s throttle in
  `HapticsManager` collapses bursts to one tap; the mortar's heavy boom is "forced" (always
  fires) and resets the throttle window, so the splash kills in the same instant fold into the
  boom rather than stacking taps on top of it.
- **Generators warmed with `prepare()`** on load and after each fire (Apple's recommended
  low-latency pattern). Haptics are device-only; on the simulator the generators simply no-op,
  so nothing here affects the UI test suite.
- **Wiring via weak refs set in `setupCallbacks`** (`EnemyManager.hapticsManager`,
  `TowerManager.hapticsManager`) rather than threading a `HapticsManager` parameter through
  every combat-method signature — matches how `onEnemyReachedEnd` and other per-scene hooks are
  already wired, and `setupCallbacks` re-runs on restart so the refs stay valid.

**Decision** (incidental): widened the `testPlacedTowerFiresProjectilesAndDestroysEnemies`
clear-field poll from 40 to 70 iterations.

**Reason**: it was intermittently failing under full-suite load (passed in isolation) — the
battlefield only fully clears in the brief gap between wave 1 dying and the larger wave 2
spawning, and slower screenshots under load meant fewer game-seconds elapsed inside the fixed
window, so it could miss that gap. Unrelated to haptics (which no-op in tests); just needed
more polling headroom.

## 2026-06-12 (Orphaned Missiles Land & Detonate)

**Decision**: When a homing Green missile's target dies or breaches mid-flight, the missile no
longer vanishes — it commits to the target's last-known position, flies the rest of the way,
and detonates on the road there. The detonation is purely cosmetic: a color-matched (lime)
flash + expanding shockwave ring, **no damage and no sound**.

**Reason**:

- **User-flagged immersion break**: "when the enemy is down but we have missiles released, it
  should not disappear — the missile should land on the road and explode." A guided munition
  blinking out of the air reads as a bug; committing to the ground and going off reads as
  physics. The fix is squarely in the project's "feel" tradition.
- **Cosmetic, not splash — deliberate** (the one real design fork): giving the road detonation
  area damage would hand Green incidental AoE and blur the Mortar's whole reason to exist (the
  roster's documented area/crowd-control specialist). Keeping it a no-damage "wasted warhead"
  preserves Green's single-target long-range-support identity and every tower's distinct niche.
  The blast is tinted in the missile's own lime and kept small/un-fiery so it never reads as an
  area attack. (If we later want orphaned missiles to feel less wasted, a *small* splash is a
  one-knob opt-in — noted, not taken.)
- **Implemented generically in `startHomingTravel`** (last-known-position + `isCommittingToGround`
  flag) rather than as Green-specific code, so any future homing projectile inherits it. The
  cosmetic blast routes through `completion(false)` + a local `spawnLandingExplosion` (sibling
  self-removing nodes, same pattern as the smoke trail) specifically to avoid the normal
  `onImpact` path — which would otherwise attempt damage on the dead target (a guaranteed no-op
  thanks to the lifeID check) and play `enemy_hit` on empty road.
- **No sound for now**: Green has no dedicated explosion sample, and playing its shoot sound or
  the enemy-hit sound on an empty-road blast would be wrong. Silent-but-visual is the clean
  choice; a dedicated "missile detonation" cue could be added later.

## 2026-06-12 (Red "Autocannon" Twin-Turret Redesign)

**Decision**: Replaced the Red gun's bare "pivot disc + two thin barrels" with a proper
twin-autocannon turret: a chunky rounded gun housing (bright turret livery, glossy highlight,
domed hatch) fixed to the rotation pivot, with the two barrels protruding from a front mantlet.
Only the barrels recoil — they slide back *into* the fixed housing on each shot. Purely visual;
no stats changed.

**Reason**:

- **User feedback**: the Red tower "looks like it has only two guns" — it lacked a turret body,
  unlike Green (solid launcher hull) and Blue (chunky tube + collar). The user asked to "attach
  a turret to these guns."
- **Discussed the two real forks and the user chose**: (1) turret silhouette = rounded box
  mantlet (over a tapered mantlet or a hexagon — the hexagon was rejected as it'd echo Pink's
  hex energy platform); (2) recoil = barrels cycle into a fixed housing (over the whole turret
  kicking). The barrels-into-housing read is the most characterful for a fast-firing autocannon
  and is what distinguishes Red's recoil from the rest of the roster.
- **Implementation rides the existing aim/recoil split for free**: the housing/mantlet/hatch/
  highlight go on `aimNode` (rotates, fixed), the barrels + muzzle bores on `barrelNode` (the
  node `PlaceholderTower` already kicks back along +y on each shot). Layering the housing above
  the barrels (`zPosition` 3–3.8 vs 2) makes the barrel rears disappear "into" the turret as
  they recoil — no new animation code, just geometry + z-order. `tipOffset` bumped to (0, 29)
  for the longer barrels so the muzzle flash/spawn point stays at the tips.
- Also reads better than the thin barrels in the small build-menu preview (same assembly,
  scaled 0.44×). Verified in-sim (idle + rotated) with a throwaway debug placement, then removed.

## 2026-06-12 (Main Menu)

**Decision**: Added the main menu as a new `.mainMenu` `GamePhase` + a SwiftUI `MainMenuView`
overlay (in `GameView.swift`, alongside the existing private `LoadingView`). The app now boots
into the menu with the fully built, *idle* battlefield dimly visible behind it; waves start —
and the phase moves to `.sceneLoaded` — only when the player taps PLAY. The menu carries the
loading screen's title identity, a pulsing PLAY button, a "10 WAVES · 3 LIVES · NO MERCY"
tagline, and the same sound/haptics toggles the pause menu offers. The victory/defeat overlays
gained a second "Menu" button (beside Restart) that returns to a freshly rebuilt idle menu
backdrop, closing the loop: menu → play → end → menu.

**Reason**:

- **Next unchecked Phase 2 item** ("Add main menu"), chosen by the user.
- **Reuses the established overlay architecture**: `GameView` already swaps SwiftUI overlays on
  `GamePhase` (loading/pause), so the menu is just one more phase + view — no new navigation
  machinery, no separate scene. `MainMenuView` lives in `GameView.swift` like `LoadingView`
  does, avoiding pbxproj surgery and following the file's own precedent.
- **Battlefield as backdrop**: `didMove` builds everything as before but stops short of
  starting waves (`startWaves` split out of `buildGameplaySlice`), then `markMainMenu()`. The
  existing phase gates already keep the idle scene inert (combat update and touch handling are
  `.sceneLoaded`-gated; an explicit `.mainMenu` early-return was added to `touchesEnded` for
  safety). PLAY fires `GameStateManager.startGame()` → `onStartGame` → `beginGameplay()`
  (mirrors the `onResume` callback shape).
- **"Menu" on end overlays** uses the same name-matched dark-pill button pattern as
  RestartButton; `exitToMainMenu()` mirrors `restartGame()` minus starting waves.
- **UI tests**: every test now taps the menu's PLAY first (`startGame(_:)` helper waiting on
  `app.buttons["PLAY"]`) — and waves now start *after* the tap rather than during app launch,
  which actually makes the tests' early-wave timing more deterministic.
