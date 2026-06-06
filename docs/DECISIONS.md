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
