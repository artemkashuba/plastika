# GAME_DESIGN.md

## High Concept

Plastika TD is a tower defense game where toy armies fight across tabletop battlefields.

Players defend strategic positions using towers while waves of enemy toys attempt to reach their objective.

## MVP Features

### Towers

Tower placement will use fixed circular build spots.

Early prototype build spots are toy bases around the enemy path. Players can tap an empty build spot to open a compact three-option tower menu below that spot. Tapping another empty build spot moves the menu, and tapping empty battlefield space hides it.

Selecting a menu option places one prototype tower on that build spot. Occupied build spots cannot place a second tower.

Placed prototype towers acquire the nearest enemy within an internal placeholder range, lock onto that enemy while it remains alive, in range, and tracked, and periodically fire simple magenta placeholder projectiles using their tower type behavior. The placeholder turret/barrel rotates toward the locked target so the tower visibly aims before and while shooting. At the instant each shot is fired, the barrel kicks back along its firing axis and a brief muzzle flash flares at the barrel tip, color-matched to that tower's projectile — heavier guns (Heavy Cannon > Missile Pod > Autocannon) recoil and flash more dramatically, giving each tower type a distinct shooting "feel". A small radial ring also appears around the tower's base at that moment, sweeping from empty to full over its reload duration and fading out the instant it's ready to fire again — a quick, glanceable readout of when each tower will shoot next.

Current prototype tower types:

1. Red Tower
   - Red visual identity
   - Fast attack speed (0.36s cooldown)
   - 1 damage per shot
   - Direct projectile behavior

2. Green Tower
   - Green visual identity
   - Homing projectile behavior
   - Slightly slower attack speed (0.58s cooldown)
   - 1 damage per shot

3. Blue Tower
   - Blue visual identity
   - Slow attack speed (0.90s cooldown)
   - 2 damage per shot — compensates for slow fire rate
   - Slow direct projectile behavior with predictive aiming — fires at the enemy's intercept position

Prototype enemies have 5 HP. A health bar appears above each enemy after the first hit, color-coded green → yellow → red as health decreases.

Players can tap a placed prototype tower to select it. The selected tower scales slightly, shows a thin white selection ring, and displays a subtle white circular range indicator centered on the tower's actual attack range. Tapping another placed tower transfers selection; tapping empty battlefield space clears selection and hides any open build menu.

All projectiles are color-coded by tower type (Red = orange, Green = lime, Blue = cyan) and produce a small expanding flash on impact.

Placed prototype towers do not support upgrades, selling, economy, splash damage, status effects, final art, or multiple enemy types yet.

Future themed tower concepts:

1. Rifle Tower
   - Fast attack speed
   - Low damage

2. Cannon Tower
   - Slow attack speed
   - Area damage

3. Glue Tower
   - Slows enemies

### Enemies

Early prototype enemies move along the hardcoded path and use basic 1 HP combat health.

1. Scout
   - Fast
   - Low HP

2. Soldier
   - Balanced

3. Tank
   - Slow
   - High HP

### Economy

- Coins earned from kills
- Towers purchased with coins
- Towers can be upgraded

### Victory

Defeat all enemies in the wave.

### Defeat

Base health reaches zero. Player starts with 3 lives. Each enemy that reaches the path end costs one life.

## Art Direction

- Bright colors
- Plastic toy appearance
- Clean silhouettes
- Easy readability
- Tabletop battlefield presentation

## Tone

- Playful
- Family-friendly
- Cartoonish
- Humorous without referencing real wars or politics

## Monetization

- Remove Ads purchase
- Cosmetic skins only
- No pay-to-win mechanics
