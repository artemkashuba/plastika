# Plastika TD

Plastika TD is a 2D tower defense game for iOS built with Swift and SpriteKit.

The project currently has an initial iOS 17+ SpriteKit project shell, scene loading, game state management, placeholder system managers, path-following prototype enemies, visual build spots, tap-to-place placeholder towers, tower selection with range visualization, stable tower target locking, visible turret/barrel aiming, and a first automatic projectile combat loop.

## Documentation

The `docs/` directory is the source of truth for project direction, workflow, design, and task state.

Start here before making implementation changes:

- [Agent Workflow](docs/AGENTS.md)
- [Game Design](docs/GAME_DESIGN.md)
- [Roadmap](docs/ROADMAP.md)
- [Task Backlog](docs/TODO.md)
- [Current Task](docs/CURRENT_TASK.md)
- [Decisions](docs/DECISIONS.md)

## Current Status

Documentation workflow and the initial SpriteKit/Xcode project structure are established. The current prototype slice has one moving enemy wave, fixed build spots, one placeholder tower placement per empty build spot, selected tower feedback with attack range display, and towers that lock targets, aim their placeholder barrel, and destroy 1 HP enemies with straight placeholder projectiles.

Do not create implementation code without first reviewing and updating the documentation workflow in `docs/AGENTS.md`.
