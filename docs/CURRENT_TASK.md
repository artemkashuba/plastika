# CURRENT_TASK.md

## Current Status

First gameplay slice is complete.

The repository now has:

- A canonical `docs/` documentation structure
- A root `README.md`
- An iOS 17+ Xcode project
- A SwiftUI app entry point hosting SpriteKit through `SpriteView`
- A `GameScene` that loads a simple tabletop placeholder view
- Placeholder managers for the documented systems
- A `PathManager` with a hardcoded waypoint path
- One placeholder enemy shape moving smoothly along that path

## Next Task

Add the next prototype slice: introduce a minimal wave spawning flow that can create the existing placeholder enemy from the path start.

Before starting, review the documentation workflow in `docs/AGENTS.md`.

## Immediate Goal

Reach first playable prototype with:

- One map
- One enemy type moving along a path
- One tower type
- One wave

## Blockers

None.
