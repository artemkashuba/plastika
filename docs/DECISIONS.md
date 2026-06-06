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

Decision:
Dim unaffordable build menu options to alpha 0.4 and block their taps silently.

Reason:
- Visual dimming gives the player immediate feedback without adding a separate error UI
- Silent block is consistent with the existing silent duplicate-placement block
- Alpha 0.4 is visually clear on the colored option circles without requiring new art
