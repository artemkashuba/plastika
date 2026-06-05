import Foundation

@MainActor
final class GameStateManager: ObservableObject {
    @Published private(set) var state = GameState()

    func markSceneLoaded(named sceneName: String) {
        state.activeSceneName = sceneName
        state.phase = .sceneLoaded
    }

    func pause() {
        state.phase = .paused
    }

    func resume() {
        state.phase = .sceneLoaded
    }
}
