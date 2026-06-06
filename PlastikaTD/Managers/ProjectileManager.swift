import CoreGraphics
import SpriteKit

@MainActor
final class ProjectileManager {
    private let projectileSpeed: CGFloat = 260
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
        at target: PlaceholderEnemy,
        in scene: SKScene,
        onImpact: @escaping @MainActor (PlaceholderEnemy) -> Void
    ) {
        let projectile = pooledProjectiles.popLast() ?? PlaceholderProjectile()
        let targetPosition = target.node.position
        let duration = TimeInterval(max(0.18, startPosition.distance(to: targetPosition) / projectileSpeed))

        if projectile.node.parent == nil {
            scene.addChild(projectile.node)
        }

        activeProjectiles.append(projectile)

        projectile.startTravel(from: startPosition, to: targetPosition, duration: duration) { [weak self, weak projectile, weak target] in
            guard let self, let projectile else {
                return
            }

            self.recycle(projectile)

            if let target {
                onImpact(target)
            }
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
