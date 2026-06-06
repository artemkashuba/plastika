import SpriteKit

@MainActor
final class TowerManager {
    private let placeholderAttackRange: CGFloat = 175
    private let placeholderAttackCooldown: TimeInterval = 0.45

    private var towersByBuildSpotID: [Int: PlaceholderTower] = [:]
    private var nextAttackTimesByBuildSpotID: [Int: TimeInterval] = [:]

    func resetForNewScene() {
        towersByBuildSpotID.values.forEach { tower in
            tower.reset()
        }
        towersByBuildSpotID.removeAll(keepingCapacity: true)
        nextAttackTimesByBuildSpotID.removeAll(keepingCapacity: true)
    }

    func placePlaceholderTower(on buildSpot: BuildSpot, in scene: SKScene) -> Bool {
        guard towersByBuildSpotID[buildSpot.id] == nil else {
            return false
        }

        let tower = PlaceholderTower()
        tower.node.position = buildSpot.position
        scene.addChild(tower.node)
        towersByBuildSpotID[buildSpot.id] = tower
        nextAttackTimesByBuildSpotID[buildSpot.id] = 0
        return true
    }

    func updateCombat(
        currentTime: TimeInterval,
        enemyManager: EnemyManager,
        projectileManager: ProjectileManager,
        in scene: SKScene
    ) {
        towersByBuildSpotID.forEach { buildSpotID, tower in
            let nextAttackTime = nextAttackTimesByBuildSpotID[buildSpotID] ?? 0

            guard currentTime >= nextAttackTime else {
                return
            }

            guard let target = enemyManager.nearestEnemy(to: tower.node.position, within: placeholderAttackRange) else {
                return
            }

            nextAttackTimesByBuildSpotID[buildSpotID] = currentTime + placeholderAttackCooldown

            projectileManager.firePlaceholderProjectile(from: tower.node.position, at: target, in: scene) { [weak enemyManager] enemy in
                enemyManager?.applyDamage(1, to: enemy)
            }
        }
    }
}
