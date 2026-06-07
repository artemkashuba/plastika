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
    private(set) var spawnedCount: Int = 0

    var totalEnemyCount: Int { prototypeWave.enemyCount }

    func resetForNewScene() {
        isSpawningComplete = false
        spawnedCount = 0
    }

    func startPrototypeWave(in scene: SKScene, path: GamePath, enemyManager: EnemyManager) {
        isSpawningComplete = false
        spawnedCount = 0
        scene.removeAction(forKey: waveActionKey)
        enemyManager.preparePool(capacity: prototypeWave.enemyCount)
        spawnedCount += 1
        enemyManager.spawnPlaceholderEnemy(in: scene, path: path)

        let spawnEnemy = SKAction.run { [weak scene, weak enemyManager, weak self] in
            guard let scene, let enemyManager else {
                return
            }

            self?.spawnedCount += 1
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
