import SpriteKit

final class GameScene: SKScene {
    static let sceneName = "GameScene"

    private let configuration: GameConfiguration
    private let systems: GameSystems
    private var didBuildScene = false

    init(configuration: GameConfiguration, systems: GameSystems) {
        self.configuration = configuration
        self.systems = systems
        super.init(size: configuration.sceneSize)
        backgroundColor = SKColor(red: 0.07, green: 0.15, blue: 0.16, alpha: 1.0)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("GameScene does not support storyboard initialization.")
    }

    override func didMove(to view: SKView) {
        super.didMove(to: view)

        guard didBuildScene == false else {
            return
        }

        didBuildScene = true
        view.preferredFramesPerSecond = configuration.preferredFramesPerSecond
        resetPlaceholderSystems()
        buildPlaceholderScene()
        buildGameplaySlice()
        systems.uiManager.configureOverlay(in: self)
        systems.gameStateManager.markSceneLoaded(named: Self.sceneName)
    }

    private func resetPlaceholderSystems() {
        systems.pathManager.resetForNewScene()
        systems.waveManager.resetForNewScene()
        systems.enemyManager.resetForNewScene()
        systems.buildSpotManager.resetForNewScene()
        systems.towerManager.resetForNewScene()
        systems.projectileManager.resetForNewScene()
        systems.economyManager.resetForNewScene()
        systems.uiManager.resetForNewScene()
    }

    private func buildPlaceholderScene() {
        let table = SKShapeNode(rectOf: CGSize(width: size.width * 0.82, height: size.height * 0.72), cornerRadius: 24)
        table.fillColor = SKColor(red: 0.23, green: 0.48, blue: 0.38, alpha: 1.0)
        table.strokeColor = SKColor(red: 0.86, green: 0.95, blue: 0.78, alpha: 1.0)
        table.lineWidth = 4
        table.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(table)
    }

    private func buildGameplaySlice() {
        addChild(systems.pathManager.makeDebugPathNode())
        addChild(systems.buildSpotManager.makeBuildSpotLayer())
        systems.waveManager.startPrototypeWave(
            in: self,
            path: systems.pathManager.activePath,
            enemyManager: systems.enemyManager
        )
    }

    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        systems.uiManager.update(activeEnemyCount: systems.enemyManager.activeEnemyCount)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        guard let touch = touches.first else {
            return
        }

        let location = touch.location(in: self)

        guard let buildSpot = systems.buildSpotManager.emptyBuildSpot(containing: location) else {
            return
        }

        let didPlaceTower = systems.towerManager.placePlaceholderTower(on: buildSpot, in: self)

        if didPlaceTower {
            systems.buildSpotManager.markOccupied(buildSpot)
        }
    }
}
