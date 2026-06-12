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
- [x] Add a second wave with an inter-wave countdown (3s "WAVE 2 IN 3..." HUD announcement)
- [x] Add Pink "Laser Lance" tower — continuous-beam single-target damage, smooth fractional HP drain, 75-coin cost, 4-option build menu
- [x] Add neon breathing pulse to the laser beam, and a flickering plasma-burn mark where it makes contact with its target
- [x] Give the Laser Lance a unique chassis — angular hexagonal "energy platform" with idle-pulsing power vents (always-on from placement, independent of combat)
- [x] Give the Laser Lance a one-shot "ignition" sound — a real recorded laser-gun sample (trimmed to its first second, converted to the project's standard format) that fires exactly once at the instant the beam locks onto a target ("the laser starts heating"), fitting the existing fire-and-forget one-shot sound model with no new looping machinery
- [x] Add tower upgrades — tap a selected tower's cyan "▲ cost" badge (mirrors the gold sell badge, positioned above instead of below) to spend coins and bump it through 2 tiers (3 stages total), each adding +50% damage/DPS over base; cost ramps per tier (≈60% of placement price, then 100%); a small glowing tier-pip cluster appears under the base plate; sell refund now accounts for upgrade spend too
- [x] Redesign Blue tower into a "Mortar" — lobs an arcing shell (dark finned bomb + ground shadow) onto the lead enemy's predicted road position and detonates in a fiery orange explosion with splash damage (55pt radius), giving the roster its area/crowd-control niche; new chunky high-angle tube visual with a 3D angled mouth (replaces the flat predictive-aim cannon)
- [x] Add an enemy death effect — on a damage kill (not a base breach), the enemy bursts into a white-hot flash, an expanding shockwave ring, and a scatter of its own livery-colored debris (hull chunks, turret, track bits), sized by chassis scale, instead of vanishing
- [x] Redesign Green "Missile Pod" visuals — unique rectangular "armored launch deck" chassis + solid launcher-hull gun assembly (replacing its old round chassis + thin twin tubes), and a new `ProjectileVisualStyle.rocket` projectile look (tapered body, nose cone, tail exhaust glow, drifting smoke trail, rotates to face its direction of travel) replacing the plain glow-ball every type otherwise shares
- [x] Add haptics — `HapticsManager` (mirrors the sound model: persisted pause-menu toggle, device-only) firing on tower place/upgrade/sell, mortar detonation (heavy), enemy kills (light, throttled), base breach (warning), victory (success), defeat (error), and HUD button taps (selection); per-shot firing deliberately excluded to avoid buzzing
- [x] Add main menu — new `.mainMenu` phase + SwiftUI `MainMenuView` (title, pulsing PLAY, sound/haptics toggles, hardcore tagline) shown over the built-but-idle battlefield; waves start on PLAY, and the victory/defeat overlays gained a "Menu" button returning to it
- [ ] Add level select
- [x] Add enemy variety — Scout/Soldier/Tank with meaningfully different stats (not palette swaps) and "soft" counters: every type should stay killable, if inefficiently, by more than one tower (avoid lock-and-key design, and avoid flying/path-ignoring enemy types entirely)
- [x] Redesign the map into a 5-lane serpentine with an underground tunnel segment — enemies dive in at one mouth (hidden, untargetable, immune) and re-emerge at the other; 8 build spots in two columns between the lanes; UI tests realigned to the new layout
- [ ] Add "total time control" UX — let the player issue build/sell actions while paused, plus a 2x/4x speed-up toggle for skipping through easy or already-won waves
- [ ] Add "total information" readouts — tap-to-inspect full stats on enemies (mirrors the existing tower ARSENAL panel: HP, speed, resistances/status effects) and a wave preview showing upcoming enemy types/counts before they spawn

## Phase 3 - Polish

- [x] Draft AI-generation art-asset brief and style guide (`docs/ART_ASSET_BRIEF.md`) — prep for the reskin below
- [x] Add decorative tabletop scenery — toy trees (round + pine), bushes, rocks, and grass tufts in the empty green, plus a spawn "camp" marker and a base/objective marker at the path ends (purely cosmetic, fixed positions, rendered below gameplay units) — `SceneryFactory`
- [x] Make the tunnel read like a real underground passage — no colored outline along its length: the road simply stops (grass continues over the buried stretch) and a grassy hillside portal (mound + stone facade + dark opening, aligned with the connecting road) marks each mouth; enemies dive in (shrink + fade + dust) and pop out (overshoot scale-up + dust) instead of blinking
- [x] Visual feel pass — enemy hull "engine rumble" bob, dust trails behind driving enemies, spawn pop, white hit-flash on discrete hits, screen shake on mortar detonations and base breaches (`SKCameraNode` + `shakeScreen`)
- [x] Environment depth pass — wooden tabletop frame with grain lines, soft vignette over the grass mat, drifting ambient cloud shadow, gentle sway on trees/bushes/grass tufts, fluttering marker flags
- [x] Add per-type turret traverse speed (rate-limited rotation, cosmetic only) — Mortar slowest (≈2s for 180°) for a heavy, sluggish feel; Mortar also commits to its locked target instead of re-picking the lead each frame, and its tempo deepened (1.85s reload / 5-damage shell, DPS ≈ unchanged)
- [x] Rework Green "Missile Pod" into long-range artillery support — range +75% (306pt, first per-type range; selection circle now re-sizes per tower), rockets −30% speed (168), +30% DPS (3-damage warhead / 0.75s = 4.0), and a clearly visible smoke trail (brighter, bigger, denser puffs)
- [x] Make orphaned Green missiles land instead of vanishing — when a homing missile's target dies/breaches mid-flight it commits to the target's last-known road spot and detonates there (cosmetic, color-matched flash + shockwave ring, no damage), instead of blinking out of the air
- [x] Redesign Red "Autocannon" gun into a proper twin-autocannon turret — a chunky rounded housing (hatch + glossy highlight) fixed to the pivot, with two barrels protruding from a front mantlet that recoil/cycle *into* the housing (instead of two bare barrels on a small disc)
- [ ] Replace placeholder art
- [ ] Improve animations
- [ ] Add skins
- [ ] Add monetization
- [ ] App Store preparation
