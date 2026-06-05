import CoreGraphics
import SpriteKit

@MainActor
final class PlaceholderEnemy: GameEntity {
    let node: SKNode

    private let movementActionKey = "placeholderEnemy.pathMovement"

    init() {
        let body = SKShapeNode(circleOfRadius: 16)
        body.name = "PlaceholderEnemy"
        body.fillColor = SKColor(red: 0.94, green: 0.25, blue: 0.20, alpha: 1.0)
        body.strokeColor = SKColor(red: 1.0, green: 0.86, blue: 0.50, alpha: 1.0)
        body.lineWidth = 3
        body.zPosition = 20
        self.node = body
    }

    func reset() {
        node.removeAction(forKey: movementActionKey)
    }

    func startMoving(along path: GamePath) {
        reset()

        guard let firstPoint = path.startPoint, path.waypoints.count > 1 else {
            return
        }

        node.position = firstPoint

        let movementActions = zip(path.waypoints, path.waypoints.dropFirst()).map { start, end in
            let duration = TimeInterval(start.distance(to: end) / path.movementSpeed)
            return SKAction.move(to: end, duration: duration)
        }

        let resetToStart = SKAction.run { [weak self] in
            self?.node.position = firstPoint
        }

        let loop = SKAction.sequence(movementActions + [
            SKAction.wait(forDuration: 0.35),
            resetToStart
        ])

        node.run(SKAction.repeatForever(loop), withKey: movementActionKey)
    }
}

private extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        let dx = x - point.x
        let dy = y - point.y
        return sqrt(dx * dx + dy * dy)
    }
}
