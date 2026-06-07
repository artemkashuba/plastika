import CoreGraphics
import SpriteKit

@MainActor
final class PlaceholderEnemy: GameEntity {
    let node: SKNode

    let killReward = 10
    private let maxHitPoints = 5
    private(set) var hitPoints = 5
    /// Canonical health value — `hitPoints` is a ceiling-rounded mirror kept in sync for
    /// Int-based consumers (kill detection, `isAlive`). Tracking health as a `Double` lets
    /// continuous sources (e.g. a laser beam) drain it in tiny fractional steps every frame,
    /// and lets `updateHealthBar` render that exact value so the bar empties smoothly rather
    /// than snapping between whole-HP increments.
    private var fractionalHealth: Double = 5.0
    private(set) var lifeID = 0
    /// Current velocity in points per second, updated at each path segment. Zero before first move.
    private(set) var velocity: CGPoint = .zero

    var isAlive: Bool {
        hitPoints > 0 && node.parent != nil
    }

    private let movementActionKey = "placeholderEnemy.pathMovement"
    private let beamBurnActionKey = "placeholderEnemy.beamBurn"
    private let healthBarWidth: CGFloat = 36
    private let healthBarNode: SKNode
    private let healthBarForeground: SKShapeNode
    /// Rotates to face the direction of travel. Shadow and health bar stay at root level.
    private let bodyNode: SKNode
    /// Small flickering "plasma burn" cluster shown at the point where a laser beam makes
    /// contact (mirrors the tower's muzzle-flash language: tinted glow + white-hot core).
    /// Lives at root level — NOT a child of `bodyNode` — so it sits at a fixed spot on the
    /// chassis regardless of which way the enemy is currently facing, coinciding with the
    /// beam's actual endpoint (`node.position`, the exact point `updateBeamCombat` aims at).
    /// Created lazily on first use; nil for enemies a beam has never touched.
    private var beamBurnNode: SKNode?

