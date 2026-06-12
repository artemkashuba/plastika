import SpriteKit

@MainActor
final class EnemyManager {
    var onEnemyReachedEnd: (@MainActor () -> Void)?
    /// Wired once at scene setup (like `onEnemyReachedEnd`) so the single damage-kill
    /// chokepoint can fire the (throttled) "enemy killed" haptic — covering projectile,
    /// beam, and splash kills alike without threading a reference through every call site.
    weak var hapticsManager: HapticsManager?

    private var activeEnemies: [PlaceholderEnemy] = []
    private var pooledEnemies: [PlaceholderEnemy] = []

    var activeEnemyCount: Int {
        activeEnemies.count
    }

    private(set) var killCount: Int = 0

    func resetForNewScene() {
        (activeEnemies + pooledEnemies).forEach { enemy in
            enemy.reset()
            enemy.node.removeFromParent()
        }

        activeEnemies.removeAll(keepingCapacity: true)
        pooledEnemies.removeAll(keepingCapacity: true)
        onEnemyReachedEnd = nil
        killCount = 0
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

    func spawnPlaceholderEnemy(in scene: SKScene, path: GamePath, type: EnemyType) {
        let enemy = pooledEnemies.popLast() ?? PlaceholderEnemy()
        // Reapply every per-type stat and chassis detail before this life starts —
        // pooled instances may have last lived as a completely different `EnemyType`,
        // and `startMoving` (called below) immediately derives `hitPoints`/
        // `fractionalHealth`/travel speed from whatever `configure` just set.
        enemy.configure(type: type)

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
            .filter(\.isTargetable)
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
            killAndRecycle(enemy)
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
            killAndRecycle(enemy)
            return true
        }

        return false
    }

    /// Mirrors `applyDamage(_:to:matchingLifeID:)` for continuous, fractional damage sources
    /// (laser beams). Same lifeID-guarded validity check and kill/recycle handling — the only
    /// difference is the per-tick amount can be a fractional `Double` (typically `dps * deltaTime`),
    /// which `PlaceholderEnemy.takeContinuousDamage` uses to drain the health bar smoothly.
    @discardableResult
    func applyContinuousDamage(_ amount: Double, to enemy: PlaceholderEnemy, matchingLifeID lifeID: Int) -> Bool {
        guard isActiveLife(enemy, lifeID: lifeID) else {
            return false
        }

        if enemy.takeContinuousDamage(amount) {
            killAndRecycle(enemy)
            return true
        }

        return false
    }

    /// Single chokepoint for an enemy dying to damage (not reaching the base): bumps the
    /// kill count, fires the death burst at the enemy's still-current position while its
    /// node is still in the scene, then recycles it. Kept separate from `recycle` itself
    /// because `recycle` is also used for enemies that *breach* the base — those should
    /// not explode.
    private func killAndRecycle(_ enemy: PlaceholderEnemy) {
        killCount += 1
        hapticsManager?.enemyKilled()
        if let scene = enemy.node.scene {
            enemy.spawnDeathEffect(in: scene)
        }
        recycle(enemy)
    }

    /// The enemy nearest to `endPoint` (i.e. furthest along the path, closest to breaching
    /// the base) among those alive and within `range` of `fromPoint`. Used by the Mortar to
    /// bombard the *leading edge* of the advance rather than whatever happens to be nearest
    /// the tower. Returns nil if no enemy is in range.
    func leadEnemy(within range: CGFloat, from fromPoint: CGPoint, towardEnd endPoint: CGPoint) -> PlaceholderEnemy? {
        activeEnemies
            .filter(\.isTargetable)
            .filter { $0.node.position.distance(to: fromPoint) <= range }
            .min { $0.node.position.distance(to: endPoint) < $1.node.position.distance(to: endPoint) }
    }

    /// Applies `damage` to every enemy within `radius` of `center` (a mortar shell's blast).
    /// Returns one `(reward, position)` per enemy *killed*, so the caller can credit coins and
    /// fly a reward from each death spot. Snapshots the victims before applying damage, since
    /// `killAndRecycle` mutates `activeEnemies` mid-loop. Each kill also fires its own death
    /// burst (via `killAndRecycle`), independent of the explosion effect drawn by the caller.
    @discardableResult
    func applyAreaDamage(_ damage: Int, at center: CGPoint, radius: CGFloat) -> [(reward: Int, position: CGPoint)] {
        let victims = activeEnemies.filter { enemy in
            enemy.isTargetable && enemy.node.position.distance(to: center) <= radius
        }

        var kills: [(reward: Int, position: CGPoint)] = []
        for enemy in victims {
            let reward = enemy.killReward
            let position = enemy.node.position
            if enemy.takeDamage(damage) {
                killAndRecycle(enemy)
                kills.append((reward, position))
            }
        }
        return kills
    }

    private func isActiveLife(_ enemy: PlaceholderEnemy, lifeID: Int) -> Bool {
        activeEnemies.contains { $0 === enemy }
            && enemy.lifeID == lifeID
            && enemy.isTargetable
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
