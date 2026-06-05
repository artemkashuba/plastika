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
        systems.uiManager.configureOverlay(in: self)
        systems.gameStateManager.markSceneLoaded(named: Self.sceneName)
    }

    private func resetPlaceholderSystems() {
        systems.waveManager.resetForNewScene()
        systems.enemyManager.resetForNewScene()
        systems.towerManager.resetForNewScene()
        systems.projectileManager.resetForNewScene()
        systems.economyManager.resetForNewScene()
    }

    private func buildPlaceholderScene() {
        let table = SKShapeNode(rectOf: CGSize(width: size.width * 0.82, height: size.height * 0.72), cornerRadius: 24)
        table.fillColor = SKColor(red: 0.23, green: 0.48, blue: 0.38, alpha: 1.0)
        table.strokeColor = SKColor(red: 0.86, green: 0.95, blue: 0.78, alpha: 1.0)
        table.lineWidth = 4
        table.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(table)

        let title = SKLabelNode(fontNamed: "AvenirNext-Bold")
        title.text = "Plastika TD"
        title.fontSize = 34
        title.fontColor = .white
        title.position = CGPoint(x: size.width / 2, y: size.height / 2 + 24)
        addChild(title)

        let subtitle = SKLabelNode(fontNamed: "AvenirNext-Medium")
        subtitle.text = "SpriteKit shell"
        subtitle.fontSize = 18
        subtitle.fontColor = SKColor(white: 1.0, alpha: 0.75)
        subtitle.position = CGPoint(x: size.width / 2, y: size.height / 2 - 18)
        addChild(subtitle)
    }
}
