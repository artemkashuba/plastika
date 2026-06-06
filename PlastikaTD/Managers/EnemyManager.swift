import SpriteKit

@MainActor
final class EnemyManager {
    private var activeEnemies: [PlaceholderEnemy] = []
    private var pooledEnemies: [PlaceholderEnemy] = []

    var activeEnemyCount: Int {
        activeEnemies.count
    }

    func resetForNewScene() {
        (activeEnemies + pooledEnemies).forEach { enemy in
            enemy.reset()
            enemy.node.removeFromParent()
        }

        activeEnemies.removeAll(keepingCapacity: true)
        pooledEnemies.removeAll(keepingCapacity: true)
    }

    func preparePool(capacity: Int) {
        guard pooledEnemies.count < capacity else {
            return
        }

        let missingCount = capacity - pooledEnemies.count

        for _ in 0..<missingCount {
            pooledEnemies.append(PlaceholderEnemy())
        }
    }

    func spawnPlaceholderEnemy(in scene: SKScene, path: GamePath) {
        let enemy = pooledEnemies.popLast() ?? PlaceholderEnemy()

        if enemy.node.parent == nil {
            scene.addChild(enemy.node)
        }

        activeEnemies.append(enemy)

        enemy.startMoving(along: path) { [weak self, weak enemy] in
            guard let self, let enemy else {
                return
            }

            self.recycle(enemy)
        }
    }

    func nearestEnemy(to point: CGPoint, within range: CGFloat) -> PlaceholderEnemy? {
        activeEnemies
            .filter(\.isAlive)
            .filter { enemy in
                enemy.node.position.distance(to: point) <= range
            }
            .min { first, second in
                first.node.position.distance(to: point) < second.node.position.distance(to: point)
            }
    }

    func applyDamage(_ damage: Int, to enemy: PlaceholderEnemy) {
        guard activeEnemies.contains(where: { $0 === enemy }) else {
            return
        }

        if enemy.takeDamage(damage) {
            recycle(enemy)
        }
    }

    private func recycle(_ enemy: PlaceholderEnemy) {
        enemy.reset()
        enemy.node.removeFromParent()

        activeEnemies.removeAll { $0 === enemy }
        pooledEnemies.append(enemy)
    }
}

private extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        let dx = x - point.x
        let dy = y - point.y
        return sqrt(dx * dx + dy * dy)
    }
}
