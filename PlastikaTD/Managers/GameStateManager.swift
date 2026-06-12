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
    /// 1-based index of the wave currently in progress (or about to start, during a countdown).
    let waveNumber: Int
    /// Total number of waves in the level's script — pairs with `waveNumber` for "1/2" display.
    let totalWaveCount: Int
}

// MARK: - Manager

@MainActor
final class GameStateManager: ObservableObject {
    @Published private(set) var state = GameState()
    /// Non-nil while the game is paused. Cleared on resume or restart.
    @Published private(set) var pauseStats: PauseStats?
    /// Persisted across sessions. Defaults to true on first launch.
    @Published private(set) var isSoundEnabled: Bool
    /// Persisted across sessions. Defaults to true on first launch. Mirrors `isSoundEnabled`.
    @Published private(set) var isHapticsEnabled: Bool

    /// Called by GameScene when the SwiftUI resume action fires.
    var onResume: (() -> Void)?
    /// Called immediately when the sound setting changes so GameScene can mute/unmute the engine.
    var onSoundEnabledChange: ((Bool) -> Void)?
    /// Called immediately when the haptics setting changes so GameScene can push it onto the
    /// HapticsManager (mirrors `onSoundEnabledChange`).
    var onHapticsEnabledChange: ((Bool) -> Void)?

    init() {
        // Default sound ON; only use stored value after first explicit set
        if UserDefaults.standard.object(forKey: "soundEnabled") == nil {
            isSoundEnabled = true
        } else {
            isSoundEnabled = UserDefaults.standard.bool(forKey: "soundEnabled")
        }

        // Default haptics ON; only use stored value after first explicit set
        if UserDefaults.standard.object(forKey: "hapticsEnabled") == nil {
            isHapticsEnabled = true
        } else {
            isHapticsEnabled = UserDefaults.standard.bool(forKey: "hapticsEnabled")
        }
    }

    /// Fired when the player taps PLAY on the main menu — GameScene wires this to begin
    /// wave progression (mirrors `onResume`'s shape).
    var onStartGame: (() -> Void)?

    // MARK: - Phase transitions

    func markSceneLoaded(named sceneName: String) {
        state.activeSceneName = sceneName
        state.phase = .sceneLoaded
        pauseStats = nil
    }

    /// Scene is built and idling as a backdrop; the SwiftUI main menu is on top.
    func markMainMenu() {
        state.phase = .mainMenu
        pauseStats = nil
    }

    /// Called by the main menu's PLAY button.
    func startGame() {
        onStartGame?()
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

    // MARK: - Haptics

    func setHapticsEnabled(_ value: Bool) {
        isHapticsEnabled = value
        UserDefaults.standard.set(value, forKey: "hapticsEnabled")
        onHapticsEnabledChange?(value)
    }
}
