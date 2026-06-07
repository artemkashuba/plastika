import Foundation

// MARK: - Pause stats snapshot

/// Captured at the moment the game is paused. Values are frozen — the game is stopped.
struct PauseStats {
    let activeEnemies: Int
    let spawnedEnemies: Int
    let totalEnemies: Int
    let killCount: Int
    let towerCounts: [TowerType: Int]
    let coinsInvested: Int
}

// MARK: - Manager

@MainActor
final class GameStateManager: ObservableObject {
    @Published private(set) var state = GameState()
    /// Non-nil while the game is paused. Cleared on resume or restart.
    @Published private(set) var pauseStats: PauseStats?
    /// Persisted across sessions. Defaults to true on first launch.
    @Published private(set) var isSoundEnabled: Bool

    /// Called by GameScene when the SwiftUI resume action fires.
    var onResume: (() -> Void)?
    /// Called immediately when the sound setting changes so GameScene can mute/unmute the engine.
    var onSoundEnabledChange: ((Bool) -> Void)?

    init() {
        // Default sound ON; only use stored value after first explicit set
        if UserDefaults.standard.object(forKey: "soundEnabled") == nil {
            isSoundEnabled = true
        } else {
            isSoundEnabled = UserDefaults.standard.bool(forKey: "soundEnabled")
        }
    }

    // MARK: - Phase transitions

    func markSceneLoaded(named sceneName: String) {
        state.activeSceneName = sceneName
        state.phase = .sceneLoaded
        pauseStats = nil
    }

    func pause(stats: PauseStats) {
        state.phase = .paused
        pauseStats = stats
    }

    func resume() {
        state.phase = .sceneLoaded
        pauseStats = nil
        onResume?()
    }

    func pause() {
        state.phase = .paused
    }

    func markGameOver() {
        state.phase = .gameOver
    }

    func markVictory() {
        state.phase = .victory
    }

    // MARK: - Sound

    func setSoundEnabled(_ value: Bool) {
        isSoundEnabled = value
        UserDefaults.standard.set(value, forKey: "soundEnabled")
        onSoundEnabledChange?(value)
    }
}
