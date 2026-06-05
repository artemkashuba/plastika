import SpriteKit

@MainActor
final class TowerManager {
    private var towersByBuildSpotID: [Int: PlaceholderTower] = [:]

    func resetForNewScene() {
        towersByBuildSpotID.values.forEach { tower in
            tower.reset()
        }
        towersByBuildSpotID.removeAll(keepingCapacity: true)
    }

    func placePlaceholderTower(on buildSpot: BuildSpot, in scene: SKScene) -> Bool {
        guard towersByBuildSpotID[buildSpot.id] == nil else {
            return false
        }

        let tower = PlaceholderTower()
        tower.node.position = buildSpot.position
        scene.addChild(tower.node)
        towersByBuildSpotID[buildSpot.id] = tower
        return true
    }
}
