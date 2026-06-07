import CoreGraphics
import SpriteKit

@MainActor
final class ProjectileManager {
    private var activeProjectiles: [PlaceholderProjectile] = []
    private var pooledProjectiles: [PlaceholderProjectile] = []

    func resetForNewScene() {
        (activeProjectiles + pooledProjectiles).forEach { projectile in
            projectile.reset()
        }

        activeProjectiles.removeAll(keepingCapacity: true)
        pooledProjectiles.removeAll(keepingCapacity: true)
    }

    func firePlaceholderProjectile(
        from startPosition: CGPoint,
        to targetPosition: CGPoint,
        behavior: TowerProjectileBehavior,
        color: SKColor,
        radius: CGFloat,
        speed: CGFloat,
        targetPositionProvider: @escaping @MainActor () -> CGPoint?,
        in scene: SKScene,
        onImpact: @escaping @MainActor () -> Void
    ) {
        let projectile = pooledProjectiles.popLast() ?? PlaceholderProjectile()

        if projectile.node.parent == nil {
            scene.addChild(projectile.node)
        }

        activeProjectiles.append(projectile)
        projectile.configure(color: color, radius: radius)

        let completion: @MainActor (Bool) -> Void = { [weak self, weak projectile, weak scene] didImpact in
            guard let self, let projectile else {
                return
            }

            let impactPosition = projectile.node.position
            self.recycle(projectile)

            if didImpact {
                onImpact()
                if let scene {
                    self.showImpactFlash(at: impactPosition, color: color, radius: radius, in: scene)
                }
            }
        }

        switch behavior {
        case .direct:
            let duration = TimeInterval(max(0.18, startPosition.distance(to: targetPosition) / speed))
            projectile.startDirectTravel(from: startPosition, to: targetPosition, duration: duration, completion: completion)
        case .homing:
            projectile.startHomingTravel(
                from: startPosition,
                speed: speed,
                targetPositionProvider: targetPositionProvider,
                completion: completion
            )
        }
    }

    private func showImpactFlash(at position: CGPoint, color: SKColor, radius: CGFloat, in scene: SKScene) {
        let flash = SKShapeNode(circleOfRadius: radius * 1.2)
        flash.position = position
        flash.fillColor = color.withAlphaComponent(0.90)
        flash.strokeColor = color.withAlphaComponent(0.50)
        flash.lineWidth = 1.5
        flash.zPosition = 27
        scene.addChild(flash)

        flash.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 2.6, duration: 0.18),
                SKAction.fadeOut(withDuration: 0.18)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    private func recycle(_ projectile: PlaceholderProjectile) {
        projectile.reset()
        activeProjectiles.removeAll { $0 === projectile }
        pooledProjectiles.append(projectile)
    }
}

private extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        let dx = x - point.x
        let dy = y - point.y
        return sqrt(dx * dx + dy * dy)
    }
}
