# GAME_DESIGN.md

## High Concept

Plastika TD is a tower defense game where toy armies fight across tabletop battlefields.

Players defend strategic positions using towers while waves of enemy toys attempt to reach their objective.

## MVP Features

### Towers

Tower placement will use fixed circular build spots.

Early prototype build spots are toy bases around the enemy path. Players can tap an empty build spot to place one placeholder tower on it.

Placed placeholder towers automatically target the nearest enemy within an internal placeholder range and periodically fire simple magenta placeholder projectiles.

Prototype enemies currently have 1 HP. One projectile hit destroys an enemy and removes it from the battlefield.

Players can tap a placed placeholder tower to select it. The selected tower scales slightly, shows a thin white selection ring, and displays a subtle white circular range indicator centered on the tower's actual attack range. Tapping another placed tower transfers selection; tapping empty battlefield space clears it.

Placed placeholder towers do not support a selection menu, upgrades, selling, economy, splash damage, status effects, multiple tower types, or final art yet.

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
