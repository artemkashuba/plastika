import SpriteKit

@MainActor
final class TowerManager {
    private let placeholderAttackRange: CGFloat = 175
    private let placeholderAttackCooldown: TimeInterval = 0.45

    private var towersByBuildSpotID: [Int: PlaceholderTower] = [:]
    private var nextAttackTimesByBuildSpotID: [Int: TimeInterval] = [:]
    private var selectedBuildSpotID: Int?
    private var rangeIndicator: SKShapeNode?

    func resetForNewScene() {
        clearSelection(animated: false)
        rangeIndicator?.removeFromParent()
        rangeIndicator = nil

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

    func selectTower(containing point: CGPoint, in scene: SKScene) -> Bool {
        guard let selection = tower(containing: point) else {
            return false
        }

        selectTower(withBuildSpotID: selection.buildSpotID, tower: selection.tower, in: scene)
        return true
    }

    func clearSelection(animated: Bool = true) {
        if let selectedBuildSpotID, let selectedTower = towersByBuildSpotID[selectedBuildSpotID] {
            selectedTower.setSelected(false, animated: animated)
        }

        selectedBuildSpotID = nil
        rangeIndicator?.removeFromParent()
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

    private func selectTower(withBuildSpotID buildSpotID: Int, tower: PlaceholderTower, in scene: SKScene) {
        if selectedBuildSpotID == buildSpotID {
            moveRangeIndicator(to: tower.node.position, in: scene)
            return
        }

        if let selectedBuildSpotID, let selectedTower = towersByBuildSpotID[selectedBuildSpotID] {
            selectedTower.setSelected(false, animated: true)
        }

        selectedBuildSpotID = buildSpotID
        tower.setSelected(true, animated: true)
        moveRangeIndicator(to: tower.node.position, in: scene)
    }

    private func moveRangeIndicator(to position: CGPoint, in scene: SKScene) {
        let indicator = makeRangeIndicator()
        indicator.position = position

        if indicator.parent == nil {
            scene.addChild(indicator)
        }
    }

    private func makeRangeIndicator() -> SKShapeNode {
        if let rangeIndicator {
            return rangeIndicator
        }

        let indicator = SKShapeNode(circleOfRadius: placeholderAttackRange)
        indicator.name = "TowerRangeIndicator"
        indicator.fillColor = .clear
        indicator.strokeColor = SKColor(white: 1.0, alpha: 0.34)
        indicator.lineWidth = 2
        indicator.zPosition = 13
        rangeIndicator = indicator
        return indicator
    }

    private func tower(containing point: CGPoint) -> (buildSpotID: Int, tower: PlaceholderTower)? {
        towersByBuildSpotID
            .filter { _, tower in
                tower.node.position.distance(to: point) <= 32
            }
            .min { first, second in
                first.value.node.position.distance(to: point) < second.value.node.position.distance(to: point)
            }
            .map { buildSpotID, tower in
                (buildSpotID, tower)
            }
    }
}

private extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        let dx = x - point.x
        let dy = y - point.y
        return sqrt(dx * dx + dy * dy)
    }
}
