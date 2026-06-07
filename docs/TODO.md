# TODO.md

## Documentation Bootstrap

- [x] Create `docs/AGENTS.md`
- [x] Create `docs/GAME_DESIGN.md`
- [x] Create `docs/ROADMAP.md`
- [x] Create `docs/TODO.md`
- [x] Create `docs/CURRENT_TASK.md`
- [x] Create `docs/DECISIONS.md`
- [x] Create root `README.md`
- [x] Establish `docs/` as the project source of truth

## Phase 1 - Prototype

- [x] Create SpriteKit/Xcode project
- [x] Create folder structure for Core, Managers, Entities, UI, Resources, and Scenes
- [x] Create placeholder managers for documented systems
- [x] Create GameScene
- [x] Create initial scene loading flow
- [x] Create initial game state management
- [x] Create enemy movement system
- [x] Create path system
- [x] Create wave spawning system
- [x] Add visual-only tower build spots
- [x] Add prototype debug HUD
- [x] Create tower placement system
- [x] Add UI verification for tower placement interaction
- [x] Create projectile system
- [x] Create combat system
- [x] Add UI verification for first combat loop
- [x] Add tower selection and range visualization
- [x] Add UI verification for tower selection, switching, and deselecting
- [x] Add stable tower target locking
- [x] Add visible turret/barrel aiming toward locked targets
- [x] Add UI verification for placeholder tower barrel aiming
- [x] Add tower type selection menu for empty build spots
- [x] Add Red, Green, and Blue prototype tower types
- [x] Add type-specific direct and homing projectile behavior
- [x] Add UI verification for build menu movement, hiding, and typed tower placement
- [x] Create economy system
- [x] Create win/lose conditions
- [x] Fix homing projectile range abort (Green missiles now follow target until impact)
- [x] Add per-tower projectile colors (Red = orange, Green = lime, Blue = cyan)
- [x] Add predictive aiming for Blue tower
- [x] Add impact flash effect on projectile hit

## Phase 2 - Vertical Slice

- [x] Add placeholder UI (top-bar HUD: coin icon + count, wave badge, heart icons for lives)
- [x] Add tower selling
- [x] Add sound effects (tower shoot × 3, enemy hit, enemy death, enemy breach, tower place, tower sell)
- [x] Add coin-fly reward animation on enemy kill
- [x] Add barrel recoil and muzzle-flash shooting animations (recoil scales with gun weight: Red < Green < Blue)
- [x] Add a small radial reload-timer ring around each tower, visible only while reloading
- [ ] Add tower upgrades
- [ ] Add haptics
- [ ] Add main menu
- [ ] Add level select

## Phase 3 - Polish

- [ ] Replace placeholder art
- [ ] Improve animations
- [ ] Add skins
- [ ] Add monetization
- [ ] App Store preparation
