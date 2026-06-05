# AGENTS.md

# Plastika TD

Plastika TD is a 2D tower defense game for iOS built with Swift and SpriteKit.

The game takes place in the world of Plastika, where toy armies wage cartoonish wars on tabletop battlefields.

## Mission

Build a polished, performant, and commercially viable tower defense game for iOS.

Priorities:

1. Fun gameplay
2. Smooth user experience
3. Performance
4. Clean architecture
5. Visual polish

Do not sacrifice gameplay for architecture perfection.

Shipping a playable game is more important than building a perfect system.

## Technology

Required:

- Swift
- SpriteKit
- Xcode
- Git

Target:

- iOS 17+
- 60 FPS minimum
- Native Apple experience

Avoid introducing unnecessary dependencies.

## Project Philosophy

Prefer:

- Simplicity
- Readability
- Maintainability
- Iterative development

Avoid:

- Premature optimization
- Overengineering
- Unnecessary abstractions
- Complex patterns without clear benefit

When in doubt, choose the simpler solution.

## Theme

The game is a humorous toy-soldier tower defense.

The tone should be:

- Playful
- Family-friendly
- Cartoonish

Avoid:

- Real countries
- Real wars
- Political content
- Graphic violence

The game should feel like toys fighting on a tabletop battlefield.

## Performance Rules

Performance is a core feature.

Prefer:

- Object pooling
- Sprite atlases
- Lightweight entities
- Efficient update loops

Avoid:

- Excessive node creation
- Excessive node destruction
- Expensive physics simulations
- Unnecessary allocations during gameplay

Target stable 60 FPS during combat.

## Architecture

Primary systems:

- GameScene
- WaveManager
- EnemyManager
- TowerManager
- ProjectileManager
- EconomyManager
- GameStateManager
- UIManager

Game logic should remain separate from UI whenever practical.

Favor composition over inheritance.

## Documentation Is Mandatory

Documentation is considered part of the codebase.

The `docs/` directory is the source of truth for the project.

Documentation must remain synchronized with the implementation.

If code and documentation disagree:

1. Update documentation immediately
2. Or explain why the code should be changed

Never leave documentation outdated.

## Documentation Workflow

Before starting implementation work, review:

- `docs/AGENTS.md`
- `docs/GAME_DESIGN.md`
- `docs/ROADMAP.md`
- `docs/TODO.md`
- `docs/CURRENT_TASK.md`
- `docs/DECISIONS.md`

Before writing code, update documentation if the planned work changes scope, design, architecture, task priority, or a prior decision.

After completing work, update all affected documentation files.

### TODO.md

Update whenever:

- Tasks are completed
- New tasks are discovered
- Priorities change

### CURRENT_TASK.md

Update whenever:

- Starting a task
- Completing a task
- Switching focus

This file should always reflect the current project state.

### DECISIONS.md

Update whenever:

- Technical decisions are made
- Design decisions are made
- Architecture changes

Record:

- Date
- Decision
- Reason

### GAME_DESIGN.md

Update whenever:

- Gameplay changes
- Towers change
- Enemies change
- Progression changes
- Monetization changes

### ROADMAP.md

Update whenever:

- Scope changes
- Milestones change
- Features move between phases

## Definition Of Done

A task is only complete when:

- Implementation is finished
- Project builds successfully, when a buildable project exists
- Documentation is updated
- `docs/TODO.md` is updated
- `docs/CURRENT_TASK.md` is updated
- Relevant decisions are recorded in `docs/DECISIONS.md`

## Development Approach

Build in small vertical slices.

Preferred order:

1. Working gameplay
2. UI
3. Visual effects
4. Sounds
5. Polish

Use placeholder assets until gameplay is proven fun.

Always prioritize creating a playable game as early as possible.
