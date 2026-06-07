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
