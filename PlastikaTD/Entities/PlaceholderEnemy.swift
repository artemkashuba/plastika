import CoreGraphics
import SpriteKit

@MainActor
final class PlaceholderEnemy: GameEntity {
    let node: SKNode

    let killReward = 10
    private let maxHitPoints = 5
    private(set) var hitPoints = 5
    private(set) var lifeID = 0

    var isAlive: Bool {
        hitPoints > 0 && node.parent != nil
    }

    private let movementActionKey = "placeholderEnemy.pathMovement"
    private let healthBarWidth: CGFloat = 30
    private let healthBarNode: SKNode
    private let healthBarForeground: SKShapeNode

    init() {
        let body = SKShapeNode(circleOfRadius: 16)
        body.name = "PlaceholderEnemy"
        body.fillColor = SKColor(red: 0.94, green: 0.25, blue: 0.20, alpha: 1.0)
        body.strokeColor = SKColor(red: 1.0, green: 0.86, blue: 0.50, alpha: 1.0)
        body.lineWidth = 3
        body.zPosition = 20

        let barContainer = SKNode()
        barContainer.position = CGPoint(x: 0, y: 26)
        barContainer.zPosition = 1
        barContainer.isHidden = true

        let background = SKShapeNode(rectOf: CGSize(width: 30, height: 4), cornerRadius: 2)
        background.fillColor = SKColor(white: 0.0, alpha: 0.55)
        background.strokeColor = .clear
        barContainer.addChild(background)

        let foreground = SKShapeNode(rectOf: CGSize(width: 30, height: 4), cornerRadius: 2)
        foreground.fillColor = SKColor(red: 0.20, green: 0.85, blue: 0.30, alpha: 1.0)
        foreground.strokeColor = .clear
        foreground.zPosition = 1
        barContainer.addChild(foreground)

        body.addChild(barContainer)

        self.node = body
        self.healthBarNode = barContainer
        self.healthBarForeground = foreground
    }

    func reset() {
        hitPoints = maxHitPoints
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

        let movementActions = zip(path.waypoints, path.waypoints.dropFirst()).map { start, end in
            let duration = TimeInterval(start.distance(to: end) / path.movementSpeed)
            return SKAction.move(to: end, duration: duration)
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
