import CoreGraphics
import SpriteKit

/// Static per-type stats and chassis "paint job" for the enemy roster — mirrors
/// `TowerType`'s shape (computed properties driving every per-type difference) so the
/// two rosters stay idiomatically consistent.
///
/// All three share `PlaceholderEnemy`'s existing toy-tank silhouette; what differs is
/// stats (HP, speed, kill reward — the "meaningfully different" axis the design doc
/// calls for) plus a recolor + uniform rescale of that shared chassis, the same
/// "shared base, distinct livery" technique two of the four prototype towers already
/// use. `.soldier` is the baseline (8 HP — bumped +50% from its original 5 in a later
/// balance pass — 1.0× speed, 10-coin reward, the original maroon livery at 1.0× scale)
/// — `.scout` and `.tank` trade HP for speed in
/// opposite directions, so every type remains killable (if inefficiently) by any tower:
/// no hard counters, no flying/path-ignoring behavior, per the documented soft-counter
/// guidance.
enum EnemyType: CaseIterable {
    case scout
    case soldier
    case tank

    var displayName: String {
        switch self {
        case .scout:   "Scout"
        case .soldier: "Soldier"
        case .tank:    "Tank"
        }
    }

    var enemyDescription: String {
        switch self {
        case .scout:   "Light and quick. Low HP — punishes towers that can't land a hit before it's gone."
        case .soldier: "The balanced baseline. No particular weakness or strength."
        case .tank:    "Slow and heavily built. High HP rewards sustained, heavy-hitting fire."
        }
    }

    /// Maximum hit points. Bumped +50% across the board from the original launch values
    /// (Scout 3→5, Soldier 5→8, Tank 12→18 — each rounded to the nearest whole point) to
    /// make every fight last longer and matter more, while preserving the relative HP
    /// ratios between types (and therefore the soft-counter balance already checked
    /// against tower DPS — see DECISIONS.md). `.soldier` (8) remains the baseline every
    /// other type is defined relative to; `.scout` trades HP for speed, `.tank` inverts
    /// that trade — meaningfully different stats, not palette swaps, per the documented
    /// design guidance.
    var maxHitPoints: Int {
        switch self {
        case .scout:   5
        case .soldier: 8
        case .tank:    18
        }
    }

    /// Multiplies `GamePath.movementSpeed` (a fixed, path-level constant — see
    /// `PlaceholderEnemy.startMoving`) to produce this type's effective travel speed.
    /// `.soldier` reports the neutral 1.0×, exactly reproducing the original fixed-speed
    /// behavior; `.scout` is meaningfully faster, `.tank` meaningfully slower.
    var speedMultiplier: CGFloat {
        switch self {
        case .scout:   1.35
        case .soldier: 1.0
        case .tank:    0.65
        }
    }

    /// Coins awarded on kill — scaled with how much effort each type costs to bring
    /// down: less for the scout's low HP and fast pace-through, more for the tank's high
    /// HP and slower kills-per-minute throughput. `.soldier` keeps the original value (10).
    var killReward: Int {
        switch self {
        case .scout:   6
        case .soldier: 10
        case .tank:    18
        }
    }

    /// Chassis fill color — recolors the same toy-tank hull every type shares, the same
    /// "shared silhouette, distinct livery" technique the Red/Blue towers already use.
    /// `.soldier` keeps the original maroon-red identity; `.scout` reads bright and
    /// nimble (toy orange), `.tank` reads dull and armored (gunmetal green-gray).
    var hullColor: SKColor {
        switch self {
        case .scout:
            SKColor(red: 0.93, green: 0.58, blue: 0.16, alpha: 1.0)
        case .soldier:
            SKColor(red: 0.68, green: 0.20, blue: 0.16, alpha: 1.0)
        case .tank:
            SKColor(red: 0.32, green: 0.36, blue: 0.30, alpha: 1.0)
        }
    }

    var hullStrokeColor: SKColor {
        switch self {
        case .scout:
            SKColor(red: 1.0, green: 0.82, blue: 0.42, alpha: 1.0)
        case .soldier:
            SKColor(red: 0.88, green: 0.52, blue: 0.28, alpha: 1.0)
        case .tank:
            SKColor(red: 0.58, green: 0.64, blue: 0.54, alpha: 1.0)
        }
    }

    var turretColor: SKColor {
        switch self {
        case .scout:
            SKColor(red: 0.70, green: 0.42, blue: 0.10, alpha: 1.0)
        case .soldier:
            SKColor(red: 0.50, green: 0.14, blue: 0.12, alpha: 1.0)
        case .tank:
            SKColor(red: 0.22, green: 0.26, blue: 0.20, alpha: 1.0)
        }
    }

    var turretStrokeColor: SKColor {
        switch self {
        case .scout:
            SKColor(red: 0.98, green: 0.70, blue: 0.32, alpha: 0.80)
        case .soldier:
            SKColor(red: 0.85, green: 0.42, blue: 0.24, alpha: 0.80)
        case .tank:
            SKColor(red: 0.50, green: 0.56, blue: 0.46, alpha: 0.80)
        }
    }

    /// Uniform scale applied to the chassis body. `.soldier` sits at the original 1.0×
    /// baseline; `.scout` reads small and nimble, `.tank` reads big and imposing —
    /// reinforcing each type's stat identity at a glance, toy-shelf style.
    var chassisScale: CGFloat {
        switch self {
        case .scout:   0.82
        case .soldier: 1.0
        case .tank:    1.28
        }
    }
}
