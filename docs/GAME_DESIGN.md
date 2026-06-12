# GAME_DESIGN.md

## High Concept

Plastika TD is a tower defense game where toy armies fight across tabletop battlefields.

Players defend strategic positions using towers while waves of enemy toys attempt to reach their objective.

## MVP Features

### Towers

Tower placement will use fixed circular build spots.

Early prototype build spots are toy bases around the enemy path. Players can tap an empty build spot to open a compact tower menu below that spot, evenly spaced and centered regardless of how many tower types exist. Tapping another empty build spot moves the menu, and tapping empty battlefield space hides it.

Selecting a menu option places one prototype tower on that build spot. Occupied build spots cannot place a second tower.

Two of the four prototype tower types (Red, Blue) sit on an identical round toy-turret base — a glossy circular plate with a specular highlight, like plastic toys from the same product line. The other two break from that mould, each with its own chassis silhouette: the Laser Lance sits on a flat-topped hexagonal "energy platform" ringed with three small glowing power vents that idle-pulse out of sync with one another — a permanent, always-on "tell" that reads as a fundamentally different kind of machine even at rest, before it ever fires a shot — while the Missile Pod sits on a stout rectangular "armored launch deck" (rounded hull plate, specular highlight, corner rivets) topped by a single solid launcher-hull gun assembly with twin recessed launch holes, reading as a compact rocket truck rather than a turret with thin barrels stuck on top.

Placed prototype towers acquire the nearest enemy within an internal placeholder range, lock onto that enemy while it remains alive, in range, and tracked. Most towers periodically fire simple magenta placeholder projectiles using their tower type behavior — the placeholder turret/barrel rotates toward the locked target so the tower visibly aims before and while shooting. That rotation traverses at a per-type maximum speed rather than snapping instantly, giving each gun a distinct weight: the Autocannon whips around almost at once, the Missile Pod swings at a medium pace, the Laser Lance sweeps quickly onto its mark, and the Mortar's heavy tube labors for nearly two seconds to come about 180°. The traverse is purely cosmetic — firing schedules never wait for alignment, so combat output is unchanged. At the instant each shot is fired, the barrel kicks back along its firing axis and a brief muzzle flash flares at the barrel tip, color-matched to that tower's projectile — heavier guns (Mortar > Missile Pod > Autocannon) recoil and flash more dramatically, giving each tower type a distinct shooting "feel". A small radial ring also appears around the tower's base at that moment, sweeping from empty to full over its reload duration and fading out the instant it's ready to fire again — a quick, glanceable readout of when each tower will shoot next.

One tower type — the Laser Lance — fights differently: instead of discrete shots, it projects a persistent glowing beam at its locked target for as long as the lock holds, dealing continuous damage every frame rather than firing in bursts. It never recoils, flashes, or shows a reload ring, since it has no discrete "shot" to animate around — its tell is the beam itself, always-on while a target is in range.

Current prototype tower types:

1. Red Tower — "Autocannon" (50 coins)
   - Red visual identity, on the shared round toy-turret base. Its gun is a proper
     twin-autocannon **turret**: a chunky rounded housing (bright red livery, glossy
     highlight, commander's hatch) with two dark barrels protruding from a front mantlet.
     The housing is fixed to the rotation pivot; on each shot only the barrels recoil,
     sliding back *into* the housing and springing out — reading as a rapid-fire autocannon
     cycling rather than a whole turret kicking
   - Fast attack speed (0.28s cooldown)
   - 1 damage per shot
   - Direct projectile behavior
   - ≈ 3.6 DPS

2. Green Tower — "Missile Pod" (50 coins)
   - Stands apart from the rest of the roster visually: a rectangular "armored launch deck" chassis and solid launcher-hull gun assembly (rather than the round toy-turret base + thin barrels), firing a tapered rocket — nose cone, tail exhaust glow, and a thick, clearly visible drifting smoke trail — that visibly rotates to face its direction of travel in flight, instead of a plain re-tinted glow-ball
   - The roster's **long-range artillery support**: 306pt acquisition range, 75% beyond the 175pt everyone else shares — it starts working on enemies most of a screen away
   - Homing projectile behavior — its rockets chase their target until impact regardless of the tower's attack range; and if that target dies or breaches while a rocket is still in the air, the rocket doesn't vanish — it flies on to where the target last was and detonates harmlessly on the road (a small color-matched blast, no damage), so a launched missile always resolves on the battlefield
   - Slow-cruising rockets (168pt/s, the slowest projectile in the roster) — they're guaranteed to hit anyway, and the long lazy flight draws a smoke arc across the battlefield
   - Slower attack speed (0.75s cooldown), heavier 3-damage warhead
   - = 4.0 DPS — strong sustained single-target output befitting its reach

3. Blue Tower — "Mortar" (50 coins)
   - A high-angle artillery piece, visually distinct from the rest of the roster: a chunky upward-flaring tube with a 3D angled steel mouth (bore + specular glint), sitting on a baseplate + bipod, rather than a flat rotating barrel
   - Slow attack speed (1.85s cooldown) — heavy, deliberate volleys, with the reload ring sweeping at a correspondingly unhurried pace
   - Everything about it moves sluggishly by design: the tube traverses at the roster's slowest speed (≈2s to come about 180°), so it visibly labors to bring new bearings under fire
   - 5 damage per shell, dealt as **splash**: lobs an arcing shell onto the road and explodes on impact, damaging *every* enemy within a 55pt blast radius rather than a single target
   - Acquires the *lead* enemy (the one closest to the base) and **commits** to it — shelling its predicted road position until it dies, breaches, dives into the tunnel, or leaves range — rather than re-evaluating the front every frame, which kept the tube whipping around
   - The roster's area/crowd-control specialist — the other three are all single-target (direct, homing, beam)
   - ≈ 2.7 DPS single-target (close to its pre-rework ≈2.9 — the slower reload is offset by a heavier shell), but far higher *effective* DPS against bunched groups

4. Pink Tower — "Laser Lance" (75 coins)
   - Stands apart from the rest of the roster at a glance: instead of the round toy-turret base every other tower shares, it sits on an angular hexagonal "energy platform" ringed with three small power vents that idly pulse a living neon-red glow — always breathing, even before it ever locks a target — while its slim emitter housing and glowing lens keep the pink/magenta chassis identity, and its signature beam glows a vivid neon red rather than matching its housing, reading as a hot, electric "laser red"
   - Locks onto a single target and projects a continuous beam at it for as long as the lock holds, draining its HP smoothly every frame and leaving a small flickering plasma-burn mark where the beam makes contact (no discrete shots, no cooldown, no recoil/flash/reload ring)
   - ≈ 4.5 DPS — the highest single-target DPS in the roster, reflecting its higher cost and guaranteed-hit reliability

Enemy HP now varies by type (see Enemies below — Soldier's 8 HP is the baseline every other type is defined relative to). A health bar appears above each enemy after the first hit, color-coded green → yellow → red as health decreases, and drains in genuinely smooth fractional steps under sustained laser fire (rather than snapping between whole-HP increments) while remaining visually identical to the old behavior under ordinary discrete hits.

Players can tap a placed prototype tower to select it. The selected tower scales slightly, shows a thin white selection ring, and displays a subtle white circular range indicator centered on the tower's actual attack range. Tapping another placed tower transfers selection; tapping empty battlefield space clears selection and hides any open build menu.

All projectiles are color-coded by tower type (Red = orange, Green = lime, Blue = cyan) and produce a small expanding flash on impact. Most fly as a simple glow-behind-bright-core orb, but the Missile Pod's lime-green warheads instead take a distinct "guided missile" form — a tapered body with a glowing nose cone, a warm-orange tail exhaust, and a drifting smoke trail — and visibly rotate to face their heading as they home in. The Mortar's munition is different again: a dark finned shell (cyan-accented) that lobs in a visible arc — rotating to follow its trajectory, nose-up as it climbs and nose-down as it plunges — with a growing ground shadow beneath it, lands on the road, and detonates in a fiery orange explosion — a white-hot core, an expanding shockwave ring, and a scatter of smoke puffs — rather than a colored orb with a small flash. The Laser Lance's signature neon-red tint instead colors its continuous beam — and the flickering plasma-burn mark it leaves where that beam makes contact.

Placed prototype towers support selling, the economy loop, and now upgrades (see below); the Mortar adds the roster's first splash/area damage. They still lack status effects and final art.

Future themed tower concepts:

1. Rifle Tower
   - Fast attack speed
   - Low damage

2. Cannon Tower
   - Slow attack speed
   - Area damage

3. Glue Tower
   - Slows enemies

Design guidance for growing this roster: keep it tight, and make sure every entry earns its place. The current four already model four genuinely different ways to deal damage — direct-fire, homing, lobbed area-of-effect (mortar), and continuous-beam — rather than DPS-variant reskins of one mechanic; new types (Rifle/Cannon/Glue and beyond) should clear the same bar by owning a clear "best at X" niche (burst vs. sustained, single-target vs. crowd, damage vs. utility/control). A wider roster only adds strategic depth if each tower remains worth building in some real situation — padding the list with towers that are strictly outclassed by others does the opposite.

### Battlefield & Path

The battlefield is a 5-lane serpentine: enemies spawn at the bottom-left camp, switch back and
forth across the table, and breach the base at the top-right. Eight build spots sit in two
columns in the gaps between lanes.

The middle lane runs **underground** — a tunnel. While traversing it, enemies are hidden,
untargetable, and immune to damage, re-emerging at the far mouth. Like a real tunnel seen from
above, it is indicated only at its two ends: the road simply stops (grass continues over the
buried stretch, with no band or outline of any kind along its length) and a grassy hillside
portal — mound, stone facade, dark arched opening aligned with the connecting road — marks each
mouth. Enemies visibly *dive* into the entrance (shrinking and fading into the opening, kicking
up dust) and *pop out* of the exit with a small overshoot, so going underground reads as a
mechanic rather than a glitch. The build spots flanking the exit are the natural "kill zone"
where surfacing enemies can be punished.

### Enemies

Enemies move along the fixed path and share one toy-tank chassis silhouette —
shadow, twin tracks, hull, turret, barrel, and a health bar that appears above
them after the first hit (color-coded green → yellow → red as health drains,
in genuinely smooth fractional steps under continuous fire). What sets each
type apart is stats, not just looks: a recolored "paint job" and a uniform
rescale of that shared chassis read as a different machine at a glance, while
HP, speed, and value are what actually make each one play differently —
mirroring how the tower roster differentiates mostly through livery on shared
silhouettes.

Enemies also *feel* alive in motion: they pop onto the table with a small scale-up when
spawned (a toy being placed), their upper chassis idles with a subtle engine-rumble bob on the
tracks, and they kick up a faint dust trail behind them as they drive (faster types more
often). Every discrete hit that lands flashes the hull white for a fraction of a second, so
incoming damage visibly registers between health-bar ticks.

When an enemy is killed by damage (as opposed to reaching the base), it doesn't
just vanish — it bursts apart "blown-apart toy" style: a white-hot flash, an
expanding shockwave ring, and a scatter of its own livery-colored debris (hull
chunks, the turret, dark track bits) flying outward, spinning, and fading. The
burst is sized by chassis scale, so a Tank dies bigger and messier than a Scout.
An enemy that breaches the base shows no such burst — only kills are celebrated.

1. Scout — bright orange livery, smaller chassis (0.82×)
   - Fast (1.35× the baseline path speed)
   - Low HP (5) — dies in roughly one or two hits from almost anything,
     rewarding towers that can land that hit before it crosses the screen
   - Worth fewer coins on a kill (6) — reflecting how little effort it costs
     to bring down

2. Soldier — original maroon livery, baseline chassis size (1.0×)
   - The balanced default: 8 HP, the original fixed path speed (1.0×),
     10-coin kill reward — every other type is defined relative to it

3. Tank — dull armored livery, larger chassis (1.28×)
   - Slow (0.65× the baseline path speed)
   - High HP (18) — needs sustained fire to bring down, rewarding
     heavy-hitting or continuous-damage towers
   - Worth more coins on a kill (18) — compensating for the time and fire
     it costs to take one down

Each spawn during a wave randomly picks from that wave's available roster —
wave 1 mixes Soldier and Scout only (easing the player in before the toughest
type appears), wave 2 onward folds the Tank into the mix. Every type remains
killable, if inefficiently, by every tower in the roster — by design (see the
guidance below): nothing here is a hard counter or a guaranteed bad matchup.

Design guidance for this roster: give each type meaningfully different stats (and, later, resistances/status interactions) so they create real tactical variety — but keep every counter "soft". No enemy type should be effectively unkillable by anything except one specific tower (a "lock-and-key" pattern that turns combat into a memorization/savings check rather than a tactical decision); a player should always have at least one sub-optimal-but-viable way to deal with anything on the board. Flying or path-ignoring enemy types should be avoided entirely — they tend to break the core "defend the path" loop rather than enrich it.

### Economy

- Coins earned from kills
- Towers purchased with coins
- Towers can be upgraded: tap a selected tower to reveal a second cyan "▲ cost"
  badge above it (mirroring the gold sell badge below). Each tap spends coins and
  advances the tower one tier, up to 2 tiers (3 total stages: base, +1, +2).
  Every tier adds a flat +50% of the tower's *base* damage/DPS — additive, not
  compounding — while range, attack speed, and everything else about the tower
  stays exactly as placed. Upgrade cost ramps off the tower's own placement price
  (tier 1 ≈ 60% of cost, tier 2 = 100% of cost), so fully committing to one tower
  is a deliberate, escalating investment. A small glowing "tier pip" appears under
  the tower's base plate per upgrade purchased — a permanent, at-a-glance readout
  of how invested that tower is. Selling an upgraded tower refunds half of
  everything spent on it (placement plus every upgrade), not just half of the
  original placement cost

### Victory

Defeat all enemies across every scripted wave. A level plays out as a sequence of waves —
each tougher than the last (more enemies, spawning faster) — separated by a short
on-screen countdown once the previous wave is fully cleared, giving the player a moment
to regroup, reposition, or build before the next wave begins.

### Defeat

Base health reaches zero. Player starts with 3 lives. Each enemy that reaches the path end costs one life.

## Art Direction

- Bright colors
- Plastic toy appearance
- Clean silhouettes
- Easy readability
- Tabletop battlefield presentation

### Battlefield Scenery

The tabletop is dressed with static, purely-decorative toy scenery to break up the bare green —
round "lollipop" trees, triangular pines, bushes, rocks, and grass tufts scattered through the
empty pockets away from the road and build spots, each with a soft shadow and specular highlight
matching the roster's toy-plastic look. Two markers also anchor the route's readability: a khaki
enemy "camp" (tent + maroon flag, the enemy livery color) at the spawn point, and a friendly
"base" bunker (cyan flag) at the path end the player defends. All of it is cosmetic, hand-placed
at fixed positions (so the map reads as designed, not random), and rendered below gameplay units
so towers, enemies, and projectiles always draw clearly on top.

The presentation also sells the "toys on a table" framing and quietly breathes: the grass mat
sits on a wooden tabletop frame (with faint plank-grain lines showing in the margins), a soft
vignette darkens the mat's edges so the field reads as lit from above, a barely-there cloud
shadow drifts across the table on a long loop, trees, bushes, and grass tufts sway gently out
of phase with one another, and the camp/base pennants flutter on their poles. Impact moments
get physical feedback too: mortar detonations and base breaches briefly shake the whole screen.

### Haptics

On device, the game's key moments also play tactile feedback (toggleable in the pause menu,
beside the sound switch, and on by default): a solid tap when placing a tower, a crisper one
when upgrading, a light one when selling; a heavy thud on a mortar detonation; a light, throttled
tap on each enemy kill; a "warning" buzz when an enemy breaches the base; and success/error
notifications on victory/defeat. Per-shot firing is intentionally silent to the touch — the
fastest tower would otherwise buzz continuously — so the Mortar's detonation carries the
roster's "heavy weapon" feel. Haptics are device-only and do nothing on the simulator.

## Tone

- Playful
- Family-friendly
- Cartoonish
- Humorous without referencing real wars or politics

## Monetization

- Remove Ads purchase
- Cosmetic skins only
- No pay-to-win mechanics
