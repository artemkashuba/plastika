import SpriteKit

@MainActor
final class UIManager {
    private var overlayNode: SKNode?
    private var enemyCountLabel: SKLabelNode?
    private var coinLabel: SKLabelNode?
    private var livesLabel: SKLabelNode?
    private var endOverlayNode: SKNode?

    func resetForNewScene() {
        overlayNode?.removeFromParent()
        overlayNode = nil
        endOverlayNode?.removeFromParent()
        endOverlayNode = nil
        enemyCountLabel = nil
        coinLabel = nil
        livesLabel = nil
    }

    func configureOverlay(in scene: SKScene) {
        resetForNewScene()

        let overlay = SKNode()
        overlay.name = "DebugHUD"
        overlay.zPosition = 40
        overlay.position = CGPoint(x: 62, y: scene.size.height - 164)

        let background = SKShapeNode(rectOf: CGSize(width: 112, height: 78), cornerRadius: 8)
        background.fillColor = SKColor(white: 0.0, alpha: 0.26)
        background.strokeColor = SKColor(white: 1.0, alpha: 0.18)
        background.lineWidth = 1
        background.position = CGPoint(x: 38, y: -24)
        overlay.addChild(background)

        let waveLabel = makeDebugLabel(text: "Wave: 1", y: 10)
        overlay.addChild(waveLabel)

        let enemiesLabel = makeDebugLabel(text: "Enemies: 0", y: -6)
        overlay.addChild(enemiesLabel)
        enemyCountLabel = enemiesLabel

        let coinsLabel = makeDebugLabel(text: "Coins: \(EconomyManager.startingCoins)", y: -22)
        overlay.addChild(coinsLabel)
        coinLabel = coinsLabel

        let livesLabel = makeDebugLabel(text: "Lives: \(BaseHealthManager.startingHealth)", y: -38)
        overlay.addChild(livesLabel)
        self.livesLabel = livesLabel

        scene.addChild(overlay)
        overlayNode = overlay
    }

    func update(activeEnemyCount: Int, coins: Int, health: Int) {
        enemyCountLabel?.text = "Enemies: \(activeEnemyCount)"
        coinLabel?.text = "Coins: \(coins)"
        livesLabel?.text = "Lives: \(health)"
    }

    func showGameOverOverlay(in scene: SKScene) {
        showEndOverlay(
            title: "DEFEAT",
            titleColor: SKColor(red: 0.94, green: 0.25, blue: 0.20, alpha: 1.0),
            subtitle: "Your base was overrun.",
            in: scene
        )
    }

    func showVictoryOverlay(in scene: SKScene) {
        showEndOverlay(
            title: "VICTORY",
            titleColor: SKColor(red: 0.98, green: 0.82, blue: 0.18, alpha: 1.0),
            subtitle: "All enemies defeated!",
            in: scene
        )
    }

    func hideEndOverlay() {
        endOverlayNode?.removeFromParent()
        endOverlayNode = nil
    }

    private func showEndOverlay(title: String, titleColor: SKColor, subtitle: String, in scene: SKScene) {
        hideEndOverlay()

        let root = SKNode()
        root.name = "EndOverlay"
        root.zPosition = 50
        root.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)

        let panel = SKShapeNode(rectOf: CGSize(width: 280, height: 210), cornerRadius: 20)
        panel.fillColor = SKColor(white: 0.0, alpha: 0.78)
        panel.strokeColor = SKColor(white: 1.0, alpha: 0.22)
        panel.lineWidth = 2
        root.addChild(panel)

        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        titleLabel.text = title
        titleLabel.fontSize = 38
        titleLabel.fontColor = titleColor
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: 0, y: 52)
        root.addChild(titleLabel)

        let subtitleLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
        subtitleLabel.text = subtitle
        subtitleLabel.fontSize = 13
        subtitleLabel.fontColor = SKColor(white: 1.0, alpha: 0.72)
        subtitleLabel.verticalAlignmentMode = .center
        subtitleLabel.position = CGPoint(x: 0, y: 18)
        root.addChild(subtitleLabel)

        let restartButton = SKShapeNode(rectOf: CGSize(width: 140, height: 44), cornerRadius: 10)
        restartButton.name = "RestartButton"
        restartButton.fillColor = SKColor(white: 1.0, alpha: 0.18)
        restartButton.strokeColor = SKColor(white: 1.0, alpha: 0.52)
        restartButton.lineWidth = 2
        restartButton.position = CGPoint(x: 0, y: -52)
        root.addChild(restartButton)

        let restartLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        restartLabel.name = "RestartButton"
        restartLabel.text = "Restart"
        restartLabel.fontSize = 16
        restartLabel.fontColor = .white
        restartLabel.verticalAlignmentMode = .center
        restartButton.addChild(restartLabel)

        scene.addChild(root)
        endOverlayNode = root
    }

    private func makeDebugLabel(text: String, y: CGFloat) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        label.text = text
        label.fontSize = 12
        label.fontColor = SKColor(white: 1.0, alpha: 0.86)
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: -8, y: y)
        return label
    }
}
