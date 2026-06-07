import CoreGraphics
import SpriteKit

@MainActor
final class PlaceholderEnemy: GameEntity {
    let node: SKNode

    let killReward = 10
    private let maxHitPoints = 5
    private(set) var hitPoints = 5
    private(set) var lifeID = 0
    /// Current velocity in points per second, updated at each path segment. Zero before first move.
    private(set) var velocity: CGPoint = .zero

    var isAlive: Bool {
        hitPoints > 0 && node.parent != nil
    }

    private let movementActionKey = "placeholderEnemy.pathMovement"
    private let healthBarWidth: CGFloat = 36
    private let healthBarNode: SKNode
    private let healthBarForeground: SKShapeNode
    /// Rotates to face the direction of travel. Shadow and health bar stay at root level.
    private let bodyNode: SKNode

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
        velocity = .zero
        node.removeAction(forKey: movementActionKey)
        healthBarNode.isHidden = true
        healthBarForeground.xScale = 1.0
        healthBarForeground.position = CGPoint(x: 0, y: 0)
        healthBarForeground.fillColor = SKColor(red: 0.20, green: 0.85, blue: 0.30, alpha: 1.0)
    }

    func takeDamage(_ damage: Int) -> Bool {
        guard hitPoints > 0 else {
            return false
        }

        hitPoints = max(0, hitPoints - damage)
        updateHealthBar()
        return hitPoints == 0
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

    private func updateHealthBar() {
        healthBarNode.isHidden = false

        let fraction = CGFloat(max(0, hitPoints)) / CGFloat(maxHitPoints)
        healthBarForeground.xScale = max(0, fraction)
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
