import CoreGraphics
import SpriteKit

enum TowerProjectileBehavior {
    case direct
    case homing
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
        case .blue:  "Heavy Cannon"
        case .pink:  "Laser Lance"
        }
    }

    var towerDescription: String {
        switch self {
        case .red:   "Twin barrels, relentless rate of fire. Shreds light enemies."
        case .green: "Homing warheads chase targets. Reliable balanced damage."
        case .blue:  "Slow, devastating rounds with predictive aim. Built for heavies."
        case .pink:  "Locks onto one foe and burns it down with a relentless beam."
        }
    }

    /// Attack range in scene points. All types share 175 for now.
    var range: CGFloat { 175 }

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

    var sellRefund: Int {
        cost / 2
    }

    var shootSound: String {
        switch self {
        case .red:   "tower_shoot_red.wav"
        case .green: "tower_shoot_green.wav"
        case .blue:  "tower_shoot_blue.wav"
        case .pink:  "tower_shoot_blue.wav" // unused — beam towers have no discrete shot sound
        }
    }

    /// Per-shot damage for projectile towers. Beam towers deal continuous, fractional damage
    /// via `laserDamagePerSecond` instead, so `.pink` reports 0 (never read in combat).
    var damage: Int {
        switch self {
        case .red:   1
        case .green: 2
        case .blue:  4
        case .pink:  0
        }
    }

    /// Time between shots for projectile towers. Beam towers have no fire-then-cooldown
    /// cycle — the beam stays on continuously while locked — so `.pink` reports 0.
    var attackCooldown: TimeInterval {
        switch self {
        case .red:   0.28
        case .green: 0.65
        case .blue:  1.40
        case .pink:  0
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
    var projectileSpeed: CGFloat {
        switch self {
        case .red:
            320
        case .green:
            240
        case .blue:
            170
        case .pink:
            0
        }
    }

    /// Signature effect color — tints muzzle flashes and projectiles for projectile towers,
    /// and doubles as the laser beam's color for `.pink` (a hot magenta beam to match its
    /// pink identity while staying clearly distinct from the other towers' palettes).
    var projectileColor: SKColor {
        switch self {
        case .red:
            SKColor(red: 1.0, green: 0.38, blue: 0.10, alpha: 1.0)
        case .green:
            SKColor(red: 0.28, green: 1.0, blue: 0.18, alpha: 1.0)
        case .blue:
            SKColor(red: 0.10, green: 0.82, blue: 1.0, alpha: 1.0)
        case .pink:
            SKColor(red: 1.0, green: 0.20, blue: 0.70, alpha: 1.0)
        }
    }

    var usesPredictiveAiming: Bool {
        switch self {
        case .blue: true
        default: false
        }
    }

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
            .direct
        case .pink:
            .direct
        }
    }
}
