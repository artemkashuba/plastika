# GAME_DESIGN.md

## High Concept

Plastika TD is a tower defense game where toy armies fight across tabletop battlefields.

Players defend strategic positions using towers while waves of enemy toys attempt to reach their objective.

## MVP Features

### Towers

Tower placement will use fixed circular build spots.

Early prototype build spots are toy bases around the enemy path. Players can tap an empty build spot to open a compact three-option tower menu below that spot. Tapping another empty build spot moves the menu, and tapping empty battlefield space hides it.

Selecting a menu option places one prototype tower on that build spot. Occupied build spots cannot place a second tower.

Placed prototype towers acquire the nearest enemy within an internal placeholder range, lock onto that enemy while it remains alive, in range, and tracked, and periodically fire simple magenta placeholder projectiles using their tower type behavior. The placeholder turret/barrel rotates toward the locked target so the tower visibly aims before and while shooting.

Current prototype tower types:

1. Red Tower
   - Red visual identity
   - Fast attack speed
   - Direct projectile behavior

2. Green Tower
   - Green visual identity
   - Homing projectile behavior
   - Slightly slower attack speed than Red

3. Blue Tower
   - Blue visual identity
   - Slow attack speed
   - Slow direct projectile behavior
   - Future TODO: predictive aiming after enemy speed and lead tuning exist

Prototype enemies currently have 1 HP. One projectile hit destroys an enemy and removes it from the battlefield.

Players can tap a placed prototype tower to select it. The selected tower scales slightly, shows a thin white selection ring, and displays a subtle white circular range indicator centered on the tower's actual attack range. Tapping another placed tower transfers selection; tapping empty battlefield space clears selection and hides any open build menu.

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

Defeat all waves.

### Defeat

Base health reaches zero.

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
