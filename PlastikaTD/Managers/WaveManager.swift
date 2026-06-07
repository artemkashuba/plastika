import SpriteKit

struct WaveDefinition {
    let enemyCount: Int
    let spawnInterval: TimeInterval
}

@MainActor
final class WaveManager {
    private let waveActionKey = "waveManager.activeWave"
    private let countdownActionKey = "waveManager.interWaveCountdown"

    /// Number of waves in the scripted slice. `waveDefinition(at:)` derives each one's
    /// difficulty from the curve below, so growing this number alone is enough to add
    /// more (automatically harder) waves — no per-wave hand-tuning required.
    private let scriptedWaveCount = 2

    /// Wave-difficulty curve: every wave after the first adds `enemyCountStepPerWave` more
    /// enemies than the last and shaves `spawnIntervalStepPerWave` seconds off the spawn
    /// interval (clamped at `minimumSpawnInterval` so spawning never becomes a blur). With
    /// these values, wave 1 = 6 enemies @ 0.85s, wave 2 = 9 @ 0.70s, wave 3 = 12 @ 0.55s, ...
    private let baseEnemyCount = 6
    private let enemyCountStepPerWave = 3
    private let baseSpawnInterval: TimeInterval = 0.85
    private let spawnIntervalStepPerWave: TimeInterval = 0.15
    private let minimumSpawnInterval: TimeInterval = 0.4

    /// Seconds shown to the player between a cleared wave and the next one starting.
    private let interWaveCountdownSeconds = 3

    private(set) var currentWaveIndex = 0
    private(set) var isSpawningComplete = false
    private(set) var spawnedCount: Int = 0
    /// True from the moment the last enemy of a wave dies until the next wave actually
    /// starts spawning — guards `updateProgression` against re-triggering the countdown.
    private(set) var isAdvancingToNextWave = false
    /// Seconds remaining in the inter-wave countdown, or nil when no countdown is active.
    private(set) var countdownSecondsRemaining: Int?

    /// Fires whenever the HUD wave badge should update — on every wave start and on each
    /// countdown tick. `countdown` is non-nil only while counting down to the *next* wave
    /// (in which case `waveNumber` is that upcoming wave's number, e.g. "WAVE 2 IN 3").
    var onWaveProgressChanged: ((_ waveNumber: Int, _ countdown: Int?) -> Void)?

    var currentWaveNumber: Int { currentWaveIndex + 1 }
    var totalWaveCount: Int { scriptedWaveCount }
    var totalEnemyCount: Int { waveDefinition(at: currentWaveIndex).enemyCount }
    private var hasNextWave: Bool { currentWaveIndex + 1 < scriptedWaveCount }

    /// Derives a wave's difficulty from its index along the linear curve described above
    /// (index 0 = wave 1, index 1 = wave 2, ...). Centralizing the math here means adding
    /// waves is just raising `scriptedWaveCount` — every wave it produces is automatically
    /// harder than the one before it.
    private func waveDefinition(at index: Int) -> WaveDefinition {
        let enemyCount = baseEnemyCount + enemyCountStepPerWave * index
        let spawnInterval = max(
            minimumSpawnInterval,
            baseSpawnInterval - spawnIntervalStepPerWave * Double(index)
        )
        return WaveDefinition(enemyCount: enemyCount, spawnInterval: spawnInterval)
    }

    func resetForNewScene() {
        currentWaveIndex = 0
        isSpawningComplete = false
        spawnedCount = 0
        isAdvancingToNextWave = false
        countdownSecondsRemaining = nil
    }

    /// Kicks off the wave script from the beginning. Call once when gameplay starts
    /// (initial load or restart).
    func beginWaveProgression(in scene: SKScene, path: GamePath, enemyManager: EnemyManager) {
        isAdvancingToNextWave = false
        startWave(at: 0, in: scene, path: path, enemyManager: enemyManager)
    }

    /// Call once per frame while gameplay is active. Drives wave-to-wave progression:
    /// once the active wave finishes spawning and its last enemy dies, this either starts
    /// the inter-wave countdown (more waves remain) or returns `true` exactly once to tell
    /// the caller every wave has been cleared — the cue to trigger victory.
    @discardableResult
    func updateProgression(
        activeEnemyCount: Int,
        in scene: SKScene,
        path: GamePath,
        enemyManager: EnemyManager
    ) -> Bool {
        guard isSpawningComplete, activeEnemyCount == 0, isAdvancingToNextWave == false else {
            return false
        }

        guard hasNextWave else {
            return true
        }

        isAdvancingToNextWave = true
        beginInterWaveCountdown(in: scene, path: path, enemyManager: enemyManager)
        return false
    }

    // MARK: - Wave spawning

    private func startWave(at index: Int, in scene: SKScene, path: GamePath, enemyManager: EnemyManager) {
        guard index >= 0, index < scriptedWaveCount else {
            return
        }

        let definition = waveDefinition(at: index)

        currentWaveIndex = index
        isSpawningComplete = false
        spawnedCount = 0
        isAdvancingToNextWave = false
        countdownSecondsRemaining = nil

        scene.removeAction(forKey: waveActionKey)
        scene.removeAction(forKey: countdownActionKey)

        onWaveProgressChanged?(currentWaveNumber, nil)

        enemyManager.preparePool(capacity: definition.enemyCount)
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
            SKAction.wait(forDuration: definition.spawnInterval),
            spawnEnemy
        ])

        let markComplete = SKAction.run { [weak self] in
            self?.isSpawningComplete = true
        }

        scene.run(
            SKAction.sequence([
                SKAction.repeat(spawnSequence, count: max(0, definition.enemyCount - 1)),
                markComplete
            ]),
            withKey: waveActionKey
        )
    }

    // MARK: - Inter-wave countdown

    /// Counts down from `interWaveCountdownSeconds` to 0, announcing each tick via
    /// `onWaveProgressChanged` so the HUD can show "WAVE 2 IN 3" → "WAVE 2 IN 1", then
    /// starts the next wave the instant the countdown reaches zero.
    private func beginInterWaveCountdown(in scene: SKScene, path: GamePath, enemyManager: EnemyManager) {
        let nextIndex = currentWaveIndex + 1
        let nextWaveNumber = nextIndex + 1
        let totalSeconds = interWaveCountdownSeconds

        countdownSecondsRemaining = totalSeconds
        onWaveProgressChanged?(nextWaveNumber, totalSeconds)

        var steps: [SKAction] = []

        // One tick per elapsed second: counts totalSeconds-1, totalSeconds-2, ..., 0.
        // The final tick (0) clears the countdown display just before the wave begins.
        for secondsLeft in stride(from: totalSeconds - 1, through: 0, by: -1) {
            let displayValue: Int? = secondsLeft > 0 ? secondsLeft : nil
            steps.append(SKAction.wait(forDuration: 1.0))
            steps.append(SKAction.run { [weak self] in
                self?.countdownSecondsRemaining = displayValue
                self?.onWaveProgressChanged?(nextWaveNumber, displayValue)
            })
        }

        steps.append(SKAction.run { [weak self, weak scene, weak enemyManager] in
            guard let self, let scene, let enemyManager else {
                return
            }

            self.startWave(at: nextIndex, in: scene, path: path, enemyManager: enemyManager)
        })

        scene.run(SKAction.sequence(steps), withKey: countdownActionKey)
    }
}
