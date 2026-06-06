import CoreGraphics
import SpriteKit

@MainActor
final class PlaceholderProjectile: GameEntity {
    let node: SKNode

    private let travelActionKey = "placeholderProjectile.travel"

    init() {
        let root = SKNode()
        root.name = "PlaceholderProjectile"
        root.zPosition = 26

        let glow = SKShapeNode(circleOfRadius: 7)
        glow.fillColor = SKColor(red: 1.0, green: 0.28, blue: 0.88, alpha: 0.28)
        glow.strokeColor = .clear
        root.addChild(glow)

        let core = SKShapeNode(circleOfRadius: 4)
        core.fillColor = SKColor(red: 1.0, green: 0.18, blue: 0.83, alpha: 1.0)
        core.strokeColor = SKColor(white: 1.0, alpha: 0.7)
        core.lineWidth = 1
        core.zPosition = 1
        root.addChild(core)

        node = root
    }

    func reset() {
        node.removeAction(forKey: travelActionKey)
        node.removeFromParent()
        node.isHidden = true
    }

    func startTravel(
        from startPosition: CGPoint,
        to targetPosition: CGPoint,
        duration: TimeInterval,
        completion: @escaping @MainActor () -> Void
    ) {
        node.removeAction(forKey: travelActionKey)
        node.position = startPosition
        node.isHidden = false

        let travel = SKAction.move(to: targetPosition, duration: duration)
        travel.timingMode = .easeIn

        node.run(
            SKAction.sequence([
                travel,
                SKAction.run(completion)
            ]),
            withKey: travelActionKey
        )
    }
}
