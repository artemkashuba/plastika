import Foundation
import SpriteKit

@MainActor
final class SceneManager: ObservableObject {
    @Published private(set) var activeSceneName: String?

    func makeInitialScene(gameStateManager: GameStateManager) -> GameScene {
        let systems = GameSystems(gameStateManager: gameStateManager)
        let scene = GameScene(configuration: .standard, systems: systems)
        scene.scaleMode = .aspectFill
        activeSceneName = GameScene.sceneName
        return scene
    }
}
