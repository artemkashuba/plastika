import SpriteKit

@MainActor
final class UIManager {
    private var overlayNode: SKNode?
    private var enemyCountLabel: SKLabelNode?

    func resetForNewScene() {
        overlayNode?.removeFromParent()
        overlayNode = nil
        enemyCountLabel = nil
    }

    func configureOverlay(in scene: SKScene) {
        resetForNewScene()

        let overlay = SKNode()
        overlay.name = "DebugHUD"
        overlay.zPosition = 40
        overlay.position = CGPoint(x: 62, y: scene.size.height - 164)

        let background = SKShapeNode(rectOf: CGSize(width: 112, height: 46), cornerRadius: 8)
        background.fillColor = SKColor(white: 0.0, alpha: 0.26)
        background.strokeColor = SKColor(white: 1.0, alpha: 0.18)
        background.lineWidth = 1
        background.position = CGPoint(x: 38, y: -8)
        overlay.addChild(background)

        let waveLabel = makeDebugLabel(text: "Wave: 1", y: 2)
        overlay.addChild(waveLabel)

        let enemiesLabel = makeDebugLabel(text: "Enemies: 0", y: -18)
        overlay.addChild(enemiesLabel)
        enemyCountLabel = enemiesLabel

        scene.addChild(overlay)
        overlayNode = overlay
    }

    func update(activeEnemyCount: Int) {
        enemyCountLabel?.text = "Enemies: \(activeEnemyCount)"
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
