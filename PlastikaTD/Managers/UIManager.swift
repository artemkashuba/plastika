import SpriteKit

@MainActor
final class UIManager {
    private var overlayNode: SKNode?
    private var enemyCountLabel: SKLabelNode?
    private var coinLabel: SKLabelNode?

    func resetForNewScene() {
        overlayNode?.removeFromParent()
        overlayNode = nil
        enemyCountLabel = nil
        coinLabel = nil
    }

    func configureOverlay(in scene: SKScene) {
        resetForNewScene()

        let overlay = SKNode()
        overlay.name = "DebugHUD"
        overlay.zPosition = 40
        overlay.position = CGPoint(x: 62, y: scene.size.height - 164)

        let background = SKShapeNode(rectOf: CGSize(width: 112, height: 62), cornerRadius: 8)
        background.fillColor = SKColor(white: 0.0, alpha: 0.26)
        background.strokeColor = SKColor(white: 1.0, alpha: 0.18)
        background.lineWidth = 1
        background.position = CGPoint(x: 38, y: -16)
        overlay.addChild(background)

        let waveLabel = makeDebugLabel(text: "Wave: 1", y: 10)
        overlay.addChild(waveLabel)

        let enemiesLabel = makeDebugLabel(text: "Enemies: 0", y: -6)
        overlay.addChild(enemiesLabel)
        enemyCountLabel = enemiesLabel

        let coinsLabel = makeDebugLabel(text: "Coins: \(EconomyManager.startingCoins)", y: -22)
        overlay.addChild(coinsLabel)
        coinLabel = coinsLabel

        scene.addChild(overlay)
        overlayNode = overlay
    }

    func update(activeEnemyCount: Int, coins: Int) {
        enemyCountLabel?.text = "Enemies: \(activeEnemyCount)"
        coinLabel?.text = "Coins: \(coins)"
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
