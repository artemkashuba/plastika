import SpriteKit

final class GameScene: SKScene {
    static let sceneName = "GameScene"

    private let configuration: GameConfiguration
    private let systems: GameSystems
    private var didBuildScene = false
    private var debugPathNode: SKShapeNode?
    /// Scene-coordinate Y of the bottom edge of the notch / Dynamic Island / status bar.
    /// Computed once from view.safeAreaInsets.top and reused on restart.
    private var safeAreaTopInScene: CGFloat = 0

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
        // Convert the bottom of the notch/island/status bar from UIKit coords (top-left origin,
        // y increases downward) to scene coords (bottom-left origin, y increases upward).
        safeAreaTopInScene = convertPoint(fromView: CGPoint(x: 0, y: view.safeAreaInsets.top)).y
        resetPlaceholderSystems()
        buildPlaceholderScene()
        buildGameplaySlice()
        setupCallbacks()
        systems.uiManager.configureOverlay(in: self, safeAreaTop: safeAreaTopInScene)
        systems.gameStateManager.markSceneLoaded(named: Self.sceneName)
    }

    private func resetPlaceholderSystems() {
        debugPathNode?.removeFromParent()
        debugPathNode = nil

        systems.pathManager.resetForNewScene()
        systems.waveManager.resetForNewScene()
        systems.enemyManager.resetForNewScene()
        systems.buildSpotManager.resetForNewScene()
        systems.towerManager.resetForNewScene()
        systems.projectileManager.resetForNewScene()
        systems.economyManager.resetForNewScene()
        systems.baseHealthManager.resetForNewScene()
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
        let pathNode = systems.pathManager.makeDebugPathNode()
        addChild(pathNode)
        debugPathNode = pathNode

        addChild(systems.buildSpotManager.makeBuildSpotLayer())

        systems.waveManager.startPrototypeWave(
            in: self,
            path: systems.pathManager.activePath,
            enemyManager: systems.enemyManager
        )
    }

    private func setupCallbacks() {
        systems.enemyManager.onEnemyReachedEnd = { [weak self] in
            self?.handleEnemyReachedEnd()
        }
    }

    private func handleEnemyReachedEnd() {
        guard systems.gameStateManager.state.phase == .sceneLoaded else {
            return
        }

        let isDestroyed = systems.baseHealthManager.takeDamage()

        // Force a HUD update immediately so the heart loss animation triggers now.
        // Without this, a health:0 loss never gets an update() call because
        // markGameOver() stops the update loop before the next frame.
        systems.uiManager.update(
            coins: systems.economyManager.coins,
            health: systems.baseHealthManager.health
        )

        if isDestroyed {
            triggerGameOver()
        }
    }

    private func triggerGameOver() {
        // Stop gameplay immediately so no further input or combat runs.
        systems.gameStateManager.markGameOver()
        // Delay the overlay so the last heart animation (0.31s) plays before it appears.
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.36),
            SKAction.run { [weak self] in
                guard let self else { return }
                self.systems.uiManager.showGameOverOverlay(in: self)
            }
        ]))
    }

    private func triggerVictory() {
        systems.gameStateManager.markVictory()
        systems.uiManager.showVictoryOverlay(in: self)
    }

    private func restartGame() {
        resetPlaceholderSystems()
        buildGameplaySlice()
        setupCallbacks()
        systems.uiManager.configureOverlay(in: self, safeAreaTop: safeAreaTopInScene)
        systems.gameStateManager.markSceneLoaded(named: Self.sceneName)
    }

    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)

        guard systems.gameStateManager.state.phase == .sceneLoaded else {
            return
        }

        systems.towerManager.updateCombat(
            currentTime: currentTime,
            enemyManager: systems.enemyManager,
            projectileManager: systems.projectileManager,
            economyManager: systems.economyManager,
            in: self
        )
        systems.uiManager.update(
            coins: systems.economyManager.coins,
            health: systems.baseHealthManager.health
        )

        if systems.waveManager.isSpawningComplete && systems.enemyManager.activeEnemyCount == 0 {
            triggerVictory()
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        guard let touch = touches.first else {
            return
        }

        let location = touch.location(in: self)
        let phase = systems.gameStateManager.state.phase

        if phase == .gameOver || phase == .victory {
            if nodes(at: location).contains(where: { $0.name == "RestartButton" }) {
                restartGame()
            }
            return
        }

        if nodes(at: location).contains(where: { $0.name == "SellBadge" }) {
            if let sold = systems.towerManager.sellSelectedTower(in: self) {
                systems.economyManager.credit(sold.refund)
                systems.buildSpotManager.markUnoccupied(buildSpotID: sold.buildSpotID)
                systems.uiManager.update(
                    coins: systems.economyManager.coins,
                    health: systems.baseHealthManager.health
                )
            }
            return
        }

        if let menuSelection = systems.buildSpotManager.towerBuildMenuSelection(
            containing: location,
            coins: systems.economyManager.coins
        ) {
            let didPlaceTower = systems.towerManager.placePlaceholderTower(
                ofType: menuSelection.towerType,
                on: menuSelection.buildSpot,
                in: self
            )

            if didPlaceTower {
                systems.economyManager.spend(menuSelection.towerType.cost)
                systems.buildSpotManager.markOccupied(menuSelection.buildSpot)
                systems.buildSpotManager.hideBuildMenu()
            }

            return
        }

        if systems.towerManager.selectTower(containing: location, in: self) {
            systems.buildSpotManager.hideBuildMenu()
            return
        }

        if let buildSpot = systems.buildSpotManager.emptyBuildSpot(containing: location) {
            systems.towerManager.clearSelection()
            systems.buildSpotManager.showBuildMenu(for: buildSpot, coins: systems.economyManager.coins, in: self)
            return
        }

        systems.towerManager.clearSelection()
        systems.buildSpotManager.hideBuildMenu()
    }
}
