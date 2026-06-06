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
