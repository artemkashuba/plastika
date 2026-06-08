# ART_ASSET_BRIEF.md

## Purpose

A reference brief for the eventual Phase 3 art pass — replacing today's procedural
placeholder graphics with illustrated/rendered sprite assets sourced via AI image
generation. It captures the target visual style (anchored to a reference screenshot
and to `GAME_DESIGN.md`'s existing Art Direction section), a full inventory of the
assets that would need to be produced, the technical specs each asset must meet to
drop cleanly into the SpriteKit pipeline, and prompt templates to keep dozens of
generations visually consistent with each other.

## Status

Prep work for **Phase 3 — Polish** (see `ROADMAP.md` "Final art pass" and `TODO.md`
"Replace placeholder art"). Phase 2 gameplay work continues unaffected — this brief
exists purely so the eventual reskin can move quickly once it actually begins. Treat
it as a living starting point, not a locked spec; revisit and refine it once the pass
starts.

## 1. Target Visual Style

The user shared a reference screenshot of a polished mobile tower-defense game that
matches — almost exactly — the "Plastic toy appearance" / "Tabletop battlefield
presentation" already written into `GAME_DESIGN.md`'s Art Direction section. That
screenshot should be the north star for the eventual pass. Carry these descriptors
into every asset and every prompt:

- Soft "claymation" / matte-plastic toy material — rounded geometric forms, no sharp edges or hard angles
- Warm, saturated-but-not-garish palette — primary tower colors (red/green/blue) popping against soft pastel-green grass
- Soft ambient-occlusion-style contact shadows beneath every object, grounding it like a toy on a tabletop
- Subtle specular highlights / rim lighting on rounded surfaces — gives the glossy-plastic feel
- Slight 3/4 isometric-leaning top-down camera angle (not a flat orthographic top-down)
- Clean, simple, instantly-readable silhouettes — must read clearly at small mobile sizes
- Glow/bloom accents on interactive elements (projectiles, pickups, status icons) to draw the eye exactly where gameplay needs attention
- **Toy-serious, not cute** — character design should read like detailed plastic toy-soldier/miniature figures with a stoic, grounded presence, not cartoon mascots with big eyes and goofy smiles. The "toy" comes through in the material (matte plastic/clay, rounded forms, tabletop scale); the "serious" comes through in posture and expression — determined rather than adorable. This still sits comfortably inside `GAME_DESIGN.md`'s documented tone (family-friendly, humorous, no real-world war/political references) — think classic plastic toy-soldier playsets, not anything graphic or grim.

## 2. Asset Inventory

### Towers (Red/Autocannon, Green/Missile Pod, Blue/Heavy Cannon)

- One idle-state composite per type: pedestal/base + turret + barrel, matte-plastic and color-coded
- Either rotation-frame sets per type, or a base/turret split that supports runtime rotation of just the turret layer (mirrors the existing `aimNode`/`barrelNode` split — see Section 5)
- Optional status-badge icons (the reference shows a snowflake and a flame on two towers — a natural fit for future tower specializations/upgrades)

### Enemies (Scout, Soldier, Tank — plus future themed sets)

- Idle/walk sprite(s) per type — grounded toy-miniature/toy-soldier-like silhouettes with a stoic, determined presence (not cartoon mascots), color-coded by type and scaled to feel like figures on a tabletop
- Health-bar chrome (small pill/bar that floats above each enemy)

### Environment

- Ground/grass tile texture(s)
- Path/road texture — straight and curve segments, or a single paintable spline-friendly texture
- Decorative scatter props for the battlefield border: trees (2–3 variants), bushes, mushrooms, flowers, rocks
- Empty build-spot marker (dashed outline + "+" indicator, per the reference)

### Projectiles & Effects

- Per-tower projectile sprite/glow, color-matched to the existing palette (orange / lime / cyan)
- Muzzle-flash burst
- Impact-flash burst
- Coin pickup (with glow halo) and a coin-fly arc sprite for the reward animation
- Elemental/status icons, if tower specializations are introduced later

### UI Chrome

- HUD bar background (rounded dark pill/bar)
- Coin icon, heart icons (full and "lost" states)
- Wave-number pill badge
- Pause button
- Build-menu option cards
- Sell badge pill
- Buttons for overlays/menus (restart, resume, etc.)

## 3. Technical Specs (so AI-generated assets drop cleanly into SpriteKit)

- **Format**: PNG with alpha transparency for all sprites; full-bleed tile textures can be opaque
- **Resolution**: export at @2x/@3x for Retina; lock down a baseline size per category once the style is finalized (e.g., towers roughly 256×256 px @1x)
- **Consistent light direction** across every asset (top-left or top-down, matching the reference) — otherwise shadows and highlights will visibly disagree once composited side by side
- **Consistent camera/perspective angle** across every category — a tower and an enemy standing on the same tile must look like they belong in the same scene
- **Naming convention** for atlas-friendly organization: `<category>_<type>_<state>@<scale>x.png` (e.g. `tower_red_idle@2x.png`), mapping cleanly onto `SKTextureAtlas` folder structure
- If the AI tool can't produce clean alpha directly, generate against a flat color-key background that's trivial to crop/key out in post

## 4. AI Prompt Templates

**Base style suffix — append to every prompt to keep results consistent:**

> ...soft claymation / matte-plastic toy render, rounded geometric shapes, warm
> saturated color palette, soft ambient-occlusion contact shadow beneath, subtle
> specular highlight, 3/4 isometric top-down camera angle, clean simple silhouette,
> toy-serious and grounded rather than cute or cartoonish, transparent background,
> mobile game asset, centered composition

**Starting points per category** (adapt the bracketed details, then append the suffix above):

- **Tower**: "A small toy-like turret cannon mounted on a rounded square pedestal, [color] matte plastic material, single thick barrel pointing up-right, glossy highlight along the barrel's top edge, sturdy and purposeful silhouette, ..."
- **Enemy**: "A small toy-soldier-like figure with a stoic, determined expression, [color] matte plastic/clay material, simple proportionate toy-miniature build, planted stance, ..."
- **Prop**: "A small rounded toy tree with a thick brown trunk and a puffy spherical green canopy, ..."
- **Pickup**: "A glowing golden coin with a soft halo of light, beveled embossed edge, ..."

## 5. Technical Integration Plan (for when the pass begins)

- Replace the `SKShapeNode`-based procedural geometry in `PlaceholderTower`,
  `TowerGunFactory`, `PlaceholderEnemy`, `PlaceholderProjectile`, `BuildSpotManager`,
  and `UIManager` with `SKSpriteNode` instances loaded from `SKTextureAtlas`
- Bundle generated PNGs into `.atlas` folders — Xcode auto-packs these into runtime texture atlases
- Keep all gameplay/manager logic (combat, pathing, economy, target locking, etc.)
  untouched; this is purely a visual-layer swap
- The existing turret/barrel split (`Assembly.aimNode` / `Assembly.barrelNode`,
  introduced for the recoil animation) maps naturally onto a base-sprite +
  turret-sprite composite — recoil, aiming, and the reload ring all keep working
  unchanged on top of sprite-based art
- Consider `SKEmitterNode`-based particle effects (`.sks` files authored in Xcode's
  Particle Emitter Editor) for glow/sparkle accents that flat procedural shapes can't
  easily achieve
- Re-tune zPositions, scales, and anchor points once real asset dimensions are known —
  current placeholder values are tuned to procedural shape sizes, not final art

## 6. Open Questions for When the Pass Begins

- Do towers need multiple fixed rotation-angle sprites, or can a single static turret
  sprite be rotated at runtime (simpler pipeline, but may look flatter than the
  reference's fixed-angle rendered look)?
- Should enemies get real walk-cycle animation frames, or stay single-sprite with
  procedural bob/squash motion layered on top?
- How many scatter-prop variants are needed per category to avoid visible repetition
  across a full battlefield?
