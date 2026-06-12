import CoreGraphics
import SpriteKit

enum TowerProjectileBehavior {
    case direct
    case homing
    /// Lobbed artillery shell — arcs from the tower onto a predicted point on the road and
    /// explodes there, dealing splash damage to every enemy within `TowerType.splashRadius`
    /// of the impact (rather than a single locked target). Used by the Mortar (`.blue`).
    case mortar
}

/// Visual treatment for a tower's projectile in flight. `.orb` is the shared glow-behind-
/// bright-core ball every type defaults to; `.rocket` swaps in an elongated body that
/// rotates to face its travel direction, glows with a tail-mounted exhaust, and leaves a
/// drifting smoke trail behind it — for warheads that should read as guided munitions
/// rather than re-tinted copies of the same energy ball.
enum ProjectileVisualStyle {
    case orb
    case rocket
    /// Mortar shell — a dark finned bomb that lobs in an arc with a growing ground shadow
    /// beneath it, then drops onto the road. Paired with `TowerProjectileBehavior.mortar`.
    case shell
}

/// Distinguishes towers that fire discrete traveling projectiles (the "shot → travel →
/// impact → cooldown" cycle every prototype tower has used so far) from towers that
/// maintain a persistent damage-over-time beam on a single locked target instead.
enum TowerAttackStyle {
    case projectile
    case beam
}

enum TowerType: CaseIterable {
    case red
    case green
    case blue
    case pink

    var displayName: String {
        switch self {
        case .red:   "Autocannon"
        case .green: "Missile Pod"
        case .blue:  "Mortar"
        case .pink:  "Laser Lance"
        }
    }

    var towerDescription: String {
        switch self {
        case .red:   "Twin barrels, relentless rate of fire. Shreds light enemies."
        case .green: "Homing warheads chase targets. Reliable balanced damage."
        case .blue:  "Lobs explosive shells onto the road. Splash damage clears bunched groups."
        case .pink:  "Locks onto one foe and burns it down with a relentless beam."
        }
    }

    /// Attack range in scene points. 175 is the roster baseline; the Missile Pod reaches
    /// 75% further (306) — its homing rockets already chase targets anywhere, so a long
    /// acquisition reach is its natural identity as the roster's long-range artillery
    /// support, balanced by slow rockets and a slower reload.
    var range: CGFloat {
        switch self {
        case .green: 306
        default:     175
        }
    }

    /// How this tower fights — discrete projectile volleys, or a persistent locked-on beam.
    /// Drives which branch of `TowerManager.updateCombat` (and which visual treatment) applies.
    var attackStyle: TowerAttackStyle {
        switch self {
        case .red, .green, .blue: .projectile
        case .pink:               .beam
        }
    }

    /// Damage per second at sustained fire rate. Projectile towers derive this from
    /// `damage`/`attackCooldown`; beam towers report their continuous `laserDamagePerSecond`
    /// directly, since they have no discrete per-shot damage or reload cycle.
    var dps: Double {
        switch attackStyle {
        case .projectile: Double(damage) / attackCooldown
        case .beam:       laserDamagePerSecond
        }
    }

    /// Continuous beam damage-per-second, applied fractionally every frame (`dps * deltaTime`)
    /// while a beam-style tower has a locked target in range. Only meaningful for `.pink` —
    /// tuned to be the strongest single-target DPS in the roster, justifying its higher cost.
    var laserDamagePerSecond: Double {
        switch self {
        case .pink: 4.5
        default:    0
        }
    }

    /// How far the barrel kicks back (in points) when firing. Heavier guns recoil harder.
    /// Beam towers never recoil — they have no discrete "shot" — so `.pink` reports 0.
    var recoilDistance: CGFloat {
        switch self {
        case .red:   2.5
        case .green: 4.5
        case .blue:  7.5
        case .pink:  0
        }
    }

    /// Relative size of the muzzle flash burst — scales with the gun's bulk.
    /// Unused by beam towers (no muzzle flash without a discrete shot); `.pink` reports 0.
    var muzzleFlashScale: CGFloat {
        switch self {
        case .red:   0.85
        case .green: 1.05
        case .blue:  1.40
        case .pink:  0
        }
    }

    var baseColor: SKColor {
        switch self {
        case .red:
            SKColor(red: 0.78, green: 0.20, blue: 0.18, alpha: 1.0)
        case .green:
            SKColor(red: 0.20, green: 0.58, blue: 0.28, alpha: 1.0)
        case .blue:
            SKColor(red: 0.16, green: 0.39, blue: 0.73, alpha: 1.0)
        case .pink:
            SKColor(red: 0.74, green: 0.18, blue: 0.52, alpha: 1.0)
        }
    }

    var turretColor: SKColor {
        switch self {
        case .red:
            SKColor(red: 0.96, green: 0.34, blue: 0.28, alpha: 1.0)
        case .green:
            SKColor(red: 0.34, green: 0.78, blue: 0.38, alpha: 1.0)
        case .blue:
            SKColor(red: 0.19, green: 0.64, blue: 0.84, alpha: 1.0)
        case .pink:
            SKColor(red: 0.97, green: 0.42, blue: 0.78, alpha: 1.0)
        }
    }

