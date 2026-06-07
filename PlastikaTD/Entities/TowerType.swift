import CoreGraphics
import SpriteKit

enum TowerProjectileBehavior {
    case direct
    case homing
}

enum TowerType: CaseIterable {
    case red
    case green
    case blue

    var displayName: String {
        switch self {
        case .red:   "Autocannon"
        case .green: "Missile Pod"
        case .blue:  "Heavy Cannon"
        }
    }

    var towerDescription: String {
        switch self {
        case .red:   "Twin barrels, relentless rate of fire. Shreds light enemies."
        case .green: "Homing warheads chase targets. Reliable balanced damage."
        case .blue:  "Slow, devastating rounds with predictive aim. Built for heavies."
        }
    }

    /// Attack range in scene points. All types share 175 for now.
    var range: CGFloat { 175 }

    /// Damage per second at sustained fire rate.
    var dps: Double { Double(damage) / attackCooldown }

    /// How far the barrel kicks back (in points) when firing. Heavier guns recoil harder.
    var recoilDistance: CGFloat {
        switch self {
        case .red:   2.5
        case .green: 4.5
        case .blue:  7.5
        }
    }

    /// Relative size of the muzzle flash burst — scales with the gun's bulk.
    var muzzleFlashScale: CGFloat {
        switch self {
        case .red:   0.85
        case .green: 1.05
        case .blue:  1.40
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
        }
    }

    var menuColor: SKColor {
        turretColor
    }

    var cost: Int {
        50
    }

    var sellRefund: Int {
        cost / 2
    }

    var shootSound: String {
        switch self {
        case .red:   "tower_shoot_red.wav"
        case .green: "tower_shoot_green.wav"
        case .blue:  "tower_shoot_blue.wav"
        }
    }

    var damage: Int {
        switch self {
        case .red:   1
        case .green: 2
        case .blue:  4
        }
    }

    var attackCooldown: TimeInterval {
        switch self {
        case .red:   0.28
        case .green: 0.65
        case .blue:  1.40
        }
    }

    /// Core projectile radius. Glow is drawn at 1.8× this value.
    var projectileRadius: CGFloat {
        switch self {
        case .red:   2.5
        case .green: 3.5
        case .blue:  5.5
        }
    }

    var projectileSpeed: CGFloat {
        switch self {
        case .red:
            320
        case .green:
            240
        case .blue:
            170
        }
    }

    var projectileColor: SKColor {
        switch self {
        case .red:
            SKColor(red: 1.0, green: 0.38, blue: 0.10, alpha: 1.0)
        case .green:
            SKColor(red: 0.28, green: 1.0, blue: 0.18, alpha: 1.0)
        case .blue:
            SKColor(red: 0.10, green: 0.82, blue: 1.0, alpha: 1.0)
        }
    }

    var usesPredictiveAiming: Bool {
        switch self {
        case .blue: true
        default: false
        }
    }

    var projectileBehavior: TowerProjectileBehavior {
        switch self {
        case .red:
            .direct
        case .green:
            .homing
        case .blue:
            .direct
        }
    }
}
