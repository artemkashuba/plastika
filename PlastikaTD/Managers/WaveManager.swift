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

    private(set) var isSpawningComplete = false

    func resetForNewScene() {
        isSpawningComplete = false
    }

    func startPrototypeWave(in scene: SKScene, path: GamePath, enemyManager: EnemyManager) {
        isSpawningComplete = false
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

        let markComplete = SKAction.run { [weak self] in
            self?.isSpawningComplete = true
        }

        scene.run(
            SKAction.sequence([
                SKAction.repeat(spawnSequence, count: max(0, prototypeWave.enemyCount - 1)),
                markComplete
            ]),
            withKey: waveActionKey
        )
    }
}
