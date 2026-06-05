# AGENTS.md

## Project

Plastika TD is a 2D tower defense game for iOS built with Swift and SpriteKit.

The game takes place in the world of Plastika, where toy armies wage cartoonish wars on tabletop battlefields.

## Core Principles

- iOS only
- SpriteKit only
- Performance first
- Target 60 FPS on modern iPhones
- Gameplay before visuals
- Avoid overengineering
- Prefer simple solutions

## Theme

Funny toy-soldier warfare.

Do not use real countries, political symbols, real military organizations, or realistic war themes.

The tone should be playful, lighthearted, and suitable for all ages.

## Architecture

Main systems:

- GameScene
- WaveManager
- EnemyManager
- TowerManager
- EconomyManager
- UIManager
- GameStateManager

## Coding Rules

- Favor composition over inheritance.
- Keep systems small and testable.
- Avoid massive view controllers.
- Keep game logic independent from UI.
- Minimize SpriteKit node creation during gameplay.
- Reuse objects whenever possible.

## Development Process

Before implementing major features:

1. Review TODO.md
2. Review CURRENT_TASK.md
3. Review DECISIONS.md

After completing a task:

- Update TODO.md
- Update CURRENT_TASK.md
- Record important decisions in DECISIONS.md

## Current Goal

Build a playable MVP before adding advanced features.
