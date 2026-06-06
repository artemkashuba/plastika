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

    func startDirectTravel(
        from startPosition: CGPoint,
        to targetPosition: CGPoint,
        duration: TimeInterval,
        completion: @escaping @MainActor (Bool) -> Void
    ) {
        node.removeAction(forKey: travelActionKey)
        node.position = startPosition
        node.isHidden = false

        let travel = SKAction.move(to: targetPosition, duration: duration)
        travel.timingMode = .easeIn

        node.run(
            SKAction.sequence([
                travel,
                SKAction.run {
                    completion(true)
                }
            ]),
            withKey: travelActionKey
        )
    }

    func startHomingTravel(
        from startPosition: CGPoint,
        speed: CGFloat,
        targetPositionProvider: @escaping @MainActor () -> CGPoint?,
        completion: @escaping @MainActor (Bool) -> Void
    ) {
        node.removeAction(forKey: travelActionKey)
        node.position = startPosition
        node.isHidden = false

        let impactRadius: CGFloat = 7
        var previousElapsedTime: CGFloat = 0
        var didComplete = false

        let home = SKAction.customAction(withDuration: 2.6) { node, elapsedTime in
            guard didComplete == false else {
                return
            }

            guard let targetPosition = targetPositionProvider() else {
                didComplete = true
                node.removeAction(forKey: self.travelActionKey)
                completion(false)
                return
            }

            let deltaTime = max(0, elapsedTime - previousElapsedTime)
            previousElapsedTime = elapsedTime

            let dx = targetPosition.x - node.position.x
            let dy = targetPosition.y - node.position.y
            let distance = sqrt(dx * dx + dy * dy)

            guard distance > impactRadius else {
                didComplete = true
                node.position = targetPosition
                node.removeAction(forKey: self.travelActionKey)
                completion(true)
                return
            }

            let stepDistance = max(1, speed * deltaTime)

            if stepDistance >= distance {
                didComplete = true
                node.position = targetPosition
                node.removeAction(forKey: self.travelActionKey)
                completion(true)
                return
            }

            node.position = CGPoint(
                x: node.position.x + (dx / distance) * stepDistance,
                y: node.position.y + (dy / distance) * stepDistance
            )
        }

        node.run(
            SKAction.sequence([
                home,
                SKAction.run {
                    if didComplete == false {
                        didComplete = true
                        completion(false)
                    }
                }
            ]),
            withKey: travelActionKey
        )
    }
}
