import SpriteKit

struct WaveDefinition {
    let enemyCount: Int
    let spawnInterval: TimeInterval
}

@MainActor
final class WaveManager {
    private let waveActionKey = "waveManager.activeWave"

    private let prototypeWave = WaveDefinition(
        enemyCount: 6,
        spawnInterval: 0.85
    )

    func resetForNewScene() {
    }

    func startPrototypeWave(in scene: SKScene, path: GamePath, enemyManager: EnemyManager) {
        scene.removeAction(forKey: waveActionKey)
        enemyManager.preparePool(capacity: prototypeWave.enemyCount)
        enemyManager.spawnPlaceholderEnemy(in: scene, path: path)

        let spawnEnemy = SKAction.run { [weak scene, weak enemyManager] in
            guard let scene, let enemyManager else {
                return
            }

            enemyManager.spawnPlaceholderEnemy(in: scene, path: path)
        }

        let spawnSequence = SKAction.sequence([
            SKAction.wait(forDuration: prototypeWave.spawnInterval),
            spawnEnemy
        ])

        scene.run(
            SKAction.repeat(spawnSequence, count: max(0, prototypeWave.enemyCount - 1)),
            withKey: waveActionKey
        )
    }
}
