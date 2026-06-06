import SpriteKit

@MainActor
final class EnemyManager {
    var onEnemyReachedEnd: (@MainActor () -> Void)?

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
        onEnemyReachedEnd = nil
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
            self.onEnemyReachedEnd?()
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

    func isValidTarget(_ enemy: PlaceholderEnemy, lifeID: Int, from point: CGPoint, within range: CGFloat) -> Bool {
        isActiveLife(enemy, lifeID: lifeID)
            && enemy.node.position.distance(to: point) <= range
    }

    /// Checks that the enemy is still alive with the given lifeID, without any range constraint.
    /// Use for in-flight homing projectiles that must follow their target regardless of tower range.
    func isTrackedAndAlive(_ enemy: PlaceholderEnemy, lifeID: Int) -> Bool {
        isActiveLife(enemy, lifeID: lifeID)
    }

    @discardableResult
    func applyDamage(_ damage: Int, to enemy: PlaceholderEnemy) -> Bool {
        guard isActiveLife(enemy, lifeID: enemy.lifeID) else {
            return false
        }

        if enemy.takeDamage(damage) {
            recycle(enemy)
            return true
        }

        return false
    }

    @discardableResult
    func applyDamage(_ damage: Int, to enemy: PlaceholderEnemy, matchingLifeID lifeID: Int) -> Bool {
        guard isActiveLife(enemy, lifeID: lifeID) else {
            return false
        }

        if enemy.takeDamage(damage) {
            recycle(enemy)
            return true
        }

        return false
    }

    private func isActiveLife(_ enemy: PlaceholderEnemy, lifeID: Int) -> Bool {
        activeEnemies.contains { $0 === enemy }
            && enemy.lifeID == lifeID
            && enemy.isAlive
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