    init() {
        let root = SKNode()
        root.name = "PlaceholderEnemy"
        root.zPosition = 20

        // Shadow — wide flat ellipse offset below the unit
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 46, height: 18))
        shadow.fillColor = SKColor(white: 0.0, alpha: 0.30)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 3, y: -8)
        shadow.zPosition = -1
        root.addChild(shadow)

        // Body node — rotates to face direction of travel (+y = forward)
        let bodyNode = SKNode()
        bodyNode.zPosition = 0
        root.addChild(bodyNode)

        // Left track
        let trackL = SKShapeNode(rectOf: CGSize(width: 9, height: 28), cornerRadius: 3)
        trackL.fillColor = SKColor(red: 0.14, green: 0.12, blue: 0.11, alpha: 1.0)
        trackL.strokeColor = SKColor(white: 0.35, alpha: 0.50)
        trackL.lineWidth = 1
        trackL.position = CGPoint(x: -16, y: 0)
        bodyNode.addChild(trackL)

        // Right track
        let trackR = SKShapeNode(rectOf: CGSize(width: 9, height: 28), cornerRadius: 3)
        trackR.fillColor = SKColor(red: 0.14, green: 0.12, blue: 0.11, alpha: 1.0)
        trackR.strokeColor = SKColor(white: 0.35, alpha: 0.50)
        trackR.lineWidth = 1
        trackR.position = CGPoint(x: 16, y: 0)
        bodyNode.addChild(trackR)

        // Hull
        let hull = SKShapeNode(rectOf: CGSize(width: 24, height: 22), cornerRadius: 5)
        hull.fillColor = SKColor(red: 0.68, green: 0.20, blue: 0.16, alpha: 1.0)
        hull.strokeColor = SKColor(red: 0.88, green: 0.52, blue: 0.28, alpha: 1.0)
        hull.lineWidth = 2
        bodyNode.addChild(hull)

        // Turret
        let turret = SKShapeNode(circleOfRadius: 7)
        turret.fillColor = SKColor(red: 0.50, green: 0.14, blue: 0.12, alpha: 1.0)
        turret.strokeColor = SKColor(red: 0.85, green: 0.42, blue: 0.24, alpha: 0.80)
        turret.lineWidth = 1.5
        turret.position = CGPoint(x: 0, y: 1)
        turret.zPosition = 1
        bodyNode.addChild(turret)

        // Barrel — points forward (+y), shows facing direction
        let barrel = SKShapeNode(rectOf: CGSize(width: 4, height: 11), cornerRadius: 2)
        barrel.fillColor = SKColor(red: 0.18, green: 0.14, blue: 0.13, alpha: 1.0)
        barrel.strokeColor = .clear
        barrel.position = CGPoint(x: 0, y: 12)
        barrel.zPosition = 2
        bodyNode.addChild(barrel)

        // Turret specular highlight
        let turretHighlight = SKShapeNode(circleOfRadius: 3)
        turretHighlight.fillColor = SKColor(white: 1.0, alpha: 0.38)
        turretHighlight.strokeColor = .clear
        turretHighlight.position = CGPoint(x: -3, y: 3)
        turretHighlight.zPosition = 3
        bodyNode.addChild(turretHighlight)

        // Health bar — at root level so it stays horizontal regardless of body rotation
        let barContainer = SKNode()
        barContainer.position = CGPoint(x: 0, y: 24)
        barContainer.zPosition = 4
        barContainer.isHidden = true
        root.addChild(barContainer)

        let background = SKShapeNode(rectOf: CGSize(width: 36, height: 4), cornerRadius: 2)
        background.fillColor = SKColor(white: 0.0, alpha: 0.55)
        background.strokeColor = .clear
        barContainer.addChild(background)

        let foreground = SKShapeNode(rectOf: CGSize(width: 36, height: 4), cornerRadius: 2)
        foreground.fillColor = SKColor(red: 0.20, green: 0.85, blue: 0.30, alpha: 1.0)
        foreground.strokeColor = .clear
        foreground.zPosition = 1
        barContainer.addChild(foreground)

        self.node = root
        self.bodyNode = bodyNode
        self.healthBarNode = barContainer
        self.healthBarForeground = foreground
    }

    func reset() {
        hitPoints = maxHitPoints
        fractionalHealth = Double(maxHitPoints)
        velocity = .zero
        node.removeAction(forKey: movementActionKey)
        hideBeamBurn()
        healthBarNode.isHidden = true
        healthBarForeground.xScale = 1.0
        healthBarForeground.position = CGPoint(x: 0, y: 0)
        healthBarForeground.fillColor = SKColor(red: 0.20, green: 0.85, blue: 0.30, alpha: 1.0)
    }

    /// Discrete, whole-point damage from a single shot (Red/Green/Blue projectile impacts).
    func takeDamage(_ damage: Int) -> Bool {
        guard hitPoints > 0 else {
            return false
        }

        applyHealthLoss(Double(damage))
        return hitPoints == 0
    }

    /// Continuous, fractional damage applied every frame a laser beam stays locked on this
    /// enemy (`amount` is typically `dps * deltaTime`, so it can be a tiny sub-1 value).
    /// Unlike `takeDamage`, this drains `fractionalHealth` — and therefore the health bar —
    /// in genuinely smooth, frame-by-frame steps rather than snapping between whole hits.
    @discardableResult
    func takeContinuousDamage(_ amount: Double) -> Bool {
        guard hitPoints > 0 else {
            return false
        }

        applyHealthLoss(amount)
        return hitPoints == 0
    }

    /// Subtracts `amount` from the canonical fractional health, re-derives the Int
    /// `hitPoints` mirror (ceiling-rounded, so it only reaches 0 exactly when health is
    /// fully drained), and redraws the bar from the precise fractional remainder.
    private func applyHealthLoss(_ amount: Double) {
        fractionalHealth = max(0, fractionalHealth - amount)
        hitPoints = Int(fractionalHealth.rounded(.up))
        updateHealthBar()
    }

    // MARK: - Beam burn (laser impact effect)

    /// Shows — creating lazily on first use — a small flickering "plasma burn" cluster at
    /// the point where a locked-on laser beam makes contact: a `color`-tinted glow around a
    /// white-hot core, the same tinted-glow-plus-bright-core language `PlaceholderTower`
    /// already uses for its muzzle flash and beam, just relocated to the point of impact.
    /// Call once per frame while a beam-style tower's lock holds on this enemy — cheap and
    /// idempotent after the first call (only re-reveals if previously hidden).
    func showBeamBurn(color: SKColor) {
        if let beamBurnNode {
            beamBurnNode.isHidden = false
            return
        }

        let burn = SKNode()
        burn.position = CGPoint(x: 0, y: 2)
        burn.zPosition = 3.5
        node.addChild(burn)

        let glow = SKShapeNode(circleOfRadius: 7)
        glow.fillColor = color.withAlphaComponent(0.40)
        glow.strokeColor = .clear
        burn.addChild(glow)

        let core = SKShapeNode(circleOfRadius: 2.5)
        core.fillColor = SKColor(white: 1.0, alpha: 0.92)
        core.strokeColor = .clear
        core.zPosition = 1
        burn.addChild(core)

        beamBurnNode = burn
        startBeamBurnFlicker(glow: glow, core: core)
    }

    /// Hides the burn effect (if one exists). Call whenever the beam loses its lock on this
    /// enemy — target out of range, tower switched targets, enemy died, etc — and from
    /// `reset()` so a recycled enemy never carries a stale glow into its next life. Safe to
    /// call on any enemy; a no-op if a beam has never touched this one.
    func hideBeamBurn() {
        beamBurnNode?.isHidden = true
    }

    /// Kicks off a fast, irregular flicker on the burn cluster the instant it's first shown —
    /// runs forever, independent of how often `showBeamBurn` is called. Each layer combines
    /// two out-of-phase sine waves at different (integer-multiple) frequencies so the loop is
    /// seamless yet reads as an erratic flame-lick rather than a smooth metronomic pulse —
    /// distinct in cadence from the beam's own slow "neon" breathing on the tower end.
    private func startBeamBurnFlicker(glow: SKShapeNode, core: SKShapeNode) {
        let glowBaseAlpha = glow.alpha
        let glowBaseScale = glow.xScale
        let period: TimeInterval = 0.6

        let glowFlicker = SKAction.customAction(withDuration: period) { node, elapsed in
            guard let shape = node as? SKShapeNode else { return }
            let phase = (elapsed / CGFloat(period)) * (2 * .pi)
            let wobble = sin(phase * 3) * 0.6 + sin(phase * 7 + 1.3) * 0.4
            shape.alpha = glowBaseAlpha + wobble * 0.18
            shape.setScale(glowBaseScale + wobble * 0.14)
        }
        glow.run(.repeatForever(glowFlicker), withKey: beamBurnActionKey)

        let coreBaseAlpha = core.alpha
        let coreBaseScale = core.xScale

        let coreFlicker = SKAction.customAction(withDuration: period) { node, elapsed in
            guard let shape = node as? SKShapeNode else { return }
            let phase = (elapsed / CGFloat(period)) * (2 * .pi)
            let wobble = sin(phase * 5 + 0.6) * 0.5 + sin(phase * 11 + 2.4) * 0.5
            shape.alpha = coreBaseAlpha + wobble * 0.16
            shape.setScale(coreBaseScale + wobble * 0.20)
        }
        core.run(.repeatForever(coreFlicker), withKey: beamBurnActionKey)
    }

    func startMoving(along path: GamePath, completion: @escaping @MainActor () -> Void) {
        reset()
        lifeID += 1

        guard let firstPoint = path.startPoint, path.waypoints.count > 1 else {
            completion()
            return
        }

        node.position = firstPoint
        node.isHidden = false

        var movementActions: [SKAction] = []
        for (start, end) in zip(path.waypoints, path.waypoints.dropFirst()) {
            let dist = max(1, start.distance(to: end))
            let duration = TimeInterval(dist / path.movementSpeed)
            let vx = ((end.x - start.x) / dist) * path.movementSpeed
            let vy = ((end.y - start.y) / dist) * path.movementSpeed
            movementActions.append(SKAction.run { [weak self] in
                self?.velocity = CGPoint(x: vx, y: vy)
                // Rotate body to face the direction of travel (+y = forward in local space)
                self?.bodyNode.zRotation = atan2(vy, vx) - (.pi / 2)
            })
            movementActions.append(SKAction.move(to: end, duration: duration))
        }

        let finish = SKAction.run {
            completion()
        }

        node.run(SKAction.sequence(movementActions + [finish]), withKey: movementActionKey)
    }

    /// Renders directly from `fractionalHealth` (not the Int `hitPoints` mirror) so every
    /// damage source — discrete hits and continuous beam ticks alike — draws the bar at its
    /// exact current health fraction. For Int-only damage this is numerically identical to
    /// the old `hitPoints`-based fraction; for fractional beam damage it's what makes the
    /// drain look genuinely continuous rather than stepped.
    private func updateHealthBar() {
        healthBarNode.isHidden = false

        let fraction = CGFloat(max(0, fractionalHealth) / Double(maxHitPoints))
        healthBarForeground.xScale = fraction
        healthBarForeground.position = CGPoint(x: -(healthBarWidth / 2) * (1 - fraction), y: 0)
        healthBarForeground.fillColor = healthBarColor(for: fraction)
    }

    private func healthBarColor(for fraction: CGFloat) -> SKColor {
        if fraction > 0.6 {
            return SKColor(red: 0.20, green: 0.85, blue: 0.30, alpha: 1.0)
        } else if fraction > 0.3 {
            return SKColor(red: 0.96, green: 0.78, blue: 0.10, alpha: 1.0)
        } else {
            return SKColor(red: 0.92, green: 0.22, blue: 0.18, alpha: 1.0)
        }
    }
}

private extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        let dx = x - point.x
        let dy = y - point.y
        return sqrt(dx * dx + dy * dy)
    }
}
