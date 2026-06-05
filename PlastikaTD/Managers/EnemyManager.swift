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

    private func recycle(_ enemy: PlaceholderEnemy) {
        enemy.reset()
        enemy.node.removeFromParent()

        activeEnemies.removeAll { $0 === enemy }
        pooledEnemies.append(enemy)
    }
}
