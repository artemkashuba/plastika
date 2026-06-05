import SpriteKit

@MainActor
final class EnemyManager {
    private var placeholderEnemy: PlaceholderEnemy?

    func resetForNewScene() {
        placeholderEnemy?.reset()
        placeholderEnemy?.node.removeFromParent()
        placeholderEnemy = nil
    }

    func showSinglePlaceholderEnemy(in scene: SKScene, path: GamePath) {
        let enemy = placeholderEnemy ?? PlaceholderEnemy()

        if enemy.node.parent == nil {
            scene.addChild(enemy.node)
        }

        placeholderEnemy = enemy
        enemy.startMoving(along: path)
    }
}
