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
        case .red:
            "Red Tower"
        case .green:
            "Green Tower"
        case .blue:
            "Blue Tower"
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

    var damage: Int {
        switch self {
        case .red:
            1
        case .green:
            1
        case .blue:
            2
        }
    }

    var attackCooldown: TimeInterval {
        switch self {
        case .red:
            0.36
        case .green:
            0.58
        case .blue:
            0.90
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
