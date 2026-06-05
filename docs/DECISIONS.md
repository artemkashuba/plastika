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