    var barrelColor: SKColor {
        switch self {
        case .red:
            SKColor(red: 0.50, green: 0.08, blue: 0.07, alpha: 1.0)
        case .green:
            SKColor(red: 0.08, green: 0.35, blue: 0.15, alpha: 1.0)
        case .blue:
            SKColor(red: 0.12, green: 0.27, blue: 0.54, alpha: 1.0)
        case .pink:
            SKColor(red: 0.46, green: 0.10, blue: 0.34, alpha: 1.0)
        }
    }

    var menuColor: SKColor {
        turretColor
    }

    /// One-time placement cost in coins. Pink costs more (75 vs. 50) — its continuous,
    /// always-on-target beam makes it the strongest single-target DPS tower in the roster.
    var cost: Int {
        switch self {
        case .red, .green, .blue: 50
        case .pink:               75
        }
    }

    /// Maximum number of times any tower can be upgraded — 2 tiers on top of its base
    /// stats, for 3 total "stages" (base, +1, +2). Kept uniform across the whole roster
    /// for this first pass: AGENTS.md favors the simplest workable curve over per-type
    /// tuning until actual playtesting surfaces a balance problem worth solving.
    static let maxUpgradeLevel = 2

    /// Coin cost to upgrade from `currentLevel` to `currentLevel + 1`, or `nil` once
    /// `currentLevel` is already at `maxUpgradeLevel`. Ramps per tier — the first upgrade
    /// costs roughly 60% of the tower's placement price, the second costs as much as the
    /// tower itself — so fully committing to one tower is a deliberate, escalating
    /// investment rather than an afterthought once coins start piling up.
    func upgradeCost(fromLevel currentLevel: Int) -> Int? {
        switch currentLevel {
        case 0:  Int((Double(cost) * 0.6).rounded())
        case 1:  cost
        default: nil
        }
    }

    /// Damage/DPS multiplier applied at the given upgrade level. Each tier adds a flat
    /// 50% of the tower's *base* output (additive, not compounding), so the jump from
    /// tier 0 → 1 and tier 1 → 2 are equally sized — easy to read, easy to communicate
    /// in UI ("+50% per tier"), and impossible to get surprised by via runaway scaling.
    /// Per the confirmed design, upgrades scale damage/DPS only — `range`, `attackCooldown`,
    /// and every other per-type stat stay fixed identity, untouched by upgrade level.
    func damageMultiplier(atUpgradeLevel level: Int) -> Double {
        1.0 + Double(level) * 0.5
    }

    /// Total coins sunk into this tower to reach the given upgrade level — its placement
    /// cost plus every upgrade purchased along the way (tier 0→1, then 1→2, ...). The
    /// basis for `sellRefund`, so selling an upgraded tower returns a fair share of the
    /// *whole* investment rather than just its original sticker price.
    func totalInvestedCost(atUpgradeLevel level: Int) -> Int {
        var total = cost
        for currentLevel in 0..<level {
            total += upgradeCost(fromLevel: currentLevel) ?? 0
        }
        return total
    }

    /// Coin refund for selling this tower at the given upgrade level — half of everything
    /// ever spent on it (placement *and* upgrades). Mirrors the original "half of cost"
    /// refund philosophy, just extended to cover upgrade spend too, so investing in
    /// upgrades never becomes a trap if the player changes their mind later.
    func sellRefund(atUpgradeLevel level: Int) -> Int {
        totalInvestedCost(atUpgradeLevel: level) / 2
    }

    var shootSound: String {
        switch self {
        case .red:   "tower_shoot_red.wav"
        case .green: "tower_shoot_green.wav"
        case .blue:  "tower_shoot_blue.wav"
        case .pink:  "tower_shoot_blue.wav" // unused — beam towers have no discrete shot sound
        }
    }

    /// Filename of this beam tower's one-shot "ignition" cue — fired exactly once at the
    /// instant its beam locks onto a target ("the laser starts heating"), then left alone
    /// for as long as that lock holds (see `TowerManager.triggerLaserIgnition`). Unlike
    /// every other sound in the roster (all procedurally synthesized), this clip is the
    /// first second of a real recorded laser-gun sample, trimmed and converted to the
    /// project's standard 22050Hz mono 16-bit format — chosen because a punchy, textured
    /// "power-up" transient reads more convincingly from a real source than a synthesized
    /// one. `nil` for projectile towers — they have no beam to ignite.
    var laserStartSound: String? {
        switch self {
        case .pink: "tower_beam_pink_start.wav"
        default:    nil
        }
    }

    /// Per-shot damage for projectile towers. Beam towers deal continuous, fractional damage
    /// via `laserDamagePerSecond` instead, so `.pink` reports 0 (never read in combat).
    /// Green's 3 damage pairs with its 0.75s cooldown to land DPS at exactly 4.0 — a +30%
    /// output bump over its old 2 dmg / 0.65s (≈3.08 DPS), delivered as a heavier warhead
    /// (per-shot damage can't be fractional, so the cooldown absorbs the remainder).
    var damage: Int {
        switch self {
        case .red:   1
        case .green: 3
        case .blue:  5
        case .pink:  0
        }
    }

