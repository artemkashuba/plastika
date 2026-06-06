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

        let completion: @MainActor (Bool) -> Void = { [weak self, weak projectile] didImpact in
            guard let self, let projectile else {
                return
            }

            self.recycle(projectile)

            if didImpact {
                onImpact()
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
