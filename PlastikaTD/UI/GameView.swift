import SpriteKit
import SwiftUI

struct GameView: View {
    @StateObject private var gameStateManager = GameStateManager()
    @StateObject private var sceneManager = SceneManager()
    @State private var scene: GameScene?

    var body: some View {
        ZStack {
            if let scene {
                SpriteView(scene: scene, options: [.ignoresSiblingOrder])
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }
        }
        .onAppear {
            loadInitialSceneIfNeeded()
        }
    }

    private func loadInitialSceneIfNeeded() {
        guard scene == nil else {
            return
        }

        scene = sceneManager.makeInitialScene(gameStateManager: gameStateManager)
    }
}