    /// Time between shots for projectile towers. Beam towers have no fire-then-cooldown
    /// cycle — the beam stays on continuously while locked — so `.pink` reports 0.
    /// Blue's 1.85s (with 5 damage, ≈2.7 DPS) keeps the Mortar's output close to its old
    /// 4 dmg / 1.40s while making each volley — and the reload ring that sweeps it —
    /// visibly heavier and more deliberate.
    var attackCooldown: TimeInterval {
        switch self {
        case .red:   0.28
        case .green: 0.75
        case .blue:  1.85
        case .pink:  0
        }
    }

    /// Maximum turret/tube rotation speed in radians per second — how fast the gun can
    /// traverse toward its aim point. Purely cosmetic (firing never waits for alignment),
    /// but it gives each gun a distinct weight: the Autocannon whips around almost
    /// instantly, the Mortar's heavy tube takes nearly two seconds to come about 180°.
    var traverseSpeed: CGFloat {
        switch self {
        case .red:   10.0
        case .green: 6.0
        case .blue:  1.8
        case .pink:  12.0
        }
    }

    /// Core projectile radius. Glow is drawn at 1.8× this value.
    /// Beam towers never spawn projectiles; `.pink` reports 0 (never read in combat).
    var projectileRadius: CGFloat {
        switch self {
        case .red:   2.5
        case .green: 3.5
        case .blue:  5.5
        case .pink:  0
        }
    }

    /// Beam towers never spawn projectiles; `.pink` reports 0 (never read in combat).
    /// Green's rockets cruise slowly (168, −30% from their old 240) — they're guaranteed
    /// to hit anyway (homing), and the long, lazy flight shows off the smoke trail across
    /// its oversized range.
    var projectileSpeed: CGFloat {
        switch self {
        case .red:
            320
        case .green:
            168
        case .blue:
            170
        case .pink:
            0
        }
    }

    /// Signature effect color — tints muzzle flashes and projectiles for projectile towers,
    /// and doubles as the laser beam's color for `.pink` (a glowing neon-red beam — a
    /// deliberate departure from its pink/magenta chassis, chosen so the laser itself reads
    /// as a hot, electric "laser red" and stays clearly distinct from the warmer brick-reds
    /// and oranges used elsewhere in the roster and on the enemy chassis).
    var projectileColor: SKColor {
        switch self {
        case .red:
            SKColor(red: 1.0, green: 0.38, blue: 0.10, alpha: 1.0)
        case .green:
            SKColor(red: 0.28, green: 1.0, blue: 0.18, alpha: 1.0)
        case .blue:
            SKColor(red: 0.10, green: 0.82, blue: 1.0, alpha: 1.0)
        case .pink:
            SKColor(red: 1.0, green: 0.10, blue: 0.22, alpha: 1.0)
        }
    }

    /// Blast radius (scene points) for area-of-effect towers — every enemy within this
    /// distance of a mortar shell's landing point takes full damage. 0 for single-target
    /// towers, which damage only their one locked target.
    var splashRadius: CGFloat {
        switch self {
        case .blue: 55
        default:    0
        }
    }

    /// Flight time of a lobbed mortar shell, launch → impact. Doubles as the lead time used
    /// to predict where the target enemy will be standing on the road when the shell lands,
    /// so the explosion comes down on the advancing wave rather than where it used to be.
    /// 0 for non-mortar towers.
    var mortarFlightDuration: TimeInterval {
        switch self {
        case .blue: 0.7
        default:    0
        }
    }

    /// Legacy direct-fire intercept aiming. No tower uses it now — the Mortar (`.blue`),
    /// which once did, lobs shells via `TowerProjectileBehavior.mortar` and does its own
    /// landing-point prediction. Kept as a hook for any future predictive direct-fire tower.
    var usesPredictiveAiming: Bool { false }

    /// Beam towers never spawn projectiles; `.pink` reports `.direct` as an unused
    /// placeholder (never read — `TowerManager.updateCombat` routes beam-style towers to a
    /// dedicated continuous-damage branch instead of `ProjectileManager`).
    var projectileBehavior: TowerProjectileBehavior {
        switch self {
        case .red:
            .direct
        case .green:
            .homing
        case .blue:
            .mortar
        case .pink:
            .direct
        }
    }

    /// Visual treatment for this tower's projectile in flight. Only `.green` gets the
    /// `.rocket` treatment — its homing warheads earn a distinct tapered-body-plus-
    /// exhaust-and-smoke-trail look that reads as "guided missile," matching its
    /// "Missile Pod" identity instead of just being a re-tinted copy of the other
    /// towers' glow-ball projectiles. Beam towers never spawn projectiles; `.pink`
    /// reports `.orb` as an unused placeholder.
    var projectileVisualStyle: ProjectileVisualStyle {
        switch self {
        case .green: .rocket
        case .blue:  .shell
        default:     .orb
        }
    }
}
